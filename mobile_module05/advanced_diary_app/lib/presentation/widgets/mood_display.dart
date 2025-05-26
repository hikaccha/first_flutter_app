import 'package:flutter/material.dart';
import '../../domain/entities/mood_type.dart';

class MoodDisplay extends StatelessWidget {
  final MoodType mood;
  final double size;
  final bool showLabel;

  const MoodDisplay({
    super.key,
    required this.mood,
    this.size = 24.0,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getMoodColor(mood).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getMoodColor(mood).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mood.emoji,
            style: TextStyle(fontSize: size),
          ),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              mood.label,
              style: TextStyle(
                fontSize: size * 0.6,
                color: _getMoodColor(mood),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getMoodColor(MoodType mood) {
    switch (mood) {
      case MoodType.veryHappy:
        return Colors.green[600]!;
      case MoodType.happy:
        return Colors.lightGreen[600]!;
      case MoodType.neutral:
        return Colors.grey[600]!;
      case MoodType.sad:
        return Colors.orange[600]!;
      case MoodType.verySad:
        return Colors.red[600]!;
    }
  }
}
