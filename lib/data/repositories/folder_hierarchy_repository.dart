import 'package:supabase_flutter/supabase_flutter.dart';

class FolderHierarchyRepository {
  static const String _tableName = 'folder_hierarchy';

  Future<bool> addSubfolder(String parentId, String childId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase.from(_tableName).insert({
        'parent_id': parentId,
        'child_id': childId,
      });
      return true;
    } catch (e) {
      throw Exception('Nepodařilo se přidat podsložku: $e');
    }
  }

  Future<bool> removeSubfolder(String parentId, String childId) async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from(_tableName)
          .delete()
          .eq('parent_id', parentId)
          .eq('child_id', childId);
      return true;
    } catch (e) {
      throw Exception('Nepodařilo se odebrat podsložku: $e');
    }
  }
} 