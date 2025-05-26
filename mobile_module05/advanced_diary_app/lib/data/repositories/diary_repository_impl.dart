import '../../domain/entities/diary_entry.dart';
import '../../domain/repositories/diary_repository.dart';
import '../models/diary_entry_model.dart';
import '../services/firestore_service.dart';

class DiaryRepositoryImpl implements DiaryRepository {
  final FirestoreService _firestoreService;

  DiaryRepositoryImpl(this._firestoreService);

  @override
  Stream<List<DiaryEntry>> getEntriesStream() {
    return _firestoreService
        .getEntriesStream()
        .map((entries) => entries.cast<DiaryEntry>());
  }

  @override
  Future<List<DiaryEntry>> getAllEntries() async {
    final models = await _firestoreService.getAllEntries();
    return models.cast<DiaryEntry>();
  }

  @override
  Future<DiaryEntry?> getEntryById(String id) async {
    final model = await _firestoreService.getEntryById(id);
    return model;
  }

  @override
  Future<List<DiaryEntry>> getEntriesByDate(DateTime date) async {
    final models = await _firestoreService.getEntriesByDate(date);
    return models.cast<DiaryEntry>();
  }

  @override
  Future<List<DiaryEntry>> getEntriesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final models =
        await _firestoreService.getEntriesByDateRange(startDate, endDate);
    return models.cast<DiaryEntry>();
  }

  @override
  Future<void> saveEntry(DiaryEntry entry) async {
    final model = DiaryEntryModel.fromEntity(entry);
    await _firestoreService.saveEntry(model);
  }

  @override
  Future<void> updateEntry(DiaryEntry entry) async {
    final model = DiaryEntryModel.fromEntity(entry);
    await _firestoreService.updateEntry(model);
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _firestoreService.deleteEntry(id);
  }

  @override
  Future<Map<String, int>> getMoodStatistics() async {
    final entries = await getAllEntries();
    final Map<String, int> statistics = {};

    for (final entry in entries) {
      final moodName = entry.mood.name;
      statistics[moodName] = (statistics[moodName] ?? 0) + 1;
    }

    return statistics;
  }

  @override
  Future<int> getTotalEntriesCount() async {
    final entries = await getAllEntries();
    return entries.length;
  }

  @override
  Future<List<DiaryEntry>> searchEntries(String query) async {
    final entries = await getAllEntries();
    return entries.where((entry) {
      return entry.title.toLowerCase().contains(query.toLowerCase()) ||
          entry.content.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Future<List<DiaryEntry>> getFavoriteEntries() async {
    final entries = await getAllEntries();
    return entries.where((entry) => entry.isFavorite).toList();
  }
}
