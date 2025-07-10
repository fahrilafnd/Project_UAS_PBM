import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projek_uas/providers/laporan_provider.dart';
import 'package:projek_uas/screen/KebunSaya/DetailLaporan/image_handler.dart';

class DetailLaporanLogic {
  // Controllers
  final TextEditingController tanggalTanamController = TextEditingController();
  final TextEditingController jenisTanamanController = TextEditingController();
  final TextEditingController jumlahPupukController = TextEditingController();
  final TextEditingController jumlahPestisidaController =
      TextEditingController();
  final TextEditingController teknikPengolahanController =
      TextEditingController();
  final TextEditingController tanggalKunjunganController =
      TextEditingController();
  final TextEditingController materiPenyuluhanController =
      TextEditingController();
  final TextEditingController kritikDanSaranController =
      TextEditingController();
  final TextEditingController deskripsiKendalaController =
      TextEditingController();
  final TextEditingController tanggalPanenController = TextEditingController();
  final TextEditingController totalPanenController =
      TextEditingController();
  final TextEditingController kualitasHasilController = TextEditingController();
  final TextEditingController deskripsiCatatanController =
      TextEditingController();

  // State variables
  bool isInitialized = false;
  bool isLoading = true;
  late ImageHandlerService imageHandler;

  // Dropdown
  String sumberBenih = 'Mandiri';
  String satuanPupuk = 'Kg';
  String satuanPestisida = 'L';
  String satuanPanen = 'Kg'; 
  String kualitasHasil = 'Bagus';

  // Dropdown options
  final List<String> sumberBenihOptions = [
    'Mandiri',
    'Bantuan',
    'Dinas',
    'Lainnya',
  ];
  final List<String> satuanPupukOptions = ['Kg', 'L', 'Ton'];
  final List<String> satuanPestisidaOptions = ['Kg', 'L'];
  final List<String> satuanPanenOptions = [
    'Kg',
    'Ton',
  ]; 
  final List<String> kualitasHasilOptions = ['Bagus', 'Sedang', 'Rusak'];

  // Callback untuk update UI
  final VoidCallback? onStateChanged;

  DetailLaporanLogic({this.onStateChanged});

  // Initialize logic
  void initialize(BuildContext context) {
    imageHandler = ImageHandlerService(
      context: context,
      onStateChanged: () {
        onStateChanged?.call();
      },
    );
  }

  Future<void> initializeData(
    BuildContext context,
    int idLahan,
    bool isEdit,
  ) async {
    if (isEdit) {
      await loadExistingData(context, idLahan);
    }
    isLoading = false;
    isInitialized = true;
    onStateChanged?.call();
  }

  Future<void> loadExistingData(BuildContext context, int idLahan) async {
    try {
      final laporanProvider = Provider.of<LaporanProvider>(
        context,
        listen: false,
      );

      await laporanProvider.fetchLaporan(idLahan);
      final laporan = laporanProvider.getLaporan(idLahan);
      if (laporan != null) {
        populateFormFromExistingData(laporan);
      }
    } catch (e) {
      print('Error loading existing data: $e');
    }
  }

