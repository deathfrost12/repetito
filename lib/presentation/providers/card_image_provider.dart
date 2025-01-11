import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/card_image_repository.dart';
import 'package:uuid/uuid.dart';

part 'card_image_provider.g.dart';

class TempImage {
  final String tempUrl;
  final String storagePath;
  final String imageType;

  TempImage({
    required this.tempUrl,
    required this.storagePath,
    required this.imageType,
  });
}

typedef CardImages = Map<String, String>;

@riverpod
class CardImageNotifier extends _$CardImageNotifier {
  final _tempImages = <String, List<TempImage>>{};
  final _persistentImages = <String, CardImages>{};
  
  @override
  AsyncValue<Map<String, CardImages>> build() {
    return AsyncValue.data(_persistentImages);
  }

  Future<void> uploadTempImage(String tempCardId, String imageType, File imageFile) async {
    try {
      final repository = ref.read(cardImageRepositoryProvider);
      final uuid = const Uuid();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${uuid.v4()}.$fileExt';
      final storagePath = 'temp/$fileName';
      
      await repository.uploadTempImage(storagePath, imageFile);
      final tempUrl = repository.getTempImageUrl(storagePath);
      
      final tempImage = TempImage(
        tempUrl: tempUrl,
        storagePath: storagePath,
        imageType: imageType,
      );
      
      // Aktualizace temp images
      if (!_tempImages.containsKey(tempCardId)) {
        _tempImages[tempCardId] = [];
      }
      _tempImages[tempCardId]?.removeWhere((img) => img.imageType == imageType);
      _tempImages[tempCardId]?.add(tempImage);
      
      // Aktualizace state a persistent images
      final currentImages = Map<String, CardImages>.from(_persistentImages);
      if (!currentImages.containsKey(tempCardId)) {
        currentImages[tempCardId] = {};
      }
      currentImages[tempCardId]?[imageType] = tempUrl;
      
      _persistentImages.clear();
      _persistentImages.addAll(currentImages);
      
      state = AsyncValue.data(currentImages);
      
      print('Current state after upload: ${state.value}');
      print('Persistent images after upload: $_persistentImages');
    } catch (error, stackTrace) {
      print('Error uploading image: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  String? getImageUrl(String cardId, String imageType) {
    final cardImages = _persistentImages[cardId];
    if (cardImages == null) return null;
    
    final url = cardImages[imageType];
    print('Getting image URL for card $cardId, type $imageType: $url');
    return url;
  }

  Future<void> finalizeTempImages(String tempCardId, String finalCardId) async {
    try {
      final repository = ref.read(cardImageRepositoryProvider);
      final tempImagesForCard = _tempImages[tempCardId] ?? [];
      
      final finalImages = <String, String>{};
      
      for (final tempImage in tempImagesForCard) {
        try {
          final finalUrl = await repository.moveTempImageToFinal(
            tempImage.storagePath,
            finalCardId,
            tempImage.imageType,
          );
          
          finalImages[tempImage.imageType] = finalUrl;
        } catch (e) {
          print('Error moving image to final: $e');
          finalImages[tempImage.imageType] = tempImage.tempUrl;
        }
      }
      
      _tempImages.remove(tempCardId);
      
      if (finalImages.isNotEmpty) {
        final currentImages = Map<String, CardImages>.from(_persistentImages);
        currentImages[finalCardId] = finalImages;
        
        _persistentImages.clear();
        _persistentImages.addAll(currentImages);
        
        state = AsyncValue.data(currentImages);
      }
      
      print('Finalized images for card $finalCardId: $finalImages');
      print('Persistent images after finalization: $_persistentImages');
    } catch (error, stackTrace) {
      print('Error finalizing images: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> cleanupTempImages(String tempCardId) async {
    try {
      final repository = ref.read(cardImageRepositoryProvider);
      final tempImagesForCard = _tempImages[tempCardId] ?? [];
      
      for (final tempImage in tempImagesForCard) {
        await repository.deleteTempImage(tempImage.storagePath);
      }
      
      _tempImages.remove(tempCardId);
      
      final currentImages = Map<String, CardImages>.from(_persistentImages);
      currentImages.remove(tempCardId);
      
      _persistentImages.clear();
      _persistentImages.addAll(currentImages);
      
      state = AsyncValue.data(currentImages);
      
      print('Cleaned up temp images for card $tempCardId');
      print('Persistent images after cleanup: $_persistentImages');
    } catch (error, stackTrace) {
      print('Error cleaning up temp images: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteImage(String cardId, String imageType) async {
    try {
      final currentImages = Map<String, CardImages>.from(_persistentImages);
      final cardImages = currentImages[cardId];
      
      if (cardImages != null) {
        cardImages.remove(imageType);
        if (cardImages.isEmpty) {
          currentImages.remove(cardId);
        }
      }
      
      _persistentImages.clear();
      _persistentImages.addAll(currentImages);
      
      state = AsyncValue.data(currentImages);

      // Smazání temp image pokud existuje
      final tempImagesForCard = _tempImages[cardId] ?? [];
      final tempImage = tempImagesForCard.firstWhere(
        (img) => img.imageType == imageType,
        orElse: () => throw Exception('Obrázek nebyl nalezen'),
      );
      
      final repository = ref.read(cardImageRepositoryProvider);
      await repository.deleteTempImage(tempImage.storagePath);
      
      tempImagesForCard.removeWhere((img) => img.imageType == imageType);
      if (tempImagesForCard.isEmpty) {
        _tempImages.remove(cardId);
      } else {
        _tempImages[cardId] = tempImagesForCard;
      }
      
      print('Deleted image for card $cardId, type $imageType');
      print('Persistent images after deletion: $_persistentImages');
    } catch (error, stackTrace) {
      print('Error deleting image: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }
} 