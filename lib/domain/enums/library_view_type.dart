import 'package:flutter/material.dart';

enum LibraryViewType {
  list,
  grid;

  String get label {
    switch (this) {
      case LibraryViewType.list:
        return 'Seznam';
      case LibraryViewType.grid:
        return 'Mřížka';
    }
  }

  IconData get icon {
    switch (this) {
      case LibraryViewType.list:
        return Icons.view_list_outlined;
      case LibraryViewType.grid:
        return Icons.grid_view_outlined;
    }
  }
} 