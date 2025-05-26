import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/services/firestore_service.dart';
import '../../domain/entities/diary_entry.dart';
import '../widgets/mood_display.dart';
import 'profile_page.dart';

class AgendaPage extends StatefulWidget {
  @override
  _AgendaPageState createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final FirestoreService _firestoreService = FirestoreService();

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<DiaryEntry> _allEntries = [];
  List<DiaryEntry> _selectedDayEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);

    try {
      final entries = await _firestoreService.getAllEntries();

      if (mounted) {
        setState(() {
          _allEntries = entries;
          _selectedDayEntries = _getEntriesForDay(_selectedDay);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading entries: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<DiaryEntry> _getEntriesForDay(DateTime day) {
    return _allEntries.where((entry) {
      return isSameDay(entry.createdAt, day);
    }).toList();
  }

  List<DiaryEntry> _getEntriesForRange(DateTime start, DateTime end) {
    return _allEntries.where((entry) {
      return entry.createdAt.isAfter(start.subtract(Duration(days: 1))) &&
          entry.createdAt.isBefore(end.add(Duration(days: 1)));
    }).toList();
  }

  bool _hasEntriesForDay(DateTime day) {
    return _allEntries.any((entry) => isSameDay(entry.createdAt, day));
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
      try {
        await _firestoreService.deleteEntry(entry.id);
        await _loadEntries(); // データを再読み込み

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('日記を削除しました')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除に失敗しました: $e')),
          );
        }
      }
    }
  }

  Widget _buildCalendar() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar<DiaryEntry>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

        // カレンダーのスタイル設定
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: Colors.red[400]),
          holidayTextStyle: TextStyle(color: Colors.red[400]),

          // 今日の日付のスタイル
          todayDecoration: BoxDecoration(
            color: Colors.blue[300],
            shape: BoxShape.circle,
          ),

          // 選択された日付のスタイル
          selectedDecoration: BoxDecoration(
            color: Colors.blue[600],
            shape: BoxShape.circle,
          ),

          // エントリーがある日のマーカー
          markerDecoration: BoxDecoration(
            color: Colors.orange[400],
            shape: BoxShape.circle,
          ),

          markersMaxCount: 1,
          markerSize: 6.0,
          markerMargin: EdgeInsets.symmetric(horizontal: 1.0),
        ),

        // ヘッダーのスタイル設定
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.blue[600]),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.blue[600]),
        ),

        // 曜日のスタイル設定
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
          weekendStyle:
              TextStyle(fontWeight: FontWeight.bold, color: Colors.red[400]),
        ),

        // イベント（エントリー）の取得
        eventLoader: (day) {
          return _getEntriesForDay(day);
        },

        // 日付選択時のコールバック
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
              _selectedDayEntries = _getEntriesForDay(selectedDay);
            });
          }
        },

        // ページ変更時のコールバック
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  Widget _buildEntriesList() {
    if (_selectedDayEntries.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.event_note,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              '${_selectedDay.month}月${_selectedDay.day}日の日記はありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.event, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text(
                '${_selectedDay.year}年${_selectedDay.month}月${_selectedDay.day}日の日記',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedDayEntries.length}件',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _selectedDayEntries.length,
            itemBuilder: (context, index) {
              final entry = _selectedDayEntries[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Dismissible(
                  key: Key(entry.id),
                  background: Container(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) => _deleteEntry(entry),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        MoodDisplay(mood: entry.mood, showLabel: false),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          entry.content.length > 50
                              ? '${entry.content.substring(0, 50)}...'
                              : entry.content,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DiaryViewPage(entry: entry),
                        ),
                      );
                      if (result == true) {
                        await _loadEntries();
                      }
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red[400]),
                      onPressed: () => _deleteEntry(entry),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('アジェンダ'),
        backgroundColor: Colors.blue[50],
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendar(),
                Expanded(
                  child: _buildEntriesList(),
                ),
              ],
            ),
    );
  }
}
