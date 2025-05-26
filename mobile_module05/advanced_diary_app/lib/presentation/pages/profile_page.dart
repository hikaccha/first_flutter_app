import 'package:flutter/material.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/firestore_service.dart';
import '../../domain/entities/diary_entry.dart';
import '../../domain/entities/mood_type.dart';
import '../widgets/mood_display.dart';
import 'diary_editor_page.dart';

// DiaryEntryクラスとDiaryServiceクラスはfirestore_service.dartに移動

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  // final MigrationService _migrationService = MigrationService();
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

      // データ移行を実行
      // await _migrationService.migrateDataToFirestore();

      final entries = await _firestoreService.getAllEntries();

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

  // 気分の使用率を計算するメソッド
  Map<MoodType, double> _calculateMoodUsage() {
    if (_entries.isEmpty) {
      return {};
    }

    Map<MoodType, int> moodCounts = {};
    for (MoodType mood in MoodType.values) {
      moodCounts[mood] = 0;
    }

    for (DiaryEntry entry in _entries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }

    Map<MoodType, double> moodUsage = {};
    for (MoodType mood in MoodType.values) {
      moodUsage[mood] = (moodCounts[mood]! / _entries.length) * 100;
    }

    return moodUsage;
  }

  // 統計情報ウィジェットを作成
  Widget _buildStatisticsView() {
    final moodUsage = _calculateMoodUsage();

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text(
                '日記統計',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // 総数表示
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book, color: Colors.blue[600]),
                SizedBox(width: 8),
                Text(
                  '総日記数: ${_entries.length}件',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),

          if (_entries.isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              '気分の使用率',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 12),

            // 気分の使用率を表示
            ...MoodType.values.map((mood) {
              final percentage = moodUsage[mood] ?? 0;
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(mood.emoji, style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                mood.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getMoodColor(mood),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          if (_entries.length > 2) ...[
            SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllEntriesPage(entries: _entries),
                    ),
                  );
                },
                icon: Icon(Icons.list),
                label: Text('すべての日記を見る'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[600],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 気分に応じた色を取得
  Color _getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.veryHappy:
        return Colors.green[400]!;
      case MoodType.happy:
        return Colors.lightGreen[400]!;
      case MoodType.neutral:
        return Colors.grey[400]!;
      case MoodType.sad:
        return Colors.orange[400]!;
      case MoodType.verySad:
        return Colors.red[400]!;
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
      await _firestoreService.deleteEntry(entry.id);
      _loadUserAndEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 最新2件のエントリーを取得
    final recentEntries = _entries.take(2).toList();

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
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ユーザー情報セクション
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

                  // 最新の日記セクション
                  if (recentEntries.isNotEmpty) ...[
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.blue[600]),
                          SizedBox(width: 8),
                          Text(
                            '最新の日記',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...recentEntries.map((entry) {
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
                          title: Row(
                            children: [
                              Expanded(child: Text(entry.title)),
                              MoodDisplay(mood: entry.mood, showLabel: false),
                            ],
                          ),
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
                    }).toList(),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            '日記がありません',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '新しい日記を作成しましょう！',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // 統計情報セクション
                  _buildStatisticsView(),
                ],
              ),
            ),
    );
  }
}

// すべての日記を表示するページ
class AllEntriesPage extends StatelessWidget {
  final List<DiaryEntry> entries;
  final FirestoreService _firestoreService = FirestoreService();

  AllEntriesPage({required this.entries});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('すべての日記'),
      ),
      body: ListView.builder(
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return ListTile(
            title: Row(
              children: [
                Expanded(child: Text(entry.title)),
                MoodDisplay(mood: entry.mood, showLabel: false),
              ],
            ),
            subtitle: Text(
              '${entry.createdAt.year}/${entry.createdAt.month}/${entry.createdAt.day}',
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DiaryViewPage(entry: entry),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DiaryViewPage extends StatelessWidget {
  final DiaryEntry entry;
  final FirestoreService _firestoreService = FirestoreService();

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
                await _firestoreService.deleteEntry(entry.id);
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${entry.createdAt.year}年${entry.createdAt.month}月${entry.createdAt.day}日',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                MoodDisplay(mood: entry.mood),
              ],
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
