import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

// 気分の種類を定義
enum MoodType {
  veryHappy,
  happy,
  neutral,
  sad,
  verySad,
}

// 気分の拡張メソッド
extension MoodTypeExtension on MoodType {
  String get emoji {
    switch (this) {
      case MoodType.veryHappy:
        return '😄';
      case MoodType.happy:
        return '😊';
      case MoodType.neutral:
        return '😐';
      case MoodType.sad:
        return '😢';
      case MoodType.verySad:
        return '😭';
    }
  }

  String get label {
    switch (this) {
      case MoodType.veryHappy:
        return 'とても嬉しい';
      case MoodType.happy:
        return '嬉しい';
      case MoodType.neutral:
        return '普通';
      case MoodType.sad:
        return '悲しい';
      case MoodType.verySad:
        return 'とても悲しい';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  static MoodType fromString(String value) {
    return MoodType.values.firstWhere(
      (mood) => mood.value == value,
      orElse: () => MoodType.neutral,
    );
  }
}

class DiaryEntry {
  String id;
  String title;
  String content;
  DateTime createdAt;
  String userId;
  String userEmail; // ユーザーのメールアドレスを追加
  MoodType mood; // その日の気分を追加

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.userId,
    required this.userEmail,
    required this.mood,
  });

  factory DiaryEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiaryEntry(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      mood: MoodTypeExtension.fromString(data['mood'] ?? 'neutral'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'userId': userId,
      'userEmail': userEmail,
      'mood': mood.value,
    };
  }

  // 既存のJSONメソッドも保持（互換性のため）
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      userId: json['userId'] ?? '',
      userEmail: json['userEmail'] ?? '',
      mood: MoodTypeExtension.fromString(json['mood'] ?? 'neutral'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
      'userEmail': userEmail,
      'mood': mood.value,
    };
  }
}

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
  Future<List<DiaryEntry>> getAllEntries() async {
    try {
      final collection = _userDiariesCollection;
      if (collection == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final querySnapshot =
          await collection.orderBy('createdAt', descending: true).get();

      return querySnapshot.docs
          .map((doc) => DiaryEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting entries: $e');
      return [];
    }
  }

  // 日記エントリを保存（新規作成または更新）
  Future<void> saveEntry(DiaryEntry entry) async {
    try {
      final collection = _userDiariesCollection;
      if (collection == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // ユーザーIDとメールアドレスを設定
      entry.userId = _currentUserId!;
      entry.userEmail = _auth.currentUser?.email ?? '';

      if (entry.id.isEmpty) {
        // 新規作成の場合
        final docRef = await collection.add(entry.toFirestore());
        entry.id = docRef.id;
      } else {
        // 更新の場合
        await collection.doc(entry.id).set(entry.toFirestore());
      }
    } catch (e) {
      print('Error saving entry: $e');
      throw e;
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
      throw e;
    }
  }

  // リアルタイムで日記エントリを監視
  Stream<List<DiaryEntry>> watchEntries() {
    final collection = _userDiariesCollection;
    if (collection == null) {
      return Stream.value([]);
    }

    return collection.orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => DiaryEntry.fromFirestore(doc)).toList());
  }

  // 特定の日記エントリを取得
  Future<DiaryEntry?> getEntry(String id) async {
    try {
      final collection = _userDiariesCollection;
      if (collection == null) {
        throw Exception('ユーザーがログインしていません');
      }

      final doc = await collection.doc(id).get();
      if (doc.exists) {
        return DiaryEntry.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting entry: $e');
      return null;
    }
  }
}
