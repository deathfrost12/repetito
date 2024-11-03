import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/deck_entity.dart';
import '../../data/repositories/deck_repository.dart';
import 'package:flutter/foundation.dart' show debugPrint;

part 'deck_list_provider.g.dart';

@riverpod
Stream<List<DeckEntity>> deckList(DeckListRef ref) {
  debugPrint('Initializing deck list stream');
  final repository = ref.watch(deckRepositoryProvider);
  return repository.watchDecks();
}

@riverpod
class CreateDeckNotifier extends _$CreateDeckNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> createDeck(String name, String? description) async {
    state = const AsyncLoading();
    
    state = await AsyncValue.guard(() async {
      debugPrint('Creating new deck: $name');
      final repository = ref.read(deckRepositoryProvider);
      await repository.createDeck(
        name: name,
        description: description,
      );
      debugPrint('Deck created successfully');
    });
  }
}

@riverpod
class DeleteDeckNotifier extends _$DeleteDeckNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> deleteDeck(String deckId) async {
    state = const AsyncLoading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(deckRepositoryProvider);
      await repository.deleteDeck(deckId);
    });
  }
}

@riverpod
class UpdateDeckNotifier extends _$UpdateDeckNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> updateDeck({
    required String deckId,
    required String name,
    String? description,
  }) async {
    state = const AsyncLoading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(deckRepositoryProvider);
      await repository.updateDeck(
        deckId: deckId,
        name: name,
        description: description,
      );
    });
  }
} 