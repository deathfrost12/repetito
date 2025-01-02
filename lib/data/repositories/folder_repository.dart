import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:repetito/domain/entities/folder_entity.dart';

part 'folder_repository.g.dart';

@riverpod
class FolderRepository extends _$FolderRepository {
  static const String _tableName = 'folders';
  static const String _folderDecksTable = 'folder_decks';

  @override
  FutureOr<void> build() {}

  Future<List<FolderEntity>> getFolders() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from(_tableName)
        .select()
        .eq('user_id', supabase.auth.currentUser!.id);

    return response.map((json) {
      final now = DateTime.now();
      final data = {
        'id': json['id']?.toString() ?? '',
        'user_id': json['user_id']?.toString() ?? supabase.auth.currentUser!.id,
        'name': json['name']?.toString() ?? '',
        'color': json['color']?.toString() ?? 'blue',
        'icon': json['icon']?.toString() ?? 'folder',
        'description': json['description']?.toString(),
        'created_at': json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : now,
        'updated_at': json['updated_at'] != null
            ? DateTime.parse(json['updated_at'].toString())
            : now,
      };
      return FolderEntity.fromJson(data);
    }).toList();
  }

  Future<FolderEntity> createFolder({
    required String name,
    required String color,
    required String icon,
    String? description,
  }) async {
    final supabase = Supabase.instance.client;
    final now = DateTime.now();
    final response = await supabase.from(_tableName).insert({
      'name': name,
      'color': color,
      'icon': icon,
      'description': description,
      'user_id': supabase.auth.currentUser!.id,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    }).select().single();

    final data = {
      'id': response['id']?.toString() ?? '',
      'user_id': response['user_id']?.toString() ?? supabase.auth.currentUser!.id,
      'name': response['name']?.toString() ?? name,
      'color': response['color']?.toString() ?? color,
      'icon': response['icon']?.toString() ?? icon,
      'description': response['description']?.toString(),
      'created_at': response['created_at'] != null
          ? DateTime.parse(response['created_at'].toString())
          : now,
      'updated_at': response['updated_at'] != null
          ? DateTime.parse(response['updated_at'].toString())
          : now,
    };
    return FolderEntity.fromJson(data);
  }

  Future<FolderEntity> updateFolder({
    required String id,
    String? name,
    String? color,
    String? icon,
    String? description,
  }) async {
    final supabase = Supabase.instance.client;
    final now = DateTime.now();
    final Map<String, dynamic> updates = {
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (icon != null) 'icon': icon,
      if (description != null) 'description': description,
      'updated_at': now.toIso8601String(),
    };

    final response = await supabase
        .from(_tableName)
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    final data = {
      'id': response['id']?.toString() ?? id,
      'user_id': response['user_id']?.toString() ?? supabase.auth.currentUser!.id,
      'name': response['name']?.toString() ?? name ?? '',
      'color': response['color']?.toString() ?? color ?? 'blue',
      'icon': response['icon']?.toString() ?? icon ?? 'folder',
      'description': response['description']?.toString(),
      'created_at': response['created_at'] != null
          ? DateTime.parse(response['created_at'].toString())
          : now,
      'updated_at': response['updated_at'] != null
          ? DateTime.parse(response['updated_at'].toString())
          : now,
    };
    return FolderEntity.fromJson(data);
  }

  Future<void> deleteFolder(String id) async {
    final supabase = Supabase.instance.client;
    try {
      // Nejdřív smažeme všechny vazby na balíčky
      await supabase
          .from(_folderDecksTable)
          .delete()
          .eq('folder_id', id);
      
      // Pak smažeme samotnou složku
      await supabase
          .from(_tableName)
          .delete()
          .eq('id', id)
          .eq('user_id', supabase.auth.currentUser!.id);
    } catch (e) {
      throw Exception('Nepodařilo se smazat složku: $e');
    }
  }

  Future<void> addDeckToFolder({
    required String folderId,
    required String deckId,
  }) async {
    final supabase = Supabase.instance.client;
    await supabase.from(_folderDecksTable).insert({
      'folder_id': folderId,
      'deck_id': deckId,
    });
  }

  Future<void> removeDeckFromFolder({
    required String folderId,
    required String deckId,
  }) async {
    final supabase = Supabase.instance.client;
    await supabase
        .from(_folderDecksTable)
        .delete()
        .eq('folder_id', folderId)
        .eq('deck_id', deckId);
  }

  Future<List<String>> getFolderDeckIds(String folderId) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from(_folderDecksTable)
        .select('deck_id')
        .eq('folder_id', folderId);
    return response.map<String>((record) => record['deck_id']?.toString() ?? '').toList();
  }
} 