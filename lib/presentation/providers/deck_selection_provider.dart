import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/deck_entity.dart';

part 'deck_selection_provider.g.dart';

@riverpod
class DeckSelectionController extends _$DeckSelectionController {
  @override
  DeckSelectionState build() => const DeckSelectionState();

  void toggleSelectionMode() {
    state = state.copyWith(
      isSelecting: !state.isSelecting,
      selectedDecks: {},
    );
  }

  void toggleDeckSelection(DeckEntity deck) {
    if (!state.isSelecting) {
      state = state.copyWith(isSelecting: true);
    }

    final selectedDecks = Set<DeckEntity>.from(state.selectedDecks);
    if (selectedDecks.contains(deck)) {
      selectedDecks.remove(deck);
    } else {
      selectedDecks.add(deck);
    }

    state = state.copyWith(selectedDecks: selectedDecks);

    if (selectedDecks.isEmpty) {
      state = state.copyWith(isSelecting: false);
    }
  }

  void selectAllDecks(List<DeckEntity> decks) {
    state = state.copyWith(
      isSelecting: true,
      selectedDecks: Set<DeckEntity>.from(decks),
    );
  }

  void clearSelection() {
    state = state.copyWith(
      isSelecting: false,
      selectedDecks: {},
    );
  }

  bool isDeckSelected(DeckEntity deck) {
    return state.selectedDecks.contains(deck);
  }
}

class DeckSelectionState {
  final bool isSelecting;
  final Set<DeckEntity> selectedDecks;

  const DeckSelectionState({
    this.isSelecting = false,
    this.selectedDecks = const {},
  });

  DeckSelectionState copyWith({
    bool? isSelecting,
    Set<DeckEntity>? selectedDecks,
  }) {
    return DeckSelectionState(
      isSelecting: isSelecting ?? this.isSelecting,
      selectedDecks: selectedDecks ?? this.selectedDecks,
    );
  }
} 