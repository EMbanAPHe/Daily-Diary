// lib/main.dart
//
// Minimal SAF-enabled app shell for Daily Diary. Picks a folder via Android's
// system picker and reads/writes today's entry at YYYY/MM/DD.md.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'storage/diary_storage.dart';
import 'storage/saf_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DiaryApp());
}

class DiaryApp extends StatelessWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Diary (SAF)',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const StorageGate(child: DiaryHome()),
    );
  }
}

class StorageGate extends StatefulWidget {
  final Widget child;
  const StorageGate({super.key, required this.child});

  @override
  State<StorageGate> createState() => _StorageGateState();
}

class _StorageGateState extends State<StorageGate> {
  late final DiaryStorage storage;
  bool _ready = false;
  bool _hasRoot = false;

  @override
  void initState() {
    super.initState();
    storage = SafStorage();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final has = await storage.hasRoot();
    setState(() {
      _hasRoot = has;
      _ready = true;
    });
  }

  Future<void> _pickRoot() async {
    await storage.pickRoot();
    final ok = await storage.hasRoot();
    setState(() => _hasRoot = ok);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_hasRoot) {
      return Scaffold(
        appBar: AppBar(title: const Text('Choose Diary Folder')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To run on GrapheneOS / modern Android, select a diary folder '
                'using the system picker (SAF). The app will store entries at '
                'YYYY/MM/DD.md under this folder.',
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _pickRoot,
                icon: const Icon(Icons.folder_open),
                label: const Text('Pick folder'),
              ),
            ],
          ),
        ),
      );
    }
    return InheritedStorage(storage: storage, child: widget.child);
  }
}

class InheritedStorage extends InheritedWidget {
  final DiaryStorage storage;
  const InheritedStorage({super.key, required this.storage, required super.child});

  static DiaryStorage of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedStorage>()!.storage;

  @override
  bool updateShouldNotify(covariant InheritedStorage oldWidget) =>
      oldWidget.storage != storage;
}

class DiaryHome extends StatefulWidget {
  const DiaryHome({super.key});

  @override
  State<DiaryHome> createState() => _DiaryHomeState();
}

class _DiaryHomeState extends State<DiaryHome> {
  late final DiaryStorage storage;
  final _controller = TextEditingController();
  bool _loading = true;
  String _todayPath = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    storage = InheritedStorage.of(context);
    _loadToday();
  }

  Future<void> _loadToday() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final yyyy = DateFormat('yyyy').format(now);
    final mm = DateFormat('MM').format(now);
    final dd = DateFormat('dd').format(now);

    _todayPath = '\$yyyy/\$mm/\$dd.md';
    await storage.ensureDirs([yyyy, mm]);

    final text = await storage.readText([yyyy, mm, '\$dd.md']) ?? '';
    _controller.text = text;
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final now = DateTime.now();
    final yyyy = DateFormat('yyyy').format(now);
    final mm = DateFormat('MM').format(now);
    final dd = DateFormat('dd').format(now);

    await storage.writeText([yyyy, mm, '\$dd.md'], _controller.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_todayPath.isEmpty ? 'Today' : _todayPath),
        actions: [
          IconButton(
            tooltip: 'Reload',
            onPressed: _loadToday,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Save',
            onPressed: _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  hintText: 'Write your diary entry here…',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save),
        label: const Text('Save'),
      ),
    );
  }
}
