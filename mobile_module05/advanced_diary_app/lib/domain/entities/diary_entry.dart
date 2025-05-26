import 'package:equatable/equatable.dart';
import 'mood_type.dart';

class DiaryEntry extends Equatable {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String userId;
  final String userEmail;
  final MoodType mood;
  final List<String> tags;
  final bool isFavorite;

  const DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    required this.userId,
    required this.userEmail,
    required this.mood,
    this.tags = const [],
    this.isFavorite = false,
  });

  DiaryEntry copyWith({
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
    return DiaryEntry(
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

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        createdAt,
        updatedAt,
        userId,
        userEmail,
        mood,
        tags,
        isFavorite,
      ];

  @override
  String toString() {
    return 'DiaryEntry(id: $id, title: $title, mood: $mood, createdAt: $createdAt)';
  }
}