  List<String> _getImageUrls(Map<String, dynamic> laporan) {
    List<String> imageUrls = [];

    try {

      if (laporan['imageUrls'] != null && laporan['imageUrls'] is List) {
        for (var url in laporan['imageUrls']) {
          if (url is String && url.isNotEmpty && _isValidUrl(url)) {
            imageUrls.add(url);
          }
        }
      }

      if (laporan['imageUrl'] != null &&
          laporan['imageUrl'].toString().isNotEmpty &&
          _isValidUrl(laporan['imageUrl'].toString())) {
        final singleUrl = laporan['imageUrl'].toString();
        if (!imageUrls.contains(singleUrl)) {
          imageUrls.add(singleUrl);
        }
      }

      if (laporan['gambar'] != null && laporan['gambar'] is List) {
        for (var gambar in laporan['gambar']) {
          String? url;

          if (gambar is String && gambar.isNotEmpty) {
            url = gambar;
          } else if (gambar is Map) {
            url = gambar['url_gambar'] ??
                gambar['url'] ??
                gambar['image_url'] ??
                gambar['gambar'];
          }

          if (url != null &&
              url.isNotEmpty &&
              _isValidUrl(url) &&
              !imageUrls.contains(url)) {
            imageUrls.add(url);
          }
        }
      }

      if (laporan['images'] != null && laporan['images'] is List) {
        for (var img in laporan['images']) {
          String? url;

          if (img is String && img.isNotEmpty) {
            url = img;
          } else if (img is Map) {
            url = img['url'] ?? img['image_url'] ?? img['src'];
          }

          if (url != null &&
              url.isNotEmpty &&
              _isValidUrl(url) &&
              !imageUrls.contains(url)) {
            imageUrls.add(url);
          }
        }
      }

      print('=== IMAGE DEBUG (DetailLaporanLogic) ===');
      print('Laporan keys: ${laporan.keys.toList()}');
      print('Found ${imageUrls.length} images: $imageUrls');
      print('=======================================');
    } catch (e) {
      print('Error getting image URLs: $e');
    }

    return imageUrls;
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  void populateFormFromExistingData(Map<String, dynamic> laporan) {
    try {
      print('=== POPULATING FORM FROM EXISTING DATA ===');
      print('Laporan structure: ${laporan.keys.toList()}');

      final musimTanam = laporan['musimTanam'] as List<dynamic>?;
      if (musimTanam != null && musimTanam.isNotEmpty) {
        final firstMusimTanam = musimTanam[0] as Map<String, dynamic>;
        print('MusimTanam data: $firstMusimTanam');

        tanggalTanamController.text = formatDateForDisplay(
          firstMusimTanam['tanggal_mulai_tanam']?.toString() ??
              firstMusimTanam['Tanggal_Mulai_Tanam']?.toString() ??
              '',
        );
        jenisTanamanController.text =
            firstMusimTanam['jenis_tanaman']?.toString() ??
            firstMusimTanam['Jenis_Tanaman']?.toString() ??
            '';
        sumberBenih =
            firstMusimTanam['sumber_benih']?.toString() ??
            firstMusimTanam['Sumber_Benih']?.toString() ??
            'Mandiri';
      }

      final inputProduksi = laporan['inputProduksi'] as List<dynamic>?;
      if (inputProduksi != null && inputProduksi.isNotEmpty) {
        final firstInput = inputProduksi[0] as Map<String, dynamic>;
        print('InputProduksi data: $firstInput');
        jumlahPupukController.text =
            firstInput['jumlah_pupuk']?.toString() ??
            firstInput['Jumlah_Pupuk']?.toString() ??
            '';
        jumlahPestisidaController.text =
            firstInput['jumlah_pestisida']?.toString() ??
            firstInput['Jumlah_Pestisida']?.toString() ??
            '';
        teknikPengolahanController.text =
            firstInput['teknik_pengolahan_tanah']?.toString() ??
            firstInput['Teknik_Pengolahan_Tanah']?.toString() ??
            '';
        satuanPupuk =
            firstInput['satuan_pupuk']?.toString() ??
            firstInput['Satuan_Pupuk']?.toString() ??
            'Kg';
        satuanPestisida =
            firstInput['satuan_pestisida']?.toString() ??
            firstInput['Satuan_Pestisida']?.toString() ??
            'L';
      }

      final pendampingan = laporan['pendampingan'] as List<dynamic>?;
      if (pendampingan != null && pendampingan.isNotEmpty) {
        final firstPendampingan = pendampingan[0] as Map<String, dynamic>;
        print('Pendampingan data: $firstPendampingan');

        tanggalKunjunganController.text = formatDateForDisplay(
          firstPendampingan['tanggal_kunjungan']?.toString() ??
              firstPendampingan['Tanggal_Kunjungan']?.toString() ??
              '',
        );
        materiPenyuluhanController.text =
            firstPendampingan['materi_penyuluhan']?.toString() ??
            firstPendampingan['Materi_Penyuluhan']?.toString() ??
            '';
        kritikDanSaranController.text =
            firstPendampingan['kritik_dan_saran']?.toString() ??
            firstPendampingan['Kritik_Dan_Saran']?.toString() ??
            '';
      }

      final kendala = laporan['kendala'] as List<dynamic>?;
      if (kendala != null && kendala.isNotEmpty) {
        final firstKendala = kendala[0] as Map<String, dynamic>;
        print('Kendala data: $firstKendala');

        deskripsiKendalaController.text =
            firstKendala['deskripsi']?.toString() ??
            firstKendala['Deskripsi']?.toString() ??
            '';
      }

      final hasilPanen = laporan['hasilPanen'] as List<dynamic>?;
      if (hasilPanen != null && hasilPanen.isNotEmpty) {
        final firstHasil = hasilPanen[0] as Map<String, dynamic>;
        print('HasilPanen data: $firstHasil');

        tanggalPanenController.text = formatDateForDisplay(
          firstHasil['tanggal_panen']?.toString() ??
              firstHasil['Tanggal_Panen']?.toString() ??
              '',
        );
        totalPanenController.text =
            firstHasil['total_hasil_panen']?.toString() ??
            firstHasil['Total_Hasil_Panen']?.toString() ??
            '';
        satuanPanen =
            firstHasil['satuan_panen']?.toString() ??
            firstHasil['Satuan_Panen']?.toString() ??
            'Kg';
        kualitasHasil =
            firstHasil['kualitas']?.toString() ??
            firstHasil['Kualitas']?.toString() ??
            'Bagus';
      }

      final catatan = laporan['catatan'] as List<dynamic>?;
      if (catatan != null && catatan.isNotEmpty) {
        final firstCatatan = catatan[0] as Map<String, dynamic>;
        print('Catatan data: $firstCatatan');

        deskripsiCatatanController.text =
            firstCatatan['deskripsi']?.toString() ??
            firstCatatan['Deskripsi']?.toString() ??
            '';
      }

      List<String> existingImages = _getImageUrls(laporan);

      if (existingImages.isNotEmpty) {
        imageHandler.initializeWithExistingImages(existingImages);
        print(
          '✅ Loaded ${existingImages.length} existing images: $existingImages',
        );
      }

      print('=== FORM POPULATION COMPLETED ===');
    } catch (e) {
      print('❌ Error populating form: $e');
    }
  }

  // Format date for display
  String formatDateForDisplay(String dateString) {
    try {
      if (dateString.isEmpty) return '';
      DateTime date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Date parsing error: $e for date: $dateString');
      return dateString;
    }
  }

  // Format date to ISO string
  String formatTanggal(String input) {
    try {
      if (input.isEmpty) return DateTime.now().toIso8601String();
      DateTime parsed = DateTime.parse(input);
      return parsed.toIso8601String();
    } catch (e) {
      print('Date formatting error: $e for input: $input');
      return DateTime.now().toIso8601String();
    }
  }

  bool validateForm(BuildContext context) {
    if (tanggalTanamController.text.isEmpty ||
        jenisTanamanController.text.isEmpty ||
        jumlahPupukController.text.isEmpty ||
        jumlahPestisidaController.text.isEmpty ||
        teknikPengolahanController.text.isEmpty ||
        tanggalKunjunganController.text.isEmpty ||
        materiPenyuluhanController.text.isEmpty ||
        kritikDanSaranController.text.isEmpty ||
        deskripsiKendalaController.text.isEmpty ||
        tanggalPanenController.text.isEmpty ||
        totalPanenController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Semua field harus diisi.")));
      return false;
    }

    if (double.tryParse(jumlahPupukController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jumlah pupuk harus berupa angka.")),
      );
      return false;
    }

    if (double.tryParse(jumlahPestisidaController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Jumlah pestisida harus berupa angka.")),
      );
      return false;
    }

    if (double.tryParse(totalPanenController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Total hasil panen harus berupa angka.")),
      );
      return false;
    }

    return true;
  }

  Map<String, dynamic> prepareLaporanData() {
    return {
      'musimTanam': {
        'tanggalTanam': formatTanggal(tanggalTanamController.text),
        'jenisTanaman': jenisTanamanController.text,
        'sumberBenih': sumberBenih,
      },
      'inputProduksi': {
        'jumlahPupuk': double.tryParse(jumlahPupukController.text) ?? 0.0,
        'satuanPupuk': satuanPupuk,
        'jumlahPestisida':
            double.tryParse(jumlahPestisidaController.text) ?? 0.0,
        'satuanPestisida': satuanPestisida,
        'teknikPengolahan': teknikPengolahanController.text,
      },
      'pendampingan': {
        'tanggalKunjungan': formatTanggal(tanggalKunjunganController.text),
        'materiPenyuluhan': materiPenyuluhanController.text,
        'kritikSaran': kritikDanSaranController.text,
      },
      'kendala': {'deskripsi': deskripsiKendalaController.text},
      'hasilPanen': {
        'tanggalPanen': formatTanggal(tanggalPanenController.text),
        'totalPanen':
            double.tryParse(totalPanenController.text) ??
            0.0, 
        'satuanPanen': satuanPanen,
        'kualitas': kualitasHasil,
      },
      'catatan': {'deskripsi': deskripsiCatatanController.text},
    };
  }

  Future<bool> saveLaporan(
    BuildContext context,
    int idLahan,
    bool isEdit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Token tidak ditemukan. Harap login ulang."),
          ),
        );
        return false;
      }

      if (!validateForm(context)) return false;

      // Upload gambar baru ke Cloudinary jika ada
      List<String> newlyUploadedUrls = [];
      if (imageHandler.hasSelectedImages) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mengupload gambar...')));

        newlyUploadedUrls = await imageHandler.uploadMultipleToCloudinary(
          onUploadStart: () {
            print('Starting image upload...');
          },
          onProgress: (current, total) {
            print('Uploading image $current of $total');
          },
          onUploadComplete: () {
            print('Image upload completed');
          },
        );

        if (newlyUploadedUrls.isEmpty && imageHandler.hasSelectedImages) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Gagal mengupload beberapa gambar. Melanjutkan dengan gambar yang berhasil diupload.',
              ),
            ),
          );
        }
      }

      final allImageUrls = <String>[];
      allImageUrls.addAll(imageHandler.existingImageUrls);
      allImageUrls.addAll(newlyUploadedUrls);

      // Remove duplicates
      final uniqueImageUrls = allImageUrls.toSet().toList();

      // Siapkan data laporan
      final laporanData = prepareLaporanData();

      // Gunakan provider untuk save atau update
      final laporanProvider = Provider.of<LaporanProvider>(
        context,
        listen: false,
      );

      bool success;
      if (isEdit) {
        // Mode edit - gunakan update
        final idLaporanLahan = laporanProvider.getLaporanLahanId(idLahan);
        if (idLaporanLahan == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ID Laporan tidak ditemukan')),
          );
          return false;
        }

        success = await laporanProvider.updateLaporan(
          token: token,
          idLaporanLahan: idLaporanLahan,
          laporanData: laporanData,
          imageUrls:
              uniqueImageUrls.isNotEmpty
                  ? uniqueImageUrls
                  : null, 
        );
      } else {
        // Mode create - gunakan save
        success = await laporanProvider.saveLaporan(
          token: token,
          idLahan: idLahan,
          laporanData: laporanData,
          imageUrls:
              uniqueImageUrls.isNotEmpty
                  ? uniqueImageUrls
                  : null, 
        );
      }

      if (success) {
        _clearSelectedImagesOnly();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Laporan berhasil diperbarui'
                  : 'Laporan berhasil disimpan',
            ),
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal ${isEdit ? 'memperbarui' : 'menyimpan'} laporan: ${laporanProvider.error}',
            ),
          ),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal ${isEdit ? 'memperbarui' : 'menyimpan'} laporan: $e',
          ),
        ),
      );
      return false;
    }
  }

  void _clearSelectedImagesOnly() {
    if (imageHandler.uploadedImageUrls.isNotEmpty) {
      final currentExisting = List<String>.from(imageHandler.existingImageUrls);
      currentExisting.addAll(imageHandler.uploadedImageUrls);
      imageHandler.initializeWithExistingImages(currentExisting);
    }

    imageHandler.clearUploadedImages();
  }

  ImageHandlerService get getImageHandler => imageHandler;

  void showImagePicker() {
    imageHandler.showImageSourceDialog();
  }

  bool get hasImages => imageHandler.hasImages;
  bool get isUploadingImages => imageHandler.isUploadingImages;
  int get totalImages => imageHandler.totalImages;

  List<String> getAllDisplayImages() {
    final List<String> allImages = [];
    allImages.addAll(imageHandler.existingImageUrls);
    allImages.addAll(imageHandler.uploadedImageUrls);
    return allImages;
  }

  void updateSumberBenih(String? value) {
    if (value != null) {
      sumberBenih = value;
      onStateChanged?.call();
    }
  }

  void updateSatuanPupuk(String? value) {
    if (value != null) {
      satuanPupuk = value;
      onStateChanged?.call();
    }
  }

  void updateSatuanPestisida(String? value) {
    if (value != null) {
      satuanPestisida = value;
      onStateChanged?.call();
    }
  }

  void updateSatuanPanen(String? value) {
    if (value != null) {
      satuanPanen = value;
      onStateChanged?.call();
    }
  }

  void updateKualitasHasil(String? value) {
    if (value != null) {
      kualitasHasil = value;
      onStateChanged?.call();
    }
  }

  // Dispose controllers and image handler
  void dispose() {
    tanggalTanamController.dispose();
    jenisTanamanController.dispose();
    jumlahPupukController.dispose();
    jumlahPestisidaController.dispose();
    teknikPengolahanController.dispose();
    tanggalKunjunganController.dispose();
    materiPenyuluhanController.dispose();
    kritikDanSaranController.dispose();
    deskripsiKendalaController.dispose();
    tanggalPanenController.dispose();
    totalPanenController.dispose(); // FIXED: dispose correct controller
    kualitasHasilController.dispose();
    deskripsiCatatanController.dispose();

    imageHandler.dispose();
  }
}