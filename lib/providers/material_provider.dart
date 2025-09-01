import 'package:flutter/foundation.dart';
import '../models/material_model.dart';
import '../services/material_service.dart';

class MaterialProvider with ChangeNotifier {
  final MaterialService _materialService = MaterialService();
  List<MaterialModel> _materials = [];
  bool _isLoading = false;
  String? _error;

  List<MaterialModel> get materials => _materials;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMaterials(String classId) async {
    setLoading(true);
    _clearError();

    try {
      final materials = await _materialService.getMaterialsByClass(classId);
      _materials = materials;
    } catch (e) {
      _error = e.toString();
    } finally {
      setLoading(false);
    }
  }

  Future<bool> deleteMaterial(int materialId) async {
    try {
      await _materialService.deleteMaterial(materialId);
      // Remove from local list
      _materials.removeWhere((material) => material.id == materialId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearMaterials() {
    _materials = [];
    notifyListeners();
  }
}
