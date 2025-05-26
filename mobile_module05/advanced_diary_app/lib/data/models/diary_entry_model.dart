import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/diary_entry.dart';
import '../../domain/entities/mood_type.dart';

class DiaryEntryModel extends DiaryEntry {
  const DiaryEntryModel({
    required super.id,
    required super.title,
    required super.content,
    required super.createdAt,
    super.updatedAt,
    required super.userId,
    required super.userEmail,
    required super.mood,
    super.tags,
    super.isFavorite,
  });

  factory DiaryEntryModel.fromEntity(DiaryEntry entry) {
    return DiaryEntryModel(
      id: entry.id,
      title: entry.title,
      content: entry.content,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
      userId: entry.userId,
      userEmail: entry.userEmail,
      mood: entry.mood,
      tags: entry.tags,
      isFavorite: entry.isFavorite,
    );
  }

  factory DiaryEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DiaryEntryModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      mood: MoodType.fromString(data['mood'] ?? 'neutral'),
      tags: List<String>.from(data['tags'] ?? []),
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  factory DiaryEntryModel.fromJson(Map<String, dynamic> json) {
    return DiaryEntryModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      userId: json['userId'] ?? '',
      userEmail: json['userEmail'] ?? '',
      mood: MoodType.fromString(json['mood'] ?? 'neutral'),
      tags: List<String>.from(json['tags'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'userId': userId,
      'userEmail': userEmail,
      'mood': mood.name,
      'tags': tags,
      'isFavorite': isFavorite,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'userId': userId,
      'userEmail': userEmail,
      'mood': mood.name,
      'tags': tags,
      'isFavorite': isFavorite,
    };
  }

  @override
  DiaryEntryModel copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? userEmail,
    MoodType? mood,
    List<String>? tags,
    bool? isFavorite,
  }) {
    return DiaryEntryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
