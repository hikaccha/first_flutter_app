import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/diary_entry.dart';
import '../../domain/entities/mood_type.dart';
import '../../domain/repositories/diary_repository.dart';
import '../../core/utils/date_utils.dart';

class DiaryProvider extends ChangeNotifier {
  final DiaryRepository _repository;

  DiaryProvider(this._repository) {
    _initializeStream();
  }

  // State
  List<DiaryEntry> _entries = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription<List<DiaryEntry>>? _entriesSubscription;

  // Getters
  List<DiaryEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 最新のエントリー（指定された数）
  List<DiaryEntry> getRecentEntries(int count) {
    return _entries.take(count).toList();
  }

  // 特定の日付のエントリー
  List<DiaryEntry> getEntriesForDay(DateTime day) {
    return _entries.where((entry) {
      return AppDateUtils.isSameDay(entry.createdAt, day);
    }).toList();
  }

  // 気分の統計
  Map<MoodType, double> getMoodStatistics() {
    if (_entries.isEmpty) return {};

    final Map<MoodType, int> moodCounts = {};
    for (final mood in MoodType.values) {
      moodCounts[mood] = 0;
    }

    for (final entry in _entries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }

    final Map<MoodType, double> moodPercentages = {};
    for (final mood in MoodType.values) {
      moodPercentages[mood] = (moodCounts[mood]! / _entries.length) * 100;
    }

    return moodPercentages;
  }

  // 総エントリー数
  int get totalEntriesCount => _entries.length;

  // お気に入りエントリー
  List<DiaryEntry> get favoriteEntries {
    return _entries.where((entry) => entry.isFavorite).toList();
  }

  // リアルタイムストリームの初期化
  void _initializeStream() {
    _entriesSubscription?.cancel();
    _entriesSubscription = _repository.getEntriesStream().listen(
      (entries) {
        _entries = entries;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // エントリーを保存
  Future<void> saveEntry(DiaryEntry entry) async {
    try {
      _setLoading(true);
      await _repository.saveEntry(entry);
      _clearError();
    } catch (e) {
      _setError('エントリーの保存に失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  // エントリーを更新
  Future<void> updateEntry(DiaryEntry entry) async {
    try {
      _setLoading(true);
      await _repository.updateEntry(entry);
      _clearError();
    } catch (e) {
      _setError('エントリーの更新に失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  // エントリーを削除
  Future<void> deleteEntry(String id) async {
    try {
      _setLoading(true);
      await _repository.deleteEntry(id);
      _clearError();
    } catch (e) {
      _setError('エントリーの削除に失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  // エントリーを検索
  Future<List<DiaryEntry>> searchEntries(String query) async {
    try {
      return await _repository.searchEntries(query);
    } catch (e) {
      _setError('検索に失敗しました: $e');
      return [];
    }
  }

  // 手動でデータを再読み込み
  Future<void> refreshEntries() async {
    try {
      _setLoading(true);
      final entries = await _repository.getAllEntries();
      _entries = entries;
      _clearError();
    } catch (e) {
      _setError('データの読み込みに失敗しました: $e');
    } finally {
      _setLoading(false);
    }
  }

  // 特定の日付範囲のエントリーを取得
  Future<List<DiaryEntry>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _repository.getEntriesByDateRange(startDate, endDate);
    } catch (e) {
      _setError('データの取得に失敗しました: $e');
      return [];
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _entriesSubscription?.cancel();
    super.dispose();
  }
}
