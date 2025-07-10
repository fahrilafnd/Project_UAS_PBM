import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http_parser/http_parser.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AddMappingLogic {
  List<LatLng> polygonPoints = [];
  LatLng? userLocation;
  final ScreenshotController screenshotController = ScreenshotController();
  final MapController mapController = MapController();
  bool isSubmitting = false;
  bool isDisposed = false;

  // Callback functions untuk komunikasi dengan UI
  Function(VoidCallback)? onStateChanged;
  Function(String)? onShowMessage;
  Function()? onNavigateToMapping;

  AddMappingLogic({
    this.onStateChanged,
    this.onShowMessage,
    this.onNavigateToMapping,
  });

  void dispose() {
    isDisposed = true;
  }

  void safeSetState(VoidCallback fn) {
    if (!isDisposed && onStateChanged != null) {
      onStateChanged!(fn);
    }
  }

  // Fungsi untuk undo titik terakhir
  void undoLastPoint() {
    if (!isDisposed && polygonPoints.isNotEmpty) {
      safeSetState(() {
        polygonPoints.removeLast();
      });
      _showMessage("Titik terakhir telah dihapus");
    } else if (polygonPoints.isEmpty) {
      _showMessage("Tidak ada titik untuk dihapus");
    }
  }

  // Fungsi untuk clear semua titik
  void clearAllPoints() {
    if (!isDisposed) {
      safeSetState(() {
        polygonPoints.clear();
      });
      _showMessage("Semua titik telah dihapus");
    }
  }

  // Fungsi untuk mengecek apakah polygon valid
  bool isPolygonValid() {
    return polygonPoints.length >= 3;
  }

  // Fungsi untuk mendapatkan status polygon
  String getPolygonStatus() {
    if (polygonPoints.isEmpty) {
      return "Belum ada titik polygon";
    } else if (polygonPoints.length < 3) {
      return "Minimal 3 titik diperlukan (saat ini: ${polygonPoints.length})";
    } else {
      return "${polygonPoints.length} titik polygon siap";
    }
  }

  Future<void> getUserLocation() async {
    if (isDisposed) return;
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Layanan lokasi tidak aktif');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showMessage('Izin lokasi ditolak');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage('Izin lokasi ditolak permanen');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (!isDisposed) {
        safeSetState(() {
          userLocation = LatLng(position.latitude, position.longitude);
        });

        if (!isDisposed) {
          mapController.move(userLocation!, 18);
        }
      }
    } catch (e) {
      _showMessage('Error mendapatkan lokasi: $e');
    }
  }

  LatLng hitungCentroid(List<LatLng> points) {
    double lat = 0.0;
    double lng = 0.0;
    for (var p in points) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return LatLng(lat / points.length, lng / points.length);
  }

  Future<String?> uploadToCloudinary(Uint8List imageBytes) async {
    if (isDisposed) return null;
    
    try {
      const cloudName = 'dxwzt2mhr';
      const uploadPreset = 'PocketFarm';

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'polygon.png',
            contentType: MediaType('image', 'png'),
          ),
        );

      final response = await request.send();
      
      if (isDisposed) return null;
      
      if (response.statusCode == 200) {
        final res = await http.Response.fromStream(response);
        if (isDisposed) return null;
        
        final data = json.decode(res.body);
        return data['secure_url'];
      } else {
        final res = await http.Response.fromStream(response);
        if (!isDisposed) {
          debugPrint('Cloudinary upload failed: ${response.statusCode}');
          debugPrint('Response body: ${res.body}');
        }
        return null;
      }
    } catch (e) {
      if (!isDisposed) {
        debugPrint('Cloudinary upload error: $e');
      }
      return null;
    }
  }

  Future<void> submitPolygon() async {
    if (isSubmitting || isDisposed) return;
    
    if (polygonPoints.length < 3) {
      _showMessage("Minimal 3 titik diperlukan untuk membuat polygon.");
      return;
    }

    isSubmitting = true;
    safeSetState(() {});

    try {
      _showMessage("Menyimpan data lahan...");

      Uint8List? image = await screenshotController.capture();
      if (isDisposed || image == null) {
        _resetSubmitting();
        return;
      }

      String? imageUrl = await uploadToCloudinary(image);
      if (isDisposed) {
        _resetSubmitting();
        return;
      }
      
      if (imageUrl == null) {
        _showMessage("Gagal mengunggah gambar ke Cloudinary.");
        _resetSubmitting();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      if (isDisposed) {
        _resetSubmitting();
        return;
      }
      
      final token = prefs.getString('token');
      if (token == null || JwtDecoder.isExpired(token)) {
        _showMessage("Token tidak tersedia atau telah kadaluarsa.");
        _resetSubmitting();
        return;
      }

      final decoded = JwtDecoder.decode(token);
      final userId = _extractUserIdFromToken(decoded);
      if (userId == null) {
        _showMessage("ID pengguna tidak ditemukan dalam token.");
        _resetSubmitting();
        return;
      }

      final nama = prefs.getString('draft_nama_lahan');
      final satuan = prefs.getString('draft_satuan_luas');
      final luas = prefs.getDouble('draft_luas_lahan');
      final lokasi = prefs.getString('draft_lokasi_lahan');
      final centroid = hitungCentroid(polygonPoints);

      if ([nama, satuan, luas].contains(null)) {
        _showMessage("Data lahan belum lengkap.");
        _resetSubmitting();
        return;
      }

      final uri = Uri.parse("http://192.168.43.143:5042/api/Laporan/polygon-image");

      final body = {
        "Nama_Lahan": nama,
        "Luas_Lahan": luas,
        "Satuan_Luas": satuan,
        "Koordinat": lokasi,
        "Centroid_Lat": centroid.latitude,
        "Centroid_Lng": centroid.longitude,
        "Id_Users": userId,
        "Polygon_Img": imageUrl,
      };

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (isDisposed) {
        _resetSubmitting();
        return;
      }

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final idLahan = result['id_lahan'];

        _showMessage("Berhasil menyimpan lahan dengan ID: $idLahan");
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (!isDisposed && onNavigateToMapping != null) {
          onNavigateToMapping!();
        }
      } else {
        _showMessage("Gagal menyimpan lahan: ${response.body}");
      }
    } catch (e) {
      _showMessage("Terjadi kesalahan: $e");
    } finally {
      _resetSubmitting();
    }
  }

  void _resetSubmitting() {
    isSubmitting = false;
    safeSetState(() {});
  }

  void _showMessage(String message) {
    if (!isDisposed && onShowMessage != null) {
      onShowMessage!(message);
    }
  }

  int? _extractUserIdFromToken(Map<String, dynamic> token) {
    final possibleIdFields = [
      'Id_Users',
      'sub',
      'nameid',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
      'userId',
    ];

    for (final field in possibleIdFields) {
      final value = token[field];
      if (value != null) {
        if (value is int) return value;
        if (value is String) return int.tryParse(value);
      }
    }

    debugPrint('Token Structure: $token');
    return null;
  }

  void onMapTap(TapPosition tapPosition, LatLng point) {
    if (!isDisposed && !isSubmitting) {
      safeSetState(() {
        polygonPoints.add(point);
      });
      
    }
  }
}