import 'package:flutter/material.dart';
import 'package:projek_uas/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:projek_uas/screen/KebunSaya/detailLaporan.dart';
import 'package:projek_uas/providers/lahan_provider.dart';
import 'package:projek_uas/providers/laporan_provider.dart';

extension FirstOrNullExt<T> on List<T> {
  T? firstOrNull() => isEmpty ? null : first;
}

class DetailLahanLogic {
  final BuildContext context;
  final int idLahan;
  String? token;

  DetailLahanLogic(this.context, this.idLahan);

  // ===== TOKEN MANAGEMENT =====
  
  Future<String?> getTokenFromAuthProvider() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      return authProvider.token;
    } catch (e) {
      return null;
    }
  }

  // ===== DATA INITIALIZATION =====
  
  Future<void> initializeData() async {
    token = await getTokenFromAuthProvider();
    final laporanProvider = Provider.of<LaporanProvider>(context, listen: false);
    await laporanProvider.fetchLaporan(idLahan);
  }

  // ===== LAPORAN OPERATIONS =====
  
  Future<void> refreshLaporan() async {
    final laporanProvider = Provider.of<LaporanProvider>(context, listen: false);
    laporanProvider.clearLaporanCache(idLahan);
    await laporanProvider.fetchLaporan(idLahan);
  }

  Future<void> createLaporan() async {
    if (token == null) {
      _showSnackBar('Token tidak tersedia. Silakan login ulang.', Colors.red);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailLaporan(idLahan: idLahan, isEdit: false),
      ),
    );

    if (result == true) {
      await refreshLaporan();
      _showSnackBar('Laporan berhasil dibuat', Colors.green);
    }
  }

  Future<void> editLaporan() async {
    if (token == null) {
      _showSnackBar('Token tidak tersedia. Silakan login ulang.', Colors.red);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailLaporan(idLahan: idLahan, isEdit: true),
      ),
    );

    if (result == true) {
      await refreshLaporan();
      _showSnackBar('Laporan berhasil diperbarui', Colors.green);
    }
  }

  Future<void> deleteLaporan() async {
    if (token == null) {
      _showSnackBar('Token tidak tersedia. Silakan login ulang.', Colors.red);
      return;
    }

    final laporanProvider = Provider.of<LaporanProvider>(context, listen: false);
    final idLaporanLahan = laporanProvider.getLaporanLahanId(idLahan);

    if (idLaporanLahan == null) {
      _showSnackBar('ID laporan tidak ditemukan', Colors.red);
      return;
    }

    final shouldDelete = await _showDeleteConfirmationDialog();
    if (shouldDelete != true) return;

    _showLoadingDialog();

    final success = await laporanProvider.deleteLaporan(token!, idLaporanLahan);
    Navigator.of(context).pop(); // Close loading dialog

    if (success) {
      _showSnackBar('Laporan berhasil dihapus', Colors.green);
      await refreshLaporan();
    } else {
      _showSnackBar(
        laporanProvider.error ?? 'Gagal menghapus laporan',
        Colors.red,
      );
    }
  }

  // ===== IMAGE PROCESSING =====
  
  List<String> getImageUrls(Map<String, dynamic> laporan) {
    List<String> imageUrls = [];

    try {
      // Check imageUrls field (array format)
      if (laporan['imageUrls'] != null && laporan['imageUrls'] is List) {
        for (var url in laporan['imageUrls']) {
          if (url is String && url.isNotEmpty && _isValidUrl(url)) {
            imageUrls.add(url);
          }
        }
      }

      // Check single imageUrl field (backward compatibility)
      if (laporan['imageUrl'] != null &&
          laporan['imageUrl'].toString().isNotEmpty &&
          _isValidUrl(laporan['imageUrl'].toString())) {
        final singleUrl = laporan['imageUrl'].toString();
        if (!imageUrls.contains(singleUrl)) {
          imageUrls.add(singleUrl);
        }
      }

      // Check gambar field (legacy format)
      if (laporan['gambar'] != null && laporan['gambar'] is List) {
        for (var gambar in laporan['gambar']) {
          String? url = _extractUrlFromGambar(gambar);
          if (url != null && !imageUrls.contains(url)) {
            imageUrls.add(url);
          }
        }
      }

      // Check images field (alternative format)
      if (laporan['images'] != null && laporan['images'] is List) {
        for (var img in laporan['images']) {
          String? url = _extractUrlFromImage(img);
          if (url != null && !imageUrls.contains(url)) {
            imageUrls.add(url);
          }
        }
      }
    } catch (e) {
      // Handle error silently
    }

    return imageUrls;
  }

  bool hasImages(Map<String, dynamic>? laporan) {
    if (laporan == null) return false;
    return getImageUrls(laporan).isNotEmpty;
  }

  // ===== DATA FORMATTING =====
  
  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String formatNumber(dynamic number, String unit) {
    if (number == null) return '-';
    return '$number $unit';
  }

  String formatLuasLahan(LahanProvider lahanProvider) {
    return lahanProvider.formatLuasLahan(idLahan);
  }

  String formatKoordinat(LahanProvider lahanProvider) {
    return lahanProvider.formatKoordinat(idLahan);
  }

  String formatCentroidLat(LahanProvider lahanProvider) {
    return lahanProvider.formatCentroid(idLahan, 'lat');
  }

  String formatCentroidLng(LahanProvider lahanProvider) {
    return lahanProvider.formatCentroid(idLahan, 'lng');
  }

  String getNamaLahan(LahanProvider lahanProvider, String fallbackTitle) {
    return lahanProvider.getNamaLahan(idLahan, fallback: fallbackTitle);
  }

  // ===== DATA EXTRACTION =====
  
  Map<String, String> getMusimTanamData(Map<String, dynamic>? laporan) {
    final musimTanam = _getFirstItemFromList(laporan, 'musimTanam');
    if (musimTanam == null) return {};

    return {
      "Tanggal Mulai Tanam": formatDate(musimTanam['tanggal_mulai_tanam']),
      "Jenis Tanaman": musimTanam['jenis_tanaman'] ?? '-',
      "Sumber Benih": musimTanam['sumber_benih'] ?? '-',
    };
  }

  Map<String, String> getInputProduksiData(Map<String, dynamic>? laporan) {
    final inputProduksi = _getFirstItemFromList(laporan, 'inputProduksi');
    if (inputProduksi == null) return {};

    return {
      "Jumlah Pupuk": formatNumber(
        inputProduksi['jumlah_pupuk'],
        inputProduksi['satuan_pupuk'] ?? '',
      ),
      "Jumlah Pestisida": formatNumber(
        inputProduksi['jumlah_pestisida'],
        inputProduksi['satuan_pestisida'] ?? '',
      ),
      "Teknik Pengolahan": inputProduksi['teknik_pengolahan_tanah'] ?? '-',
    };
  }

  Map<String, String> getHasilPanenData(Map<String, dynamic>? laporan) {
    final hasilPanen = _getFirstItemFromList(laporan, 'hasilPanen');
    if (hasilPanen == null) return {};

    return {
      "Tanggal Panen": formatDate(hasilPanen['tanggal_panen']),
      "Total Panen": formatNumber(
        hasilPanen['total_hasil_panen'],
        hasilPanen['satuan_panen'] ?? '',
      ),
      "Kualitas": hasilPanen['kualitas'] ?? '-',
    };
  }

  Map<String, String> getPendampinganData(Map<String, dynamic>? laporan) {
    final pendampingan = _getFirstItemFromList(laporan, 'pendampingan');
    if (pendampingan == null) return {};

    return {
      "Tanggal Kunjungan": formatDate(pendampingan['tanggal_kunjungan']),
      "Materi Penyuluhan": pendampingan['materi_penyuluhan'] ?? '-',
      "Kritik dan Saran": pendampingan['kritik_dan_saran'] ?? '-',
    };
  }

  Map<String, String> getKendalaData(Map<String, dynamic>? laporan) {
    final kendala = _getFirstItemFromList(laporan, 'kendala');
    if (kendala == null) return {};

    return {
      "Deskripsi": kendala['deskripsi'] ?? '-',
    };
  }

  Map<String, String> getCatatanData(Map<String, dynamic>? laporan) {
    final catatan = _getFirstItemFromList(laporan, 'catatan');
    if (catatan == null) return {};

    return {
      "Deskripsi": catatan['deskripsi'] ?? '-',
    };
  }

  Map<String, String> getInformasiLahanData(LahanProvider lahanProvider, String fallbackTitle) {
    return {
      "Nama Lahan": getNamaLahan(lahanProvider, fallbackTitle),
      "Luas Lahan": formatLuasLahan(lahanProvider),
      "Koordinat": formatKoordinat(lahanProvider),
      "Centroid Lat": formatCentroidLat(lahanProvider),
      "Centroid Lng": formatCentroidLng(lahanProvider),
    };
  }

  // ===== PRIVATE HELPER METHODS =====
  
  Map<String, dynamic>? _getFirstItemFromList(Map<String, dynamic>? laporan, String key) {
    if (laporan == null || 
        laporan[key] == null || 
        laporan[key] is! List || 
        (laporan[key] as List).isEmpty) {
      return null;
    }
    return (laporan[key] as List).firstOrNull();
  }

  String? _extractUrlFromGambar(dynamic gambar) {
    String? url;
    
    if (gambar is String && gambar.isNotEmpty) {
      url = gambar;
    } else if (gambar is Map) {
      url = gambar['url_gambar'] ?? 
            gambar['url'] ?? 
            gambar['image_url'] ?? 
            gambar['gambar'];
    }

    return (url != null && url.isNotEmpty && _isValidUrl(url)) ? url : null;
  }

  String? _extractUrlFromImage(dynamic img) {
    String? url;
    
    if (img is String && img.isNotEmpty) {
      url = img;
    } else if (img is Map) {
      url = img['url'] ?? img['image_url'] ?? img['src'];
    }

    return (url != null && url.isNotEmpty && _isValidUrl(url)) ? url : null;
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus laporan ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }
}