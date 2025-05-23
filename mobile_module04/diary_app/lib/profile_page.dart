import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'auth_service.dart';

class DiaryEntry {
  String id;
  String title;
  String content;
  DateTime createdAt;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class DiaryService {
  static const String _storageKey = 'diary_entries';

  Future<List<DiaryEntry>> getAllEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList(_storageKey) ?? [];

    if (entriesJson.isEmpty) {
      return [];
    }

    try {
      return entriesJson.map((json) {
        final parts = json.split(',');
        final map = <String, dynamic>{};

        for (final part in parts) {
          final keyValue = part.split(':');
          if (keyValue.length >= 2) {
            final key = keyValue[0];
            final value = keyValue.sublist(1).join(':');
            map[key] = value;
          }
        }

        return DiaryEntry.fromJson(map);
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error parsing entries: $e');
      return [];
    }
  }

  Future<void> saveEntry(DiaryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getAllEntries();

    final existingIndex = entries.indexWhere((e) => e.id == entry.id);

    if (existingIndex >= 0) {
      entries[existingIndex] = entry;
    } else {
      entries.add(entry);
    }

    await prefs.setStringList(
        _storageKey,
        entries
            .map((e) =>
                'id:${e.id},title:${e.title},content:${e.content},createdAt:${e.createdAt.toIso8601String()}')
            .toList());
  }

  Future<void> deleteEntry(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await getAllEntries();

    entries.removeWhere((entry) => entry.id == id);

    await prefs.setStringList(
        _storageKey,
        entries
            .map((e) =>
                'id:${e.id},title:${e.title},content:${e.content},createdAt:${e.createdAt.toIso8601String()}')
            .toList());
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DiaryService _diaryService = DiaryService();
  final AuthService _authService = AuthService();
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserAndEntries();
  }

  Future<void> _loadUserAndEntries() async {
    setState(() => _isLoading = true);

    try {
      _currentUser = await _authService.getCurrentUser();
      final entries = await _diaryService.getAllEntries();

      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user and entries: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _safeSignOut() async {
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('ログアウト'),
          content: Text('ログアウトしてもよろしいですか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('ログアウト'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      print('Error during sign out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ログアウトエラー: $e')),
        );
      }
    }
  }

  Future<void> _createNewEntry() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DiaryEditorPage()),
    );

    if (result == true) {
      _loadUserAndEntries();
    }
  }

  Future<void> _deleteEntry(DiaryEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('日記の削除'),
        content: Text('この日記を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('削除'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _diaryService.deleteEntry(entry.id);
      _loadUserAndEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('マイ日記'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _safeSignOut,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      (_currentUser != null && _currentUser!.photoURL != null)
                          ? CircleAvatar(
                              radius: 30,
                              backgroundImage:
                                  NetworkImage(_currentUser!.photoURL!),
                            )
                          : CircleAvatar(
                              radius: 30,
                              child: Icon(Icons.person),
                            ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentUser?.displayName ?? 'ユーザー',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _currentUser?.email ?? 'メールアドレスなし',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(),
                Expanded(
                  child: _entries.isEmpty
                      ? Center(child: Text('日記がありません。新しい日記を作成しましょう！'))
                      : ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            return Dismissible(
                              key: Key(entry.id),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: Icon(Icons.delete, color: Colors.white),
                              ),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) => _deleteEntry(entry),
                              child: ListTile(
                                title: Text(entry.title),
                                subtitle: Text(
                                  '${entry.createdAt.year}/${entry.createdAt.month}/${entry.createdAt.day}',
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DiaryViewPage(entry: entry),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadUserAndEntries();
                                  }
                                },
                                trailing: IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _deleteEntry(entry),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewEntry,
        child: Icon(Icons.add),
        tooltip: '新しい日記を作成',
      ),
    );
  }
}

class DiaryEditorPage extends StatefulWidget {
  final DiaryEntry? entry;

  DiaryEditorPage({this.entry});

  @override
  _DiaryEditorPageState createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  final DiaryService _diaryService = DiaryService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
    }
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final entry = DiaryEntry(
        id: widget.entry?.id ?? const Uuid().v4(),
        title: _titleController.text,
        content: _contentController.text,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
      );

      await _diaryService.saveEntry(entry);
      Navigator.pop(context, true);
    } catch (e) {
      print('Error saving entry: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました')),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? '新しい日記' : '日記を編集'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _saveEntry,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'タイトル',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 1,
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: '内容',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

class DiaryViewPage extends StatelessWidget {
  final DiaryEntry entry;
  final DiaryService _diaryService = DiaryService();

  DiaryViewPage({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.title),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiaryEditorPage(entry: entry),
                ),
              );
              if (result == true) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('日記の削除'),
                  content: Text('この日記を削除してもよろしいですか？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('キャンセル'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('削除'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await _diaryService.deleteEntry(entry.id);
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.createdAt.year}年${entry.createdAt.month}月${entry.createdAt.day}日',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            Text(
              entry.title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  entry.content,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
