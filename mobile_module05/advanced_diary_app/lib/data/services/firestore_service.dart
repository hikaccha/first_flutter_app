import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/diary_entry_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // 現在のユーザーIDを取得
  String? get _currentUserId => _auth.currentUser?.uid;

  // ユーザー固有のコレクション参照を取得
  CollectionReference? get _userDiariesCollection {
    final userId = _currentUserId;
    if (userId == null) return null;
    return _firestore.collection('users').doc(userId).collection('diaries');
  }

  // 全ての日記エントリを取得
  Future<List<DiaryEntryModel>> getAllEntries() async {
    try {
      final collection = _userDiariesCollection;
      if (collection == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final querySnapshot =
          await collection.orderBy('createdAt', descending: true).get();

      return querySnapshot.docs
          .map((doc) => DiaryEntryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting entries: $e');
      return [];
    }
  }

  // エントリのストリームを取得（リアルタイム更新用）
  Stream<List<DiaryEntryModel>> getEntriesStream() {
    return watchEntries();
  }

  // IDで特定のエントリを取得
  Future<DiaryEntryModel?> getEntryById(String id) async {
    return await getEntry(id);
  }

  // 特定の日付のエントリを取得
  Future<List<DiaryEntryModel>> getEntriesByDate(DateTime date) async {
    try {
      final collection = _userDiariesCollection;
      if (collection == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // 日付の開始と終了を設定
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final querySnapshot = await collection
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DiaryEntryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting entries by date: $e');
      return [];
    }
  }

  // 日付範囲でエントリを取得
  Future<List<DiaryEntryModel>> getEntriesByDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final collection = _userDiariesCollection;
      if (collection == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final querySnapshot = await collection
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => DiaryEntryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting entries by date range: $e');
      return [];
    }
  }

  // エントリを更新
  Future<void> updateEntry(DiaryEntryModel entry) async {
    await saveEntry(entry);
  }

  // 日記エントリを保存（新規作成または更新）
  Future<void> saveEntry(DiaryEntryModel entry) async {
    try {
      final collection = _userDiariesCollection;
      if (collection == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // ユーザーIDとメールアドレスを設定
      final updatedEntry = entry.copyWith(
        userId: _currentUserId!,
        userEmail: _auth.currentUser?.email ?? '',
      );

      if (updatedEntry.id.isEmpty) {
        // 新規作成の場合
        final docRef = await collection.add(updatedEntry.toFirestore());
        // 新しいIDでエントリを更新
        final finalEntry = updatedEntry.copyWith(id: docRef.id);
        await collection.doc(docRef.id).set(finalEntry.toFirestore());
      } else {
        // 更新の場合
        await collection.doc(updatedEntry.id).set(updatedEntry.toFirestore());
      }
    } catch (e) {
      print('Error saving entry: $e');
      rethrow;
    }
  }

  // 日記エントリを削除
  Future<void> deleteEntry(String id) async {
    try {
      final collection = _userDiariesCollection;
      if (collection == null) {
        throw Exception('ユーザーがログインしていません');
      }

      await collection.doc(id).delete();
    } catch (e) {
      print('Error deleting entry: $e');
      rethrow;
    }
  }

  // リアルタイムで日記エントリを監視
  Stream<List<DiaryEntryModel>> watchEntries() {
    final collection = _userDiariesCollection;
    if (collection == null) {
      return Stream.value([]);
    }

    return collection.orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => DiaryEntryModel.fromFirestore(doc))
            .toList());
  }

  // 特定の日記エントリを取得
  Future<DiaryEntryModel?> getEntry(String id) async {
    try {
      final collection = _userDiariesCollection;
      if (collection == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final doc = await collection.doc(id).get();
      if (doc.exists) {
        return DiaryEntryModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting entry: $e');
      return null;
    }
  }
}
