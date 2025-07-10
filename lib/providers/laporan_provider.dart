// lib/providers/laporan_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LaporanProvider with ChangeNotifier {
  final Map<int, Map<String, dynamic>> _laporanCache = {};
  bool _isLoading = false;
  String? _error;
  
  static const String baseUrl = 'http://192.168.43.143:5042/api/Laporan';

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get laporan dari cache atau fetch dari server
  Map<String, dynamic>? getLaporan(int idLahan) {
    return _laporanCache[idLahan];
  }

  // Fetch laporan by ID lahan - DIPERBAIKI untuk handling data yang ada
  Future<void> fetchLaporan(int idLahan) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/laporan/$idLahan'),
        headers: {'Content-Type': 'application/json'},
      );

      print('=== FETCH LAPORAN DEBUG ===');
      print('URL: $baseUrl/laporan/$idLahan');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Parsed Data: $data');
        print('Data type: ${data.runtimeType}');
        
        // Cek apakah response memiliki struktur yang benar
        if (data is Map<String, dynamic>) {
          // Normalisasi data untuk memastikan konsistensi struktur
          final normalizedData = _normalizeResponseData(data);
          _laporanCache[idLahan] = normalizedData;
          _error = null;
          print('✅ Laporan cached successfully for idLahan $idLahan');
          print('Cache keys: ${normalizedData.keys.toList()}');
          
          // Debug setiap section
          normalizedData.forEach((key, value) {
            print('Section "$key": ${value.runtimeType} - ${value is List ? 'Length: ${(value).length}' : 'Value: $value'}');
          });
        } else {
          print('❌ Invalid data structure: ${data.runtimeType}');
          _error = 'Format data tidak valid';
        }
      } else if (response.statusCode == 404) {
        // Laporan belum ada, buat struktur kosong
        print('📝 No existing laporan found, creating empty structure');
        _laporanCache[idLahan] = _createEmptyLaporanStructure();
        _error = null;
      } else {
        _error = 'Gagal mengambil laporan: ${response.body}';
        print('❌ Error fetching laporan: $_error');
      }
    } catch (e) {
      _error = 'Kesalahan saat mengambil laporan: $e';
      print('❌ Exception fetching laporan: $e');
      // Buat struktur kosong jika terjadi error
      _laporanCache[idLahan] = _createEmptyLaporanStructure();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fungsi untuk normalisasi data response agar konsisten
  Map<String, dynamic> _normalizeResponseData(Map<String, dynamic> data) {
    final normalized = <String, dynamic>{};
    
    // Copy laporan_lahan info jika ada
    if (data.containsKey('laporan_lahan')) {
      normalized['laporan_lahan'] = data['laporan_lahan'];
    }
    
    // Normalisasi setiap section - pastikan semua berupa List
    final sections = [
      'musimTanam', 'inputProduksi', 'pendampingan', 
      'kendala', 'hasilPanen', 'catatan', 'gambar'
    ];
    
    for (final section in sections) {
      if (data.containsKey(section)) {
        final sectionData = data[section];
        
        if (sectionData is List) {
          normalized[section] = List.from(sectionData);
        } else if (sectionData is Map && sectionData.isNotEmpty) {
          // Jika berupa Map, wrap dalam List
          normalized[section] = [Map.from(sectionData)];
        } else {
          normalized[section] = [];
        }
      } else {
        normalized[section] = [];
      }
    }
    
    return normalized;
  }

  // Buat struktur laporan kosong untuk inisialisasi
  Map<String, dynamic> _createEmptyLaporanStructure() {
    return {
      'laporan_lahan': null,
      'musimTanam': [],
      'inputProduksi': [],
      'pendampingan': [],
      'kendala': [],
      'hasilPanen': [],
      'catatan': [],
      'gambar': [],
    };
  }

  // Check apakah laporan kosong - DIPERBAIKI
  bool isLaporanEmpty(int idLahan) {
    final laporan = _laporanCache[idLahan];
    
    print('=== IS LAPORAN EMPTY CHECK ===');
    print('IdLahan: $idLahan');
    print('Laporan data: $laporan');
    
    if (laporan == null) {
      print('❌ Laporan null for idLahan: $idLahan');
      return true;
    }

    // List semua sections yang perlu dicek
    final sectionsToCheck = [
      'musimTanam',
      'hasilPanen', 
      'inputProduksi',
      'pendampingan',
      'kendala',
      'catatan',
      'gambar',
    ];

    print('Checking sections: $sectionsToCheck');

    bool hasData = false;
    for (final section in sectionsToCheck) {
      final sectionData = laporan[section];
      print('Section "$section": $sectionData (Type: ${sectionData.runtimeType})');
      
      if (sectionData is List) {
        print('  - List length: ${sectionData.length}');
        if (sectionData.isNotEmpty) {
          print('  ✅ Found non-empty section: $section with ${sectionData.length} items');
          hasData = true;
        }
      } else if (sectionData is Map && sectionData.isNotEmpty) {
        print('  ✅ Found non-empty map section: $section');
        hasData = true;
      } else {
        print('  - Empty or null section: $section');
      }
    }

    print('=== FINAL RESULT ===');
    print('Has data: $hasData');
    print('Is empty: ${!hasData}');
    
    return !hasData;
  }

  // Fungsi helper untuk cek apakah ada data di section tertentu
  bool hasSectionData(int idLahan, String sectionName) {
    final laporan = _laporanCache[idLahan];
    if (laporan == null) return false;
    
    final section = laporan[sectionName];
    if (section is List) {
      return section.isNotEmpty;
    } else if (section is Map) {
      return section.isNotEmpty;
    }
    return false;
  }

  // Get specific section data
  List<dynamic> getSectionData(int idLahan, String sectionName) {
    final laporan = _laporanCache[idLahan];
    if (laporan == null) return [];
    
    final section = laporan[sectionName];
    if (section is List) {
      return section;
    }
    return [];
  }

  // Get laporan lahan info
  Map<String, dynamic>? getLaporanLahanInfo(int idLahan) {
    final laporan = _laporanCache[idLahan];
    if (laporan == null) return null;
    
    return laporan['laporan_lahan'] as Map<String, dynamic>?;
  }

  // Fungsi untuk menambah URL gambar ke data gambar
  List<Map<String, dynamic>> _formatGambarData(List<String> imageUrls) {
    return imageUrls.where((url) => url.isNotEmpty).map((url) => {
      'Url_Gambar': url,
    }).toList();
  }

  // Fungsi untuk validasi URL gambar
  bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;
    
    // Basic URL validation
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasAbsolutePath) return false;
    
    // Check if URL ends with image extension (optional)
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final lowerUrl = url.toLowerCase();
    
    return imageExtensions.any((ext) => lowerUrl.contains(ext)) || 
           url.startsWith('http://') || url.startsWith('https://');
  }

  // Simpan laporan lengkap - DIPERBAIKI sesuai format API dengan support gambar
  Future<bool> saveLaporan({
    required String token,
    required int idLahan,
    required Map<String, dynamic> laporanData,
    List<String>? imageUrls, // Changed from File? image to List<String>? imageUrls
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== SAVE LAPORAN DEBUG ===');
      print('Saving laporan for idLahan: $idLahan');
      print('LaporanData: $laporanData');
      print('ImageUrls: $imageUrls');

      // LANGKAH 1: Buat laporan lahan dulu
      final laporanLahanResponse = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'Id_Lahan': idLahan,
          'Tanggal_Laporan': DateTime.now().toIso8601String(),
        }),
      );

      print('Laporan Lahan Response: ${laporanLahanResponse.statusCode}');
      print('Laporan Lahan Body: ${laporanLahanResponse.body}');

      if (laporanLahanResponse.statusCode != 200) {
        throw Exception('Gagal membuat laporan lahan: ${laporanLahanResponse.body}');
      }

      final laporanLahanResult = jsonDecode(laporanLahanResponse.body);
      final idLaporanLahan = laporanLahanResult['id_laporan_lahan'];

      // LANGKAH 2: Siapkan data untuk laporan lengkap dengan format yang benar
      final requestBody = <String, dynamic>{
        'Id_Laporan_Lahan': idLaporanLahan,
      };

      // Data Musim Tanam
      final musimTanam = laporanData['musimTanam'];
      if (musimTanam != null && musimTanam['jenisTanaman'] != null) {
        requestBody['MusimTanam'] = {
          'Tanggal_Mulai_Tanam': musimTanam['tanggalTanam'] ?? DateTime.now().toIso8601String(),
          'Jenis_Tanaman': musimTanam['jenisTanaman'],
          'Sumber_Benih': musimTanam['sumberBenih'] ?? '',
        };
      }

      // Data Input Produksi
      final inputProduksi = laporanData['inputProduksi'];
      if (inputProduksi != null && inputProduksi['satuanPupuk'] != null) {
        requestBody['InputProduksi'] = {
          'Jenis_Pupuk': inputProduksi['jenisPupuk'] ?? 'Tidak Diketahui',
          'Jumlah_Pupuk': double.tryParse(inputProduksi['jumlahPupuk']?.toString() ?? '0') ?? 0.0,
          'Satuan_Pupuk': inputProduksi['satuanPupuk'],
          'Jumlah_Pestisida': double.tryParse(inputProduksi['jumlahPestisida']?.toString() ?? '0') ?? 0.0,
          'Satuan_Pestisida': inputProduksi['satuanPestisida'] ?? 'L',
          'Teknik_Pengolahan_Tanah': inputProduksi['teknikPengolahan'] ?? '',
        };
      }

      // Data Pendampingan
      final pendampingan = laporanData['pendampingan'];
      if (pendampingan != null && pendampingan['materiPenyuluhan'] != null) {
        requestBody['Pendampingan'] = {
          'Tanggal_Kunjungan': pendampingan['tanggalKunjungan'] ?? DateTime.now().toIso8601String(),
          'Materi_Penyuluhan': pendampingan['materiPenyuluhan'],
          'Kritik_Dan_Saran': pendampingan['kritikSaran'] ?? '',
        };
      }

      // Data Kendala
      final kendala = laporanData['kendala'];
      if (kendala != null && kendala['deskripsi'] != null && kendala['deskripsi'].isNotEmpty) {
        requestBody['Kendala'] = {
          'Deskripsi': kendala['deskripsi'],
        };
      }

      // Data Hasil Panen
      final hasilPanen = laporanData['hasilPanen'];
      if (hasilPanen != null && hasilPanen['totalPanen'] != null) {
        requestBody['HasilPanen'] = {
          'Tanggal_Panen': hasilPanen['tanggalPanen'] ?? DateTime.now().toIso8601String(),
          'Total_Hasil_Panen': double.tryParse(hasilPanen['totalPanen']?.toString() ?? '0') ?? 0.0,
          'Satuan_Panen': hasilPanen['satuanPanen'] ?? 'Kg',
          'Kualitas': hasilPanen['kualitas'] ?? '',
        };
      }

      // Data Catatan
      final catatan = laporanData['catatan'];
      if (catatan != null && catatan['deskripsi'] != null && catatan['deskripsi'].isNotEmpty) {
        requestBody['Catatan'] = {
          'Deskripsi': catatan['deskripsi'],
        };
      }

      // Data Gambar - NEW: Support untuk multiple image URLs
      if (imageUrls != null && imageUrls.isNotEmpty) {
        final validUrls = imageUrls.where((url) => _isValidImageUrl(url)).toList();
        
        if (validUrls.isNotEmpty) {
          requestBody['Gambar'] = _formatGambarData(validUrls);
          print('✅ Added ${validUrls.length} valid image URLs to request');
          print('Image URLs: $validUrls');
        } else {
          print('⚠️ No valid image URLs found');
        }
      }

      print('Final Request Body: ${jsonEncode(requestBody)}');

      // LANGKAH 3: Kirim data laporan lengkap
      final response = await http.post(
        Uri.parse('$baseUrl/laporan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Final Response status: ${response.statusCode}');
      print('Final Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Save successful, refreshing cache...');
        
        // PENTING: Hapus cache dan fetch ulang untuk memastikan data terbaru
        _laporanCache.remove(idLahan);
        
        // Tunggu sebentar untuk memastikan database sudah ter-update
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Fetch ulang data
        await fetchLaporan(idLahan);
        
        print('✅ Cache refreshed');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception("Gagal menyimpan laporan lengkap: ${response.body}");
      }

    } catch (e) {
      _error = 'Gagal menyimpan laporan: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Error saving laporan: $e');
      return false;
    }
  }

  // UPDATE: Method untuk pre-populate form data saat edit
  Future<bool> loadLaporanForEdit(int idLahan) async {
    try {
      print('=== LOADING LAPORAN FOR EDIT ===');
      print('IdLahan: $idLahan');
      
      // Fetch data dari server jika belum ada di cache
      if (!_laporanCache.containsKey(idLahan)) {
        await fetchLaporan(idLahan);
      }
      
      final laporan = _laporanCache[idLahan];
      if (laporan == null) {
        print('❌ No laporan found for idLahan: $idLahan');
        return false;
      }
      
      print('✅ Laporan loaded for edit');
      print('Available sections: ${laporan.keys.toList()}');
      
      // Debug each section
      laporan.forEach((key, value) {
        if (value is List && value.isNotEmpty) {
          print('Section $key has ${value.length} items');
          print('First item: ${value.first}');
        }
      });
      
      return true;
    } catch (e) {
      print('❌ Error loading laporan for edit: $e');
      _error = 'Gagal memuat data laporan: $e';
      return false;
    }
  }

  // Update laporan yang sudah ada (UPDATE) - DIPERBAIKI dengan support gambar
  Future<bool> updateLaporan({
    required String token,
    required int idLaporanLahan,
    required Map<String, dynamic> laporanData,
    List<String>? imageUrls, // Changed from File? image to List<String>? imageUrls
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('=== UPDATE LAPORAN DEBUG ===');
      print('Updating laporan with idLaporanLahan: $idLaporanLahan');
      print('LaporanData: $laporanData');
      print('ImageUrls: $imageUrls');

      // Siapkan data untuk update dengan format yang benar
      final requestBody = <String, dynamic>{
        'Id_Laporan_Lahan': idLaporanLahan,
      };

      // Data Musim Tanam
      final musimTanam = laporanData['musimTanam'];
      if (musimTanam != null) {
        requestBody['MusimTanam'] = {
          'Tanggal_Mulai_Tanam': musimTanam['tanggalTanam'],
          'Jenis_Tanaman': musimTanam['jenisTanaman'],
          'Sumber_Benih': musimTanam['sumberBenih'],
        };
      }
 
      // Data Input Produksi
      final inputProduksi = laporanData['inputProduksi'];
      if (inputProduksi != null) {
        requestBody['InputProduksi'] = {
          'Jenis_Pupuk': inputProduksi['jenisPupuk'] ?? 'Tidak Diketahui',
          'Jumlah_Pupuk': double.tryParse(inputProduksi['jumlahPupuk']?.toString() ?? '0') ?? 0.0,
          'Satuan_Pupuk': inputProduksi['satuanPupuk'],
          'Jumlah_Pestisida': double.tryParse(inputProduksi['jumlahPestisida']?.toString() ?? '0') ?? 0.0,
          'Satuan_Pestisida': inputProduksi['satuanPestisida'],
          'Teknik_Pengolahan_Tanah': inputProduksi['teknikPengolahan'],
        };
      }

      // Data Pendampingan
      final pendampingan = laporanData['pendampingan'];
      if (pendampingan != null) {
        requestBody['Pendampingan'] = {
          'Tanggal_Kunjungan': pendampingan['tanggalKunjungan'],
          'Materi_Penyuluhan': pendampingan['materiPenyuluhan'],
          'Kritik_Dan_Saran': pendampingan['kritikSaran'],
        };
      }

      // Data Kendala
      final kendala = laporanData['kendala'];
      if (kendala != null) {
        requestBody['Kendala'] = {
          'Deskripsi': kendala['deskripsi'],
        };
      }

      // Data Hasil Panen
      final hasilPanen = laporanData['hasilPanen'];
      if (hasilPanen != null) {
        requestBody['HasilPanen'] = {
          'Tanggal_Panen': hasilPanen['tanggalPanen'],
          'Total_Hasil_Panen': double.tryParse(hasilPanen['totalPanen']?.toString() ?? '0') ?? 0.0,
          'Satuan_Panen': hasilPanen['satuanPanen'],
          'Kualitas': hasilPanen['kualitas'],
        };
      }

      // Data Catatan
      final catatan = laporanData['catatan'];
      if (catatan != null) {
        requestBody['Catatan'] = {
          'Deskripsi': catatan['deskripsi'],
        };
      }

      // Data Gambar - NEW: Support untuk multiple image URLs dalam update
      if (imageUrls != null && imageUrls.isNotEmpty) {
        final validUrls = imageUrls.where((url) => _isValidImageUrl(url)).toList();
        
        if (validUrls.isNotEmpty) {
          requestBody['Gambar'] = _formatGambarData(validUrls);
          print('✅ Updated with ${validUrls.length} valid image URLs');
          print('Image URLs: $validUrls');
        } else {
          print('⚠️ No valid image URLs found for update');
        }
      }

      print('Update Request Body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse('$baseUrl/laporan/$idLaporanLahan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      print('Update Response status: ${response.statusCode}');
      print('Update Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Update successful, refreshing cache...');
        
        // Cari idLahan berdasarkan idLaporanLahan
        int? idLahan;
        _laporanCache.forEach((key, value) {
          if (value['laporan_lahan']?['id_laporan_lahan'] == idLaporanLahan) {
            idLahan = key;
          }
        });
        
        if (idLahan != null) {
          // Hapus cache dan fetch ulang
          _laporanCache.remove(idLahan);
          await Future.delayed(const Duration(milliseconds: 500));
          await fetchLaporan(idLahan!);
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception("Gagal mengupdate laporan: ${response.body}");
      }

    } catch (e) {
      _error = 'Gagal mengupdate laporan: $e';
      _isLoading = false;
      notifyListeners();
      print('❌ Error updating laporan: $e');
      return false;
    }
  }

  // Method untuk mendapatkan ID laporan lahan dari data yang ada
  int? getLaporanLahanId(int idLahan) {
    final laporan = _laporanCache[idLahan];
    return laporan?['laporan_lahan']?['id_laporan_lahan'];
  }

  // Method untuk mendapatkan daftar URL gambar
  List<String> getImageUrls(int idLahan) {
    final gambarList = getSectionData(idLahan, 'gambar');
    return gambarList
        .map((item) => item['url_gambar'] as String? ?? item['Url_Gambar'] as String? ?? '')
        .where((url) => url.isNotEmpty)
        .toList();
  }

  // Method untuk menambah URL gambar baru
  void addImageUrl(int idLahan, String imageUrl) {
    if (!_isValidImageUrl(imageUrl)) {
      print('⚠️ Invalid image URL: $imageUrl');
      return;
    }

    final laporan = _laporanCache[idLahan];
    if (laporan != null) {
      final gambarList = laporan['gambar'] as List<dynamic>? ?? [];
      gambarList.add({'Url_Gambar': imageUrl});
      laporan['gambar'] = gambarList;
      notifyListeners();
      print('✅ Image URL added to cache: $imageUrl');
    }
  }

  // Method untuk menghapus URL gambar
  void removeImageUrl(int idLahan, String imageUrl) {
    final laporan = _laporanCache[idLahan];
    if (laporan != null) {
      final gambarList = laporan['gambar'] as List<dynamic>? ?? [];
      gambarList.removeWhere((item) => 
          item['url_gambar'] == imageUrl || item['Url_Gambar'] == imageUrl);
      laporan['gambar'] = gambarList;
      notifyListeners();
      print('✅ Image URL removed from cache: $imageUrl');
    }
  }

  // Hapus laporan (DELETE)
  Future<bool> deleteLaporan(String token, int idLaporanLahan) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/laporan/$idLaporanLahan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Hapus dari cache juga
        _laporanCache.removeWhere((key, value) => 
          value['laporan_lahan']?['id_laporan_lahan'] == idLaporanLahan);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception("Gagal menghapus laporan: ${response.body}");
      }
      
    } catch (e) {
      _error = 'Gagal menghapus laporan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear cache untuk lahan tertentu
  void clearLaporanCache(int idLahan) {
    _laporanCache.remove(idLahan);
    notifyListeners();
  }

  // Clear semua cache
  void clearAllCache() {
    _laporanCache.clear();
    notifyListeners();
  }

  // Debug method - untuk development saja
  void debugPrintCache() {
    print('=== CACHE DEBUG ===');
    _laporanCache.forEach((key, value) {
      print('IdLahan $key: ${value.keys.toList()}');
      if (value['laporan_lahan'] != null) {
        print('  - Laporan Lahan ID: ${value['laporan_lahan']['id_laporan_lahan']}');
      }
      if (value['gambar'] != null && (value['gambar'] as List).isNotEmpty) {
        print('  - Images: ${(value['gambar'] as List).length} items');
      }
    });
  }
}