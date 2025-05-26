enum MoodType {
  veryHappy,
  happy,
  neutral,
  sad,
  verySad;

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

  String get description {
    switch (this) {
      case MoodType.veryHappy:
        return '最高の気分です！';
      case MoodType.happy:
        return '良い気分です';
      case MoodType.neutral:
        return '普通の気分です';
      case MoodType.sad:
        return '少し落ち込んでいます';
      case MoodType.verySad:
        return 'とても落ち込んでいます';
    }
  }

  int get value {
    switch (this) {
      case MoodType.veryHappy:
        return 5;
      case MoodType.happy:
        return 4;
      case MoodType.neutral:
        return 3;
      case MoodType.sad:
        return 2;
      case MoodType.verySad:
        return 1;
    }
  }

  static MoodType fromValue(int value) {
    switch (value) {
      case 5:
        return MoodType.veryHappy;
      case 4:
        return MoodType.happy;
      case 3:
        return MoodType.neutral;
      case 2:
        return MoodType.sad;
      case 1:
        return MoodType.verySad;
      default:
        return MoodType.neutral;
    }
  }

  static MoodType fromString(String mood) {
    switch (mood.toLowerCase()) {
      case 'veryhappy':
        return MoodType.veryHappy;
      case 'happy':
        return MoodType.happy;
      case 'neutral':
        return MoodType.neutral;
      case 'sad':
        return MoodType.sad;
      case 'verysad':
        return MoodType.verySad;
      default:
        return MoodType.neutral;
    }
  }
}
