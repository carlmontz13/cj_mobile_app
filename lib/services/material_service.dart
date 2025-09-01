import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/material_model.dart';

class MaterialService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<int> createMaterial(MaterialModel material) async {
    try {
      final response = await _supabase
          .from('materials')
          .insert({
            'class_id': material.classId,
            'title': material.title,
            'language_code': material.languageCode,
            'simplified_content': material.simplifiedContent,
            'standard_content': material.standardContent,
            'advanced_content': material.advancedContent,
            'selected_content_type': material.selectedContentType,
            'selected_content': material.selectedContent,
            'created_by': material.createdBy,
            'is_active': material.isActive,
          })
          .select()
          .single();

      return response['id'] as int;
    } catch (e) {
      throw Exception('Failed to create material: $e');
    }
  }

  Future<List<MaterialModel>> getMaterialsByClass(String classId) async {
    try {
      final response = await _supabase
          .from('materials')
          .select()
          .eq('class_id', classId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response.map((data) => MaterialModel.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to get materials: $e');
    }
  }

  Future<MaterialModel?> getMaterialById(int id) async {
    try {
      final response = await _supabase
          .from('materials')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        return MaterialModel.fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get material: $e');
    }
  }

  Future<int> updateMaterial(MaterialModel material) async {
    try {
      if (material.id == null) {
        throw Exception('Cannot update material without an ID');
      }
      
      final response = await _supabase
          .from('materials')
          .update({
            'title': material.title,
            'language_code': material.languageCode,
            'simplified_content': material.simplifiedContent,
            'standard_content': material.standardContent,
            'advanced_content': material.advancedContent,
            'selected_content_type': material.selectedContentType,
            'selected_content': material.selectedContent,
            'is_active': material.isActive,
          })
          .eq('id', material.id!)
          .select()
          .single();

      return response['id'] as int;
    } catch (e) {
      throw Exception('Failed to update material: $e');
    }
  }

  Future<int> deleteMaterial(int id) async {
    try {
      // Soft delete by setting is_active to false
      final response = await _supabase
          .from('materials')
          .update({'is_active': false})
          .eq('id', id)
          .select()
          .single();

      return response['id'] as int;
    } catch (e) {
      throw Exception('Failed to delete material: $e');
    }
  }

  Future<List<MaterialModel>> searchMaterials(String classId, String query) async {
    try {
      final response = await _supabase
          .from('materials')
          .select()
          .eq('class_id', classId)
          .eq('is_active', true)
          .or('title.ilike.%$query%,selected_content.ilike.%$query%')
          .order('created_at', ascending: false);

      return response.map((data) => MaterialModel.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to search materials: $e');
    }
  }
}
