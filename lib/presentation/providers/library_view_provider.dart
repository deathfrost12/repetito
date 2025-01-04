import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/enums/library_view_type.dart';

part 'library_view_provider.g.dart';

@riverpod
class LibraryViewController extends _$LibraryViewController {
  @override
  LibraryViewType build() => LibraryViewType.grid;

  void toggleView() {
    state = state == LibraryViewType.grid
        ? LibraryViewType.list
        : LibraryViewType.grid;
  }

  void setView(LibraryViewType viewType) {
    state = viewType;
  }
} 