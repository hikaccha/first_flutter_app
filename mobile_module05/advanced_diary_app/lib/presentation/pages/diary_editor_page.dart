import 'package:flutter/material.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/diary_entry_model.dart';
import '../../domain/entities/diary_entry.dart';
import '../../domain/entities/mood_type.dart';
import '../widgets/mood_selector.dart';

class DiaryEditorPage extends StatefulWidget {
  final DiaryEntry? entry;

  DiaryEditorPage({this.entry});

  @override
  _DiaryEditorPageState createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isLoading = false;
  MoodType _selectedMood = MoodType.neutral;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _titleController.text = widget.entry!.title;
      _contentController.text = widget.entry!.content;
      _selectedMood = widget.entry!.mood;
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
      final entry = DiaryEntryModel(
        id: widget.entry?.id ?? '',
        title: _titleController.text,
        content: _contentController.text,
        createdAt: widget.entry?.createdAt ?? DateTime.now(),
        userId: '', // FirestoreServiceで自動設定される
        userEmail: '', // FirestoreServiceで自動設定される
        mood: _selectedMood,
      );

      await _firestoreService.saveEntry(entry);
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
                  MoodSelector(
                    selectedMood: _selectedMood,
                    onMoodChanged: (MoodType mood) {
                      setState(() {
                        _selectedMood = mood;
                      });
                    },
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
