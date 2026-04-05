import 'package:flutter/material.dart';
import '../core/neumorphic.dart';
import '../core/theme/app_theme.dart';

class MoodSelector extends StatelessWidget {
  final int? selected;
  final ValueChanged<int> onChanged;

  const MoodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const _moods = [
    (value: 1, emoji: '😣', label: '低能量'),
    (value: 2, emoji: '😐', label: '平稳'),
    (value: 3, emoji: '🙂', label: '还不错'),
    (value: 4, emoji: '😊', label: '顺手'),
    (value: 5, emoji: '🤩', label: '高光'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _moods.map((mood) {
        final isSelected = selected == mood.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: mood.value == _moods.last.value ? 0 : AppTheme.spacingS,
            ),
            child: NeuIconButton(
              size: 62,
              isSelected: isSelected,
              onPressed: () => onChanged(mood.value),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: TextStyle(fontSize: isSelected ? 25 : 22),
                    child: Text(mood.emoji),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mood.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
