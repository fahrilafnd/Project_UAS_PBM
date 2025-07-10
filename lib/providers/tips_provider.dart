// lib/providers/tips_provider.dart
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class TipsProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _tips = [];
  final List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  
  static const String baseUrl = 'http://192.168.43.143:5042/api/Tips';
  static const String authUrl = 'http://192.168.43.143:5042/api/Auth';

  // === CONSISTENT TOKEN KEYS ===
  static const String _tokenKey = 'token'; // Konsisten dengan AuthProvider
  static const String _accessTokenKey = 'access_token'; // Untuk access token API
  static const String _refreshTokenKey = 'refresh_token'; // Untuk refresh token API

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get tips => _tips;
  List<Map<String, dynamic>> get searchResults => _searchResults;

  // Token validation method dengan JWT decoder yang konsisten
  bool isTokenValid(String? token) {
    if (token == null || token.isEmpty) {
      print('❌ Token is null or empty');
      return false;
    }

    try {
      // Gunakan JWT decoder yang sama dengan AuthProvider
      final isExpired = JwtDecoder.isExpired(token);
      final expiryDate = JwtDecoder.getExpirationDate(token);
      final now = DateTime.now();
      
      print('=== TOKEN VALIDATION ===');
      print('Token expiry date: $expiryDate');
      print('Current date: $now');
      print('Time until expiry: ${expiryDate.difference(now).inMinutes} minutes');
      print('Is expired: $isExpired');
      print('Is valid: ${!isExpired}');
      
      return !isExpired;
    } catch (e) {
      print('❌ Error validating token: $e');
      return false;
    }
  }

  // Auto refresh token method
  Future<String?> refreshToken() async {
    try {
      print('=== REFRESHING TOKEN ===');
      
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);
      
      if (refreshToken == null) {
        print('❌ No refresh token available');
        return null;
      }

      final response = await http.post(
        Uri.parse('$authUrl/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refresh_token': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final newToken = data['access_token'];
          final newRefreshToken = data['refresh_token'];
          
          // Save new tokens dengan key yang konsisten
          await prefs.setString(_tokenKey, newToken); // Main token untuk AuthProvider
          await prefs.setString(_accessTokenKey, newToken); // Access token untuk API calls
          if (newRefreshToken != null) {
            await prefs.setString(_refreshTokenKey, newRefreshToken);
          }
          
          print('✅ Token refreshed successfully');
          return newToken;
        }
      }
      
      print('❌ Failed to refresh token: ${response.body}');
      return null;
    } catch (e) {
      print('❌ Error refreshing token: $e');
      return null;
    }
  }

  // Get valid token (with auto refresh) - prioritas main token dulu
  Future<String?> getValidToken() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Coba ambil main token dulu (yang digunakan AuthProvider)
    String? token = prefs.getString(_tokenKey);
    
    // Jika tidak ada main token, coba access token
    token ??= prefs.getString(_accessTokenKey);
    
    if (token == null) {
      print('❌ No token found');
      return null;
    }

    // Check if token is valid
    if (isTokenValid(token)) {
      return token;
    }

    // Try to refresh token
    print('🔄 Token expired, attempting to refresh...');
    final newToken = await refreshToken();
    
    if (newToken != null && isTokenValid(newToken)) {
      return newToken;
    }

    // If refresh failed, clear tokens and require re-login
    await clearTokens();
    print('❌ Token refresh failed, user needs to re-login');
    return null;
  }

  // Clear all tokens - konsisten dengan AuthProvider
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    
    // Clear additional auth data jika ada
    await prefs.remove('user_info');
    await prefs.remove('user_data');
    await prefs.remove('user_profile');
  }

  // Token validation with auto-refresh wrapper
  Future<bool> ensureValidToken() async {
    final token = await getValidToken();
    if (token == null) {
      _error = 'Sesi Anda telah berakhir. Silakan login ulang.';
      notifyListeners();
      return false;
    }
    return true;
  }

  // Enhanced getUserIdFromToken menggunakan JWT decoder
  int? getUserIdFromToken(String token) {
    try {
      final decodedToken = JwtDecoder.decode(token);
      
      print('=== GET USER ID FROM TOKEN ===');
      print('Available fields in token:');
      decodedToken.forEach((key, value) {
        print('  $key: $value (${value.runtimeType})');
      });
      
      // Try different possible field names for user ID - konsisten dengan AuthProvider
      final possibleIdFields = [
        'Id_Users', 
        'sub', 
        'nameid',
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
        'userId',
      ];

      for (final field in possibleIdFields) {
        final value = decodedToken[field];
        if (value != null) {
          int? userId;
          if (value is int) {
            userId = value;
          } else if (value is String) {
            userId = int.tryParse(value);
          }
          
          if (userId != null) {
            print('Found $field: $value -> parsed as: $userId');
            return userId;
          }
        }
      }
      
      print('❌ No user ID field found in token');
      return null;
    } catch (e) {
      print('❌ Error getting user ID from token: $e');
      return null;
    }
  }

  // Enhanced canUserUpdateTip dengan debugging yang lebih baik
  Future<bool> canUserUpdateTip(int idTips) async {
    print('=== CAN USER UPDATE TIP ===');
    
    final token = await getValidToken();
    if (token == null) {
      print('❌ No valid token');
      return false;
    }
    
    final userIdFromToken = getUserIdFromToken(token);
    if (userIdFromToken == null) {
      print('❌ Cannot extract user ID from token');
      return false;
    }
    
    final tip = getTipById(idTips);
    if (tip == null) {
      print('❌ Tip not found with ID: $idTips');
      print('Available tips:');
      for (var t in _tips) {
        print('  ID: ${t['id_tips']}, Owner: ${t['id_users']}');
      }
      return false;
    }
    
    final tipOwnerId = tip['id_users'];
    
    print('=== OWNERSHIP COMPARISON ===');
    print('User ID from token: $userIdFromToken (${userIdFromToken.runtimeType})');
    print('Tip owner ID: $tipOwnerId (${tipOwnerId.runtimeType})');
    
    // Try multiple comparison methods
    bool canUpdate = false;
    
    // Method 1: Direct comparison
    if (userIdFromToken == tipOwnerId) {
      canUpdate = true;
      print('✅ Match via direct comparison');
    }
    
    // Method 2: String comparison
    if (userIdFromToken.toString() == tipOwnerId.toString()) {
      canUpdate = true;
      print('✅ Match via string comparison');
    }
    
    // Method 3: Int conversion comparison
    final userIdInt = int.tryParse(userIdFromToken.toString());
    final tipOwnerIdInt = int.tryParse(tipOwnerId.toString());
    if (userIdInt != null && tipOwnerIdInt != null && userIdInt == tipOwnerIdInt) {
      canUpdate = true;
      print('✅ Match via int conversion comparison');
    }
    
    if (!canUpdate) {
      print('❌ No ownership match found');
      print('  userIdFromToken == tipOwnerId: ${userIdFromToken == tipOwnerId}');
      print('  userIdFromToken.toString() == tipOwnerId.toString(): ${userIdFromToken.toString() == tipOwnerId.toString()}');
      print('  Types: ${userIdFromToken.runtimeType} vs ${tipOwnerId.runtimeType}');
    }
    
    print('Final result: $canUpdate');
    return canUpdate;
  }

  // Method untuk sinkronisasi dengan AuthProvider
  Future<void> syncWithAuthProvider(String? authToken) async {
    if (authToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, authToken);
      await prefs.setString(_accessTokenKey, authToken);
      print('✅ Token synced with AuthProvider');
    }
  }

  // Method untuk mendapatkan token dari AuthProvider jika tidak ada
  Future<String?> getTokenFromAuthProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Fetch all tips
  Future<void> fetchAllTips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== FETCH ALL TIPS DEBUG ===');
      print('URL: $baseUrl');

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed Data: $data');
        
        if (data is Map<String, dynamic> && data['success'] == true) {
          final List<dynamic> tipsData = data['data'] ?? [];
          _tips.clear();
          _tips.addAll(tipsData.cast<Map<String, dynamic>>());
          _error = null;
          print('✅ Tips loaded successfully: ${_tips.length} items');
        } else {
          _error = 'Format response tidak valid';
          print('❌ Invalid response format');
        }
      } else {
        _error = 'Gagal mengambil data tips: ${response.body}';
        print('❌ Error fetching tips: $_error');
      }
    } catch (e) {
      _error = 'Kesalahan saat mengambil tips: $e';
      print('❌ Exception fetching tips: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add new tip dengan token handling yang konsisten
  Future<bool> addTip({
    required String judul,
    required String deskripsi,
    String? gambar,
    required DateTime tanggalTips,
    required int idUsers,
  }) async {
    // Ensure we have a valid token
    if (!await ensureValidToken()) {
      return false;
    }

    final token = await getValidToken();
    if (token == null) {
      _error = 'Token tidak valid, silakan login ulang';
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== ADD TIP DEBUG ===');
      print('Judul: $judul');
      print('Deskripsi: $deskripsi');
      print('Gambar: $gambar');
      print('Tanggal: $tanggalTips');
      print('ID Users: $idUsers');

      final requestBody = {
        'Judul': judul,
        'Deskripsi': deskripsi,
        'Gambar': gambar ?? '',
        'Tanggal_Tips': tanggalTips.toIso8601String(),
        'Id_Users': idUsers,
      };

      print('Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Add Response status: ${response.statusCode}');
      print('Add Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('✅ Tip added successfully with ID: ${result['id_tips']}');
          
          // Refresh data setelah berhasil menambah
          await fetchAllTips();
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          throw Exception(result['message'] ?? 'Gagal menambahkan tip');
        }
      } else if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        final newToken = await getValidToken();
        if (newToken != null) {
          // Retry with new token
          return await addTip(
            judul: judul,
            deskripsi: deskripsi,
            gambar: gambar,
            tanggalTips: tanggalTips,
            idUsers: idUsers,
          );
        } else {
          throw Exception('Sesi telah berakhir, silakan login ulang');
        }
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body);
        final message = errorData['message'] ?? 'Access denied';
        throw Exception('Akses ditolak: $message');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal menambahkan tip');
      }

    } catch (e) {
      _error = 'Gagal menambahkan tip: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Error adding tip: $e');
      return false;
    }
  }

  // Update existing tip dengan token handling yang konsisten
  Future<bool> updateTip({
    required int idTips,
    required String judul,
    required String deskripsi,
    String? gambar,
    required DateTime tanggalTips,
    required int idUsers
  }) async {
    print('=== UPDATE TIP START ===');
    print('Starting update process for tip ID: $idTips');
    
    // Ensure we have a valid token
    if (!await ensureValidToken()) {
      return false;
    }

    final token = await getValidToken();
    if (token == null) {
      _error = 'Token tidak valid, silakan login ulang';
      return false;
    }

    // === ENHANCED TOKEN DEBUGGING ===
    print('=== TOKEN DEBUGGING ===');
    print('Token length: ${token.length}');
    print('Token starts with: ${token.substring(0, math.min(20, token.length))}...');
    
    // Decode dan print token details menggunakan JWT decoder
    try {
      final decodedToken = JwtDecoder.decode(token);
      print('Decoded Token Payload:');
      decodedToken.forEach((key, value) {
        print('  $key: $value');
      });
      
      final expiryDate = JwtDecoder.getExpirationDate(token);
      print('Token expiry: $expiryDate');
    } catch (e) {
      print('❌ Error decoding token: $e');
    }

    // Ensure we have the latest data
    if (_tips.isEmpty) {
      print('🔄 Tips data is empty, fetching...');
      await fetchAllTips();
    }

    // Check ownership before proceeding
    if (!await canUserUpdateTip(idTips)) {
      _error = 'Anda hanya bisa mengupdate tip yang Anda buat sendiri';
      print('❌ Ownership validation failed');
      _isLoading = false;
      notifyListeners();
      return false;
    }
    print('✅ Ownership validation passed');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== UPDATE TIP REQUEST ===');
      print('ID Tips: $idTips');
      print('Judul: $judul');
      print('Deskripsi: $deskripsi');
      print('Gambar: $gambar');
      print('Tanggal: $tanggalTips');

      final requestBody = {
        'Judul': judul,
        'Deskripsi': deskripsi,
        'Gambar': gambar ?? '',
        'Tanggal_Tips': tanggalTips.toIso8601String(),
        'Id_Users': idUsers,
      };

      print('Update Request Body: ${jsonEncode(requestBody)}');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      
      print('=== REQUEST HEADERS ===');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          print('  $key: Bearer ${value.substring(7, math.min(27, value.length))}...');
        } else {
          print('  $key: $value');
        }
      });
      
      print('Full URL: $baseUrl/$idTips');
      print('Method: PUT');

      final response = await http.put(
        Uri.parse('$baseUrl/$idTips'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('=== RESPONSE DETAILS ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers:');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('✅ Tip updated successfully');
          
          // Refresh data setelah berhasil mengupdate
          await fetchAllTips();
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          throw Exception(result['message'] ?? 'Gagal mengupdate tip');
        }
      } else if (response.statusCode == 401) {
        print('❌ 401 Unauthorized - Token might be invalid');
        
        // Check if token is still valid
        final isValid = isTokenValid(token);
        print('Token validation result: $isValid');
        
        // Try to refresh token
        final newToken = await getValidToken();
        if (newToken != null && newToken != token) {
          print('🔄 Got new token, retrying...');
          // Retry with new token
          return await updateTip(
            idTips: idTips,
            judul: judul,
            deskripsi: deskripsi,
            gambar: gambar,
            tanggalTips: tanggalTips,
            idUsers: idUsers
          );
        } else {
          throw Exception('Sesi telah berakhir, silakan login ulang');
        }
      } else if (response.statusCode == 403) {
        print('❌ 403 Forbidden - Access denied');
        
        try {
          final errorData = jsonDecode(response.body);
          final message = errorData['message'] ?? 'Access denied';
          print('Backend error message: $message');
          
          throw Exception('Akses ditolak: $message. Periksa apakah Anda memiliki hak akses untuk mengupdate tip ini.');
        } catch (e) {
          print('Error parsing 403 response: $e');
          throw Exception('Akses ditolak. Periksa apakah Anda memiliki hak akses untuk mengupdate tip ini.');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Tip tidak ditemukan');
      } else {
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Gagal mengupdate tip (Status: ${response.statusCode})');
        } catch (e) {
          throw Exception('Gagal mengupdate tip (Status: ${response.statusCode}): ${response.body}');
        }
      }

    } catch (e) {
      _error = 'Gagal mengupdate tip: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Error updating tip: $e');
      return false;
    }
  }

  // Delete tip dengan token handling yang konsisten
  Future<bool> deleteTip({
    required int idTips,
  }) async {
    // Ensure we have a valid token
    if (!await ensureValidToken()) {
      return false;
    }

    final token = await getValidToken();
    if (token == null) {
      _error = 'Token tidak valid, silakan login ulang';
      return false;
    }

    // Check ownership before proceeding
    if (!await canUserUpdateTip(idTips)) {
      _error = 'Anda hanya bisa menghapus tip yang Anda buat sendiri';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== DELETE TIP DEBUG ===');
      print('ID Tips: $idTips');

      final response = await http.delete(
        Uri.parse('$baseUrl/$idTips'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Delete Response status: ${response.statusCode}');
      print('Delete Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('✅ Tip deleted successfully');
          
          // Refresh data setelah berhasil menghapus
          await fetchAllTips();
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          throw Exception(result['message'] ?? 'Gagal menghapus tip');
        }
      } else if (response.statusCode == 401) {
        // Token might be expired, try to refresh
        final newToken = await getValidToken();
        if (newToken != null) {
          // Retry with new token
          return await deleteTip(idTips: idTips);
        } else {
          throw Exception('Sesi telah berakhir, silakan login ulang');
        }
      } else if (response.statusCode == 403) {
        final errorData = jsonDecode(response.body);
        final message = errorData['message'] ?? 'Access denied';
        throw Exception('Akses ditolak: $message. Anda hanya bisa menghapus tip milik Anda sendiri.');
      } else if (response.statusCode == 404) {
        throw Exception('Tip tidak ditemukan');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal menghapus tip');
      }

    } catch (e) {
      _error = 'Gagal menghapus tip: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Error deleting tip: $e');
      return false;
    }
  }

  // Search tips
  Future<void> searchTips(String keyword) async {
    if (keyword.trim().isEmpty) {
      _searchResults.clear();
      _error = 'Keyword pencarian tidak boleh kosong';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== SEARCH TIPS DEBUG ===');
      print('Keyword: $keyword');
      print('URL: $baseUrl/search/${Uri.encodeComponent(keyword)}');

      final response = await http.get(
        Uri.parse('$baseUrl/search/${Uri.encodeComponent(keyword)}'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Search Response status: ${response.statusCode}');
      print('Search Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data is Map<String, dynamic> && data['success'] == true) {
          final List<dynamic> searchData = data['data'] ?? [];
          _searchResults.clear();
          _searchResults.addAll(searchData.cast<Map<String, dynamic>>());
          _error = null;
          print('✅ Search completed: ${_searchResults.length} results found');
        } else {
          _error = 'Format response pencarian tidak valid';
          print('❌ Invalid search response format');
        }
      } else {
        _error = 'Gagal mencari tips: ${response.body}';
        print('❌ Error searching tips: $_error');
      }
    } catch (e) {
      _error = 'Kesalahan saat mencari tips: $e';
      print('❌ Exception searching tips: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Helper methods
  Map<String, dynamic>? getTipById(int idTips) {
    try {
      return _tips.firstWhere((tip) => tip['id_tips'] == idTips);
    } catch (e) {
      return null;
    }
  }

  bool hasTip(int idTips) {
    return _tips.any((tip) => tip['id_tips'] == idTips);
  }

  List<Map<String, dynamic>> getTipsByUser(int idUsers) {
    return _tips.where((tip) => tip['id_users'] == idUsers).toList();
  }

  List<Map<String, dynamic>> getRecentTips([int limit = 5]) {
    final sortedTips = List<Map<String, dynamic>>.from(_tips);
    sortedTips.sort((a, b) {
      final dateA = DateTime.tryParse(a['tanggal_tips']?.toString() ?? '') ?? DateTime(1970);
      final dateB = DateTime.tryParse(b['tanggal_tips']?.toString() ?? '') ?? DateTime(1970);
      return dateB.compareTo(dateA);
    });
    
    return sortedTips.take(limit).toList();
  }

  void clearSearchResults() {
    _searchResults.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await fetchAllTips();
  }

  bool get isEmpty => _tips.isEmpty;
  int get totalTips => _tips.length;

  // Check if user is logged in with valid token - konsisten dengan AuthProvider
  Future<bool> isLoggedIn() async {
    final token = await getValidToken();
    return token != null;
  }

  // Get current user ID - konsisten dengan AuthProvider
  Future<int?> getCurrentUserId() async {
    final token = await getValidToken();
    if (token == null) return null;
    return getUserIdFromToken(token);
  }

  // Method untuk memastikan sinkronisasi dengan AuthProvider
  Future<void> ensureSyncWithAuthProvider() async {
    final authToken = await getTokenFromAuthProvider();
    if (authToken != null) {
      await syncWithAuthProvider(authToken);
    }
  }

  // Validation dan formatting methods tetap sama
  Map<String, String?> validateTipData({
    required String judul,
    required String deskripsi,
    required DateTime tanggalTips,
    required int idUsers,
  }) {
    final errors = <String, String?>{};

    if (judul.trim().isEmpty) {
      errors['judul'] = 'Judul tips tidak boleh kosong';
    } else if (judul.length > 84) {
      errors['judul'] = 'Judul tips tidak boleh lebih dari 84 karakter';
    }

    if (deskripsi.trim().isEmpty) {
      errors['deskripsi'] = 'Deskripsi tips tidak boleh kosong';
    }

    if (idUsers <= 0) {
      errors['id_users'] = 'ID User harus berupa angka positif';
    }

    if (tanggalTips.isAfter(DateTime.now().add(const Duration(days: 365)))) {
      errors['tanggal_tips'] = 'Tanggal tips tidak valid';
    }

    return errors;
  }

  String formatTanggal(String? tanggalString) {
    if (tanggalString == null) return '-';
    
    try {
      final date = DateTime.parse(tanggalString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return tanggalString;
    }
  }

  String formatTanggalWaktu(String? tanggalString) {
    if (tanggalString == null) return '-';
    
    try {
      final date = DateTime.parse(tanggalString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return tanggalString;
    }
  }
}