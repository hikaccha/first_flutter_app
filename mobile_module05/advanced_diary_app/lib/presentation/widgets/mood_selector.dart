import 'package:flutter/material.dart';
import '../../domain/entities/mood_type.dart';

class MoodSelector extends StatelessWidget {
  final MoodType selectedMood;
  final ValueChanged<MoodType> onMoodChanged;

  const MoodSelector({
    Key? key,
    required this.selectedMood,
    required this.onMoodChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今日の気分',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: MoodType.values.map((mood) {
              final isSelected = mood == selectedMood;
              return GestureDetector(
                onTap: () => onMoodChanged(mood),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue[100] : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: Colors.blue, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mood.emoji,
                        style: TextStyle(
                          fontSize: isSelected ? 32 : 28,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        mood.label,
                        style: TextStyle(
                          fontSize: 10,
                          color:
                              isSelected ? Colors.blue[700] : Colors.grey[600],
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
