import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'folder_hierarchy_provider.g.dart';

@riverpod
class FolderHierarchy extends _$FolderHierarchy {
  static const String _tableName = 'folder_hierarchy';

  @override
  FutureOr<bool> build() async => true;

  Future<bool> addSubfolder(String parentId, String childId) async {
    state = const AsyncLoading();
    
    try {
      final supabase = Supabase.instance.client;
      await supabase.from(_tableName).insert({
        'parent_id': parentId,
        'child_id': childId,
      });

      state = const AsyncData(true);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      throw Exception('Nepodařilo se přidat podsložku: $e');
    }
  }

  Future<bool> removeSubfolder(String parentId, String childId) async {
    state = const AsyncLoading();
    
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from(_tableName)
          .delete()
          .eq('parent_id', parentId)
          .eq('child_id', childId);

      state = const AsyncData(true);
      return true;
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      throw Exception('Nepodařilo se odebrat podsložku: $e');
    }
  }
} 