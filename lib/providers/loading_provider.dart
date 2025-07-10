// lib/providers/loading_provider.dart
import 'package:flutter/material.dart';

class LoadingProvider with ChangeNotifier {
  final Map<String, bool> _loadingStates = {};
  String? _globalMessage;

  // Get loading state untuk key tertentu
  bool isLoading(String key) => _loadingStates[key] ?? false;

  // Get global loading (jika ada yang loading)
  bool get isGlobalLoading => _loadingStates.values.any((loading) => loading);

  // Get global message
  String? get globalMessage => _globalMessage;

  // Set loading state
  void setLoading(String key, bool loading, {String? message}) {
    _loadingStates[key] = loading;
    
    if (loading && message != null) {
      _globalMessage = message;
    } else if (!isGlobalLoading) {
      _globalMessage = null;
    }
    
    notifyListeners();
  }

  // Set loading dengan auto-complete setelah Future selesai
  Future<T> withLoading<T>(
    String key, 
    Future<T> future, {
    String? message,
  }) async {
    setLoading(key, true, message: message);
    try {
      final result = await future;
      setLoading(key, false);
      return result;
    } catch (e) {
      setLoading(key, false);
      rethrow;
    }
  }

  // Clear loading state untuk key tertentu
  void clearLoading(String key) {
    _loadingStates.remove(key);
    if (!isGlobalLoading) {
      _globalMessage = null;
    }
    notifyListeners();
  }

  // Clear semua loading states
  void clearAllLoading() {
    _loadingStates.clear();
    _globalMessage = null;
    notifyListeners();
  }

  // Predefined keys untuk konsistensi
  static const String fetchLahan = 'fetch_lahan';
  static const String addLahan = 'add_lahan';
  static const String deleteLahan = 'delete_lahan';
  static const String fetchLaporan = 'fetch_laporan';
  static const String saveLaporan = 'save_laporan';
  static const String deleteLaporan = 'delete_laporan';
  static const String login = 'login';
  static const String logout = 'logout';
  static const String uploadImage = 'upload_image';
}