import 'package:flutter/material.dart';

enum DifficultyLevel {
  easy,
  medium,
  hard;

  String get label {
    switch (this) {
      case DifficultyLevel.easy:
        return 'Snadné';
      case DifficultyLevel.medium:
        return 'Střední';
      case DifficultyLevel.hard:
        return 'Těžké';
    }
  }

  Color get color {
    switch (this) {
      case DifficultyLevel.easy:
        return Colors.green;
      case DifficultyLevel.medium:
        return Colors.orange;
      case DifficultyLevel.hard:
        return Colors.red;
    }
  }
} 