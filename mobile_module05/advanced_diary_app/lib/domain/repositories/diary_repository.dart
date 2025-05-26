import '../entities/diary_entry.dart';

abstract class DiaryRepository {
  Stream<List<DiaryEntry>> getEntriesStream();
  Future<List<DiaryEntry>> getAllEntries();
  Future<DiaryEntry?> getEntryById(String id);
  Future<List<DiaryEntry>> getEntriesByDate(DateTime date);
  Future<List<DiaryEntry>> getEntriesByDateRange(
      DateTime startDate, DateTime endDate);
  Future<void> saveEntry(DiaryEntry entry);
  Future<void> updateEntry(DiaryEntry entry);
  Future<void> deleteEntry(String id);
  Future<Map<String, int>> getMoodStatistics();
  Future<int> getTotalEntriesCount();
  Future<List<DiaryEntry>> searchEntries(String query);
  Future<List<DiaryEntry>> getFavoriteEntries();
}
