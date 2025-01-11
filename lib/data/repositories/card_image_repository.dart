import 'dart:io';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

final cardImageRepositoryProvider = Provider<CardImageRepository>((ref) {
  return CardImageRepository(Supabase.instance.client);
});

class CardImageRepository {
  final SupabaseClient _supabase;

  CardImageRepository(this._supabase);

  Future<void> uploadTempImage(String storagePath, File imageFile) async {
    await _supabase.storage.from('card_images').upload(
      storagePath,
      imageFile,
    );
  }

  String getTempImageUrl(String storagePath) {
    return _supabase.storage.from('card_images').getPublicUrl(storagePath);
  }

  Future<String> moveTempImageToFinal(String tempPath, String cardId, String imageType) async {
    try {
      final storage = _supabase.storage;
      final fileExt = tempPath.split('.').last;
      final finalPath = 'cards/$cardId/${imageType}_${const Uuid().v4()}.$fileExt';
      
      // Přesuneme soubor z temp do finální složky
      await storage.from('card_images').copy(
        tempPath,
        finalPath,
      );
      
      // Získáme URL finálního obrázku
      final finalUrl = storage.from('card_images').getPublicUrl(finalPath);
      
      try {
        // Smažeme původní soubor
        await storage.from('card_images').remove([tempPath]);
      } catch (e) {
        print('Warning: Could not delete temp file: $e');
        // Pokračujeme i když se nepodaří smazat temp soubor
      }
      
      return finalUrl;
    } catch (e) {
      print('Error moving image to final location: $e');
      // Pokud se nepodaří přesunout, vrátíme původní URL
      return _supabase.storage.from('card_images').getPublicUrl(tempPath);
    }
  }

  Future<void> deleteTempImage(String storagePath) async {
    await _supabase.storage.from('card_images').remove([storagePath]);
  }

  Future<List<Map<String, dynamic>>> getImagesForCard(String cardId) async {
    try {
      final response = await _supabase
          .from('card_images')
          .select()
          .eq('card_id', cardId);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Nepodařilo se načíst obrázky: $e');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      // Získáme cestu k souboru z URL
      final uri = Uri.parse(imageUrl);
      final storagePath = uri.pathSegments.last;
      
      // Smažeme soubor ze Storage
      await _supabase.storage.from('card_images').remove([storagePath]);
      
      // Smažeme záznam z databáze
      await _supabase
          .from('card_images')
          .delete()
          .eq('image_url', imageUrl);
    } catch (e) {
      throw Exception('Nepodařilo se smazat obrázek: $e');
    }
  }
} 