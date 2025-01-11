import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/deck_entity.dart';
import '../../data/repositories/deck_repository.dart';
import '../../data/repositories/card_repository.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'deck_list_provider.dart';
import 'package:uuid/uuid.dart';
import 'card_image_provider.dart';

part 'ai_deck_provider.g.dart';

@riverpod
class CreateAIDeckNotifier extends _$CreateAIDeckNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<DeckEntity> createDeck({
    required String name,
    String? description,
    required List<Map<String, String>> cards,
  }) async {
    state = const AsyncLoading();
    
    try {
      debugPrint('Creating new AI deck: $name');
      final deckRepository = ref.read(deckRepositoryProvider);
      final cardRepository = ref.read(cardRepositoryProvider);
      final cardImageNotifier = ref.read(cardImageNotifierProvider.notifier);
      
      // Vytvoříme balíček
      final newDeck = await deckRepository.createDeck(
        name: name,
        description: description,
      );
      
      debugPrint('New AI deck created: ${newDeck.id}');
      
      // Vytvoříme kartičky a přesuneme jejich obrázky
      for (final card in cards) {
        if (card['front']?.isNotEmpty == true || card['back']?.isNotEmpty == true) {
          debugPrint('Creating card for AI deck: ${newDeck.id}');
          final newCard = await cardRepository.createCard(
            deckId: newDeck.id,
            frontContent: card['front'] ?? '',
            backContent: card['back'] ?? '',
          );
          
          // Přesuneme dočasné obrázky do finální pozice
          final tempCardId = card['id'];
          if (tempCardId != null) {
            await cardImageNotifier.finalizeTempImages(tempCardId, newCard.id);
          }
          
          debugPrint('Card created for AI deck');
        }
      }
      
      // Invalidujeme seznam balíčků aby se zobrazil nový balíček
      ref.invalidate(deckListProvider);
      
      state = const AsyncData(null);
      return newDeck;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

@riverpod
class AICardListNotifier extends _$AICardListNotifier {
  @override
  List<Map<String, String>> build() {
    // Inicializujeme tři prázdné kartičky
    return [
      {'id': const Uuid().v4(), 'front': '', 'back': ''},
      {'id': const Uuid().v4(), 'front': '', 'back': ''},
      {'id': const Uuid().v4(), 'front': '', 'back': ''},
    ];
  }

  void addCard() {
    state = [...state, {'id': const Uuid().v4(), 'front': '', 'back': ''}];
  }

  void removeCard(int index) {
    final newState = [...state];
    newState.removeAt(index);
    state = newState;
  }

  void updateCard(int index, String front, String back) {
    if (index >= state.length) return;
    
    final newState = [...state];
    final cardId = newState[index]['id'] ?? const Uuid().v4();
    newState[index] = {'id': cardId, 'front': front, 'back': back};
    state = newState;
  }

  void insertCard(int index) {
    if (index > state.length) return;
    
    final newState = [...state];
    newState.insert(index, {'id': const Uuid().v4(), 'front': '', 'back': ''});
    state = newState;
  }

  String getCardId(int index) {
    if (index >= state.length) return '';
    return state[index]['id'] ?? '';
  }

  void setCardId(int index, String id) {
    if (index >= state.length) return;
    
    final newState = [...state];
    final card = newState[index];
    newState[index] = {
      ...card,
      'id': id,
    };
    state = newState;
  }

  String getFront(int index) {
    if (index >= state.length) return '';
    return state[index]['front'] ?? '';
  }

  String getBack(int index) {
    if (index >= state.length) return '';
    return state[index]['back'] ?? '';
  }

  int get cardCount => state.length;
} 