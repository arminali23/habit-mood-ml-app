import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Mood',
      theme: ThemeData(useMaterial3: true),
      home: const EntriesPage(),
    );
  }
}

class Entry {
  final int id;
  final String text;
  final String mood;
  final DateTime createdAt;

  Entry({
    required this.id,
    required this.text,
    required this.mood,
    required this.createdAt,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      id: json['id'] as int,
      text: json['text'] as String,
      mood: json['mood'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class Api {
  // Web/iOS simulator: 127.0.0.1 works.
  // Android emulator: use 10.0.2.2
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<List<Entry>> fetchEntries() async {
    final res = await http.get(Uri.parse('$baseUrl/entries'));
    if (res.statusCode != 200) {
      throw Exception('GET /entries failed (${res.statusCode})');
    }
    final List data = jsonDecode(res.body) as List;
    return data.map((e) => Entry.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Entry> createEntry(String text) async {
    final res = await http.post(
      Uri.parse('$baseUrl/entries'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );
    if (res.statusCode != 200) {
      throw Exception('POST /entries failed (${res.statusCode})');
    }
    return Entry.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<Map<String, dynamic>> fetchStats({int days = 7}) async {
    final res = await http.get(Uri.parse('$baseUrl/stats?days=$days'));
    if (res.statusCode != 200) {
      throw Exception('GET /stats failed (${res.statusCode})');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

class EntriesPage extends StatefulWidget {
  const EntriesPage({super.key});

  @override
  State<EntriesPage> createState() => _EntriesPageState();
}

class _EntriesPageState extends State<EntriesPage> {
  final _controller = TextEditingController();
  bool _loading = false;
  List<Entry> _entries = [];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _loading = true);
    try {
      final items = await Api.fetchEntries();
      setState(() => _entries = items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Load error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _loading = true);
    try {
      await Api.createEntry(text);
      _controller.clear();
      final items = await Api.fetchEntries();
      setState(() => _entries = items);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Mood'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const StatsPage()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Write a short sentence',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading && _entries.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadEntries,
                      child: ListView.separated(
                        itemCount: _entries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final e = _entries[i];
                          return ListTile(
                            title: Text(e.text),
                            subtitle: Text(
                              '${e.mood} • ${e.createdAt.toLocal()}',
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _loading = false;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final s = await Api.fetchStats(days: 7);
      setState(() => _stats = s);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Stats error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats;

    return Scaffold(
      appBar: AppBar(title: const Text('Stats (Last 7 days)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading && s == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadStats,
                child: ListView(
                  children: [
                    _StatRow(label: 'Total', value: '${s?['total'] ?? 0}'),
                    _StatRow(
                      label: 'Positive',
                      value: '${s?['positive'] ?? 0}',
                    ),
                    _StatRow(label: 'Neutral', value: '${s?['neutral'] ?? 0}'),
                    _StatRow(
                      label: 'Negative',
                      value: '${s?['negative'] ?? 0}',
                    ),
                    const SizedBox(height: 12),
                    const Text('Pull to refresh.'),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Text(label), trailing: Text(value)),
    );
  }
}
