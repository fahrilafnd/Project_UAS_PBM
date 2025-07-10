// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _userInfo;
  bool _isLoading = false;

  String? get token => _token;
  Map<String, dynamic>? get userInfo => _userInfo;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && !JwtDecoder.isExpired(_token!);

  // Inisialisasi provider saat app startup
  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      
      if (_token != null && !JwtDecoder.isExpired(_token!)) {
        _userInfo = JwtDecoder.decode(_token!);
      } else {
        await logout(); // Clear invalid token
      }
    } catch (e) {
      await logout();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // Login method
  Future<bool> login(String token) async {
    try {
      if (JwtDecoder.isExpired(token)) {
        return false;
      }

      _token = token;
      _userInfo = JwtDecoder.decode(token);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);

      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Enhanced logout method with expired token cleanup
  Future<void> logout({bool clearExpiredTokens = true}) async {
    _token = null;
    _userInfo = null;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Hapus token utama
    await prefs.remove('token');
    
    // Opsional: bersihkan semua token yang sudah expired jika ada
    if (clearExpiredTokens) {
      await _clearExpiredTokens(prefs);
    }
    
    // Bersihkan data auth lainnya jika ada
    await _clearAdditionalAuthData(prefs);
    
    notifyListeners();
  }

  // Method untuk membersihkan token yang sudah expired
  Future<void> _clearExpiredTokens(SharedPreferences prefs) async {
    try {
      // Daftar key yang mungkin menyimpan token
      final tokenKeys = [
        'token',
        'access_token',
        'refresh_token',
        'auth_token',
        'jwt_token',
        'bearer_token',
      ];

      for (final key in tokenKeys) {
        final storedToken = prefs.getString(key);
        if (storedToken != null) {
          try {
            // Cek apakah token expired
            if (JwtDecoder.isExpired(storedToken)) {
              await prefs.remove(key);
              debugPrint('Removed expired token: $key');
            }
          } catch (e) {
            // Jika token tidak valid, hapus juga
            await prefs.remove(key);
            debugPrint('Removed invalid token: $key');
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing expired tokens: $e');
    }
  }

  // Method untuk membersihkan data auth tambahan
  Future<void> _clearAdditionalAuthData(SharedPreferences prefs) async {
    try {
      // Daftar key data auth lainnya yang perlu dibersihkan
      final authDataKeys = [
        'user_info',
        'user_data',
        'user_profile',
        'login_time',
        'last_activity',
        'session_id',
        'device_id',
      ];

      for (final key in authDataKeys) {
        if (prefs.containsKey(key)) {
          await prefs.remove(key);
          debugPrint('Removed auth data: $key');
        }
      }
    } catch (e) {
      debugPrint('Error clearing additional auth data: $e');
    }
  }

  // Method untuk forced logout dengan pembersihan menyeluruh
  Future<void> forceLogout() async {
    debugPrint('Performing force logout with complete cleanup');
    
    _token = null;
    _userInfo = null;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Hapus semua data yang terkait dengan authentication
    await prefs.clear(); // Hati-hati: ini akan menghapus SEMUA data SharedPreferences
    
    // Atau gunakan pembersihan selektif:
    // await _clearExpiredTokens(prefs);
    // await _clearAdditionalAuthData(prefs);
    
    notifyListeners();
  }

  // Method untuk cek dan bersihkan token expired secara berkala
  Future<void> cleanupExpiredTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearExpiredTokens(prefs);
      
      // Jika token saat ini juga expired, lakukan logout
      if (_token != null && JwtDecoder.isExpired(_token!)) {
        await logout();
      }
    } catch (e) {
      debugPrint('Error during token cleanup: $e');
    }
  }

  // Get user ID dari token
  int? getUserId() {
    if (_userInfo == null) return null;

    final possibleIdFields = [
      'Id_Users', 
      'sub', 
      'nameid',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
      'userId',
    ];

    for (final field in possibleIdFields) {
      final value = _userInfo![field];
      if (value != null) {
        if (value is int) return value;
        if (value is String) return int.tryParse(value);
      }
    }

    return null;
  }

  // Check apakah token akan expire dalam 5 menit
  bool willExpireSoon() {
    if (_token == null) return true;
    
    final expiryDate = JwtDecoder.getExpirationDate(_token!);
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inMinutes;
    
    return difference <= 5;
  }

  // Method untuk auto-cleanup yang bisa dipanggil secara berkala
  Future<void> performMaintenanceCleanup() async {
    try {
      // Cek token saat ini
      if (_token != null && JwtDecoder.isExpired(_token!)) {
        debugPrint('Current token expired, performing logout');
        await logout();
        return;
      }

      // Bersihkan token expired lainnya
      await cleanupExpiredTokens();
      
      debugPrint('Maintenance cleanup completed');
    } catch (e) {
      debugPrint('Error during maintenance cleanup: $e');
    }
  }
}