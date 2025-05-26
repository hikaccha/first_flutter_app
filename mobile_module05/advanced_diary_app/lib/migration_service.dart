// ローカルのデータをFirestoreに移行するためのコード
// import 'package:shared_preferences/shared_preferences.dart';
// import 'firestore_service.dart';

// class MigrationService {
//   final FirestoreService _firestoreService = FirestoreService();
//   static const String _storageKey = 'diary_entries';
//   static const String _migrationKey = 'data_migrated_to_firestore';

//   // データ移行が完了しているかチェック
//   Future<bool> isMigrationCompleted() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getBool(_migrationKey) ?? false;
//   }

//   // SharedPreferencesからFirestoreにデータを移行
//   Future<void> migrateDataToFirestore() async {
//     try {
//       // 既に移行済みの場合はスキップ
//       if (await isMigrationCompleted()) {
//         print('Migration already completed');
//         return;
//       }

//       final prefs = await SharedPreferences.getInstance();
//       final entriesJson = prefs.getStringList(_storageKey) ?? [];

//       if (entriesJson.isEmpty) {
//         print('No local data to migrate');
//         await _markMigrationCompleted();
//         return;
//       }

//       print('Starting migration of ${entriesJson.length} entries...');

//       // ローカルデータをパース
//       final localEntries = <DiaryEntry>[];
//       for (final json in entriesJson) {
//         try {
//           final parts = json.split(',');
//           final map = <String, dynamic>{};

//           for (final part in parts) {
//             final keyValue = part.split(':');
//             if (keyValue.length >= 2) {
//               final key = keyValue[0];
//               final value = keyValue.sublist(1).join(':');
//               map[key] = value;
//             }
//           }

//           // userIdとuserEmailを空文字で初期化（Firestoreサービスで設定される）
//           map['userId'] = '';
//           map['userEmail'] = '';
//           // 既存データには気分情報がないので、デフォルトで普通に設定
//           map['mood'] = 'neutral';

//           final entry = DiaryEntry.fromJson(map);
//           // IDをクリア（Firestoreで新しいIDが生成される）
//           entry.id = '';
//           localEntries.add(entry);
//         } catch (e) {
//           print('Error parsing entry: $e');
//           continue;
//         }
//       }

//       // Firestoreに保存
//       for (final entry in localEntries) {
//         try {
//           await _firestoreService.saveEntry(entry);
//           print('Migrated entry: ${entry.title}');
//         } catch (e) {
//           print('Error migrating entry "${entry.title}": $e');
//         }
//       }

//       // 移行完了をマーク
//       await _markMigrationCompleted();
//       print('Migration completed successfully');
//     } catch (e) {
//       print('Error during migration: $e');
//       throw e;
//     }
//   }

//   // 移行完了をマーク
//   Future<void> _markMigrationCompleted() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(_migrationKey, true);
//   }

//   // 移行状態をリセット（テスト用）
//   Future<void> resetMigrationStatus() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_migrationKey);
//   }

//   // ローカルデータをクリア（移行後の清掃用）
//   Future<void> clearLocalData() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_storageKey);
//     print('Local diary data cleared');
//   }
// }
