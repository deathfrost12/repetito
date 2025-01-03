import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/folder_entity.dart';
import '../../../data/repositories/folder_hierarchy_repository.dart';

part 'subfolder_list_provider.g.dart';

@riverpod
class SubfolderList extends _$SubfolderList {
  static const String _tableName = 'folder_hierarchy';

  @override
  Future<List<FolderEntity>> build(String parentId) async {
    final supabase = Supabase.instance.client;
    
    // Získáme ID všech podsložek
    final response = await supabase
        .from(_tableName)
        .select('child_id')
        .eq('parent_id', parentId);
    
    final childIds = response
        .map<String>((record) => record['child_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (childIds.isEmpty) {
      return [];
    }

    // Načteme data všech podsložek
    final foldersResponse = await supabase
        .from('folders')
        .select()
        .filter('id', 'in', childIds);

    return foldersResponse.map((json) {
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

  Future<void> removeSubfolder(String childId) async {
    final repository = FolderHierarchyRepository();
    await repository.removeSubfolder(parentId, childId);
    ref.invalidateSelf();
  }
} 