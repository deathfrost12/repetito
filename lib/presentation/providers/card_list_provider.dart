import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/card_entity.dart';
import '../../data/repositories/card_repository.dart';

part 'card_list_provider.g.dart';

@riverpod
Stream<List<CardEntity>> cardList(CardListRef ref, String deckId) {
  final repository = ref.watch(cardRepositoryProvider);
  return repository.watchCards(deckId);
}

@riverpod
class CreateCardNotifier extends _$CreateCardNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> createCard({
    required String deckId,
    required String frontContent,
    required String backContent,
  }) async {
    state = const AsyncLoading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(cardRepositoryProvider);
      await repository.createCard(
        deckId: deckId,
        frontContent: frontContent,
        backContent: backContent,
      );
      ref.invalidate(cardListProvider(deckId));
    });
  }
}

@riverpod
class DeleteCardNotifier extends _$DeleteCardNotifier {
  @override
  FutureOr<void> build() {}

  Future<void> deleteCard(String cardId, String deckId) async {
    state = const AsyncLoading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(cardRepositoryProvider);
      await repository.deleteCard(cardId);
      ref.invalidate(cardListProvider(deckId));
    });
  }
}

@riverpod
Future<List<CardEntity>> practiceCards(PracticeCardsRef ref, String deckId) {
  final repository = ref.watch(cardRepositoryProvider);
  return repository.getAllCards(deckId);
} 