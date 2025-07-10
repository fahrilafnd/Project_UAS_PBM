import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

// Extension untuk safe operations
extension FirstOrNullExt<T> on List<T> {
  T? firstOrNull() => isEmpty ? null : first;
}

// Mixin untuk safe state management
mixin SafeState<T extends StatefulWidget> on State<T> {
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }
}

class ImageHandlerService {
  static const int maxImages = 5;
  static const String cloudName = 'dxwzt2mhr';
  static const String uploadPreset = 'PocketFarm_Laporan';

  final ImagePicker _picker = ImagePicker();

  // Context untuk operations
  final BuildContext context;

  // Callback untuk update UI
  final VoidCallback? onStateChanged;

  // State variables
  final List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  List<String> _uploadedImageUrls = [];
  bool _isUploadingImages = false;
  bool _isDisposed = false; // Flag untuk tracking disposal
  bool _isProcessing = false; // Flag untuk prevent multiple operations

  ImageHandlerService({required this.context, this.onStateChanged});

  // Getters
  List<File> get selectedImages => List.unmodifiable(_selectedImages);
  List<String> get existingImageUrls => List.unmodifiable(_existingImageUrls);
  List<String> get uploadedImageUrls => List.unmodifiable(_uploadedImageUrls);
  bool get isUploadingImages => _isUploadingImages;
  bool get isDisposed => _isDisposed;
  bool get isProcessing => _isProcessing;
  int get totalImages => _selectedImages.length + _existingImageUrls.length;
  bool get hasImages => totalImages > 0;
  bool get hasSelectedImages => _selectedImages.isNotEmpty;
  bool get hasExistingImages => _existingImageUrls.isNotEmpty;

  // Dispose method
  void dispose() {
    _isDisposed = true;
    _selectedImages.clear();
    _existingImageUrls.clear();
    _uploadedImageUrls.clear();
  }

  // Safe setState helper
  void _safeNotifyStateChanged() {
    if (!_isDisposed && context.mounted) {
      onStateChanged?.call();
    }
  }

  // Initialize dengan data yang sudah ada
  void initializeWithExistingImages(List<String> existingUrls) {
    if (_isDisposed) return;

    _existingImageUrls = List<String>.from(existingUrls.where(_isValidUrl));
    _safeNotifyStateChanged();

    print('=== IMAGE HANDLER INIT ===');
    print('Initialized with ${_existingImageUrls.length} existing images');
    print('URLs: $_existingImageUrls');
    print('========================');
  }

  // Method untuk mengeset uploaded URLs
  void setUploadedUrls(List<String> urls) {
    if (_isDisposed) return;

    _uploadedImageUrls = List<String>.from(urls.where(_isValidUrl));
    _safeNotifyStateChanged();
  }

  // Get all image URLs (existing + uploaded)
  List<String> getAllImageUrls() {
    List<String> allUrls = [];
    allUrls.addAll(_existingImageUrls);
    allUrls.addAll(_uploadedImageUrls);
    return allUrls;
  }

  // Clear uploaded images (untuk reset state)
  void clearUploadedImages() {
    if (_isDisposed) return;

    _uploadedImageUrls.clear();
    _safeNotifyStateChanged();
  }

  // Show image source dialog dengan improved UI
  void showImageSourceDialog() {
    if (_isDisposed || !context.mounted || _isProcessing) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Pilih Sumber Gambar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.photo_library,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  title: const Text("Pilih dari Galeri"),
                  subtitle: const Text("Pilih beberapa gambar sekaligus"),
                  onTap: () {
                    Navigator.pop(context);
                    pickMultipleImages(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.green.shade600),
                  ),
                  title: const Text("Ambil dengan Kamera"),
                  subtitle: const Text("Foto langsung dengan kamera"),
                  onTap: () {
                    Navigator.pop(context);
                    pickImage(ImageSource.camera);
                  },
                ),
                if (hasImages) ...[
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.delete, color: Colors.red.shade600),
                    ),
                    title: const Text(
                      "Hapus Semua Gambar",
                      style: TextStyle(color: Colors.red),
                    ),
                    subtitle: Text("$totalImages gambar akan dihapus"),
                    onTap: () {
                      Navigator.pop(context);
                      _showRemoveAllConfirmationDialog();
                    },
                  ),
                ],
              ],
            ),
          ),
    );
  }

  // Pick multiple images from gallery dengan improved error handling
  Future<void> pickMultipleImages(ImageSource source) async {
    if (_isDisposed || !context.mounted || _isProcessing) return;

    _isProcessing = true;
    _safeNotifyStateChanged();

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      // Check if disposed after async operation
      if (_isDisposed || !context.mounted) return;

      if (pickedFiles.isNotEmpty) {
        final totalAfterAdd = totalImages + pickedFiles.length;

        if (totalAfterAdd > maxImages) {
          final availableSlots = maxImages - totalImages;
          if (availableSlots > 0) {
            _showSnackBar(
              'Hanya dapat menambah $availableSlots gambar lagi (maksimal $maxImages)',
              Colors.orange,
            );
            // Ambil hanya gambar yang muat
            final filesToAdd = pickedFiles.take(availableSlots);
            _selectedImages.addAll(filesToAdd.map((file) => File(file.path)));
          } else {
            _showSnackBar('Maksimal $maxImages gambar', Colors.red);
          }
        } else {
          _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
          _showSnackBar(
            '${pickedFiles.length} gambar berhasil ditambahkan',
            Colors.green,
          );
        }

        _safeNotifyStateChanged();
      }
    } catch (e) {
      if (context.mounted && !_isDisposed) {
        print('Error picking images: $e');
        _showSnackBar('Gagal memilih gambar: $e', Colors.red);
      }
    } finally {
      _isProcessing = false;
      _safeNotifyStateChanged();
    }
  }

  // Pick single image dengan improved error handling
  Future<void> pickImage(ImageSource source) async {
    if (_isDisposed || !context.mounted || _isProcessing) return;

    _isProcessing = true;
    _safeNotifyStateChanged();

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      // Check if disposed after async operation
      if (_isDisposed || !context.mounted) return;

      if (pickedFile != null) {
        if (totalImages >= maxImages) {
          _showSnackBar('Maksimal $maxImages gambar', Colors.red);
          return;
        }

        _selectedImages.add(File(pickedFile.path));
        _showSnackBar('Gambar berhasil ditambahkan', Colors.green);
        _safeNotifyStateChanged();
      }
    } catch (e) {
      if (context.mounted && !_isDisposed) {
        print('Error picking image: $e');
        _showSnackBar('Gagal mengambil gambar: $e', Colors.red);
      }
    } finally {
      _isProcessing = false;
      _safeNotifyStateChanged();
    }
  }

  // Remove all images dengan confirmation
  void _showRemoveAllConfirmationDialog() {
    if (_isDisposed || !context.mounted) return;

    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
            'Apakah Anda yakin ingin menghapus semua $totalImages gambar? '
            'Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                removeAllImages();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus Semua'),
            ),
          ],
        );
      },
    );
  }

  // Remove all images
  void removeAllImages() {
    if (_isDisposed) return;

    final totalRemoved = totalImages;
    _selectedImages.clear();
    _existingImageUrls.clear();
    _uploadedImageUrls.clear();

    _showSnackBar('$totalRemoved gambar berhasil dihapus', Colors.green);
    _safeNotifyStateChanged();
  }

  // Remove specific image dengan improved validation
  void removeImage(int index, {bool isExisting = false}) {
    if (_isDisposed) return;

    bool removed = false;

    if (isExisting) {
      if (index >= 0 && index < _existingImageUrls.length) {
        _existingImageUrls.removeAt(index);
        removed = true;
      }
    } else {
      if (index >= 0 && index < _selectedImages.length) {
        _selectedImages.removeAt(index);
        removed = true;
      }
    }

    if (removed) {
      _showSnackBar('Gambar berhasil dihapus', Colors.green);
      _safeNotifyStateChanged();
    }
  }

  // Upload multiple images to Cloudinary dengan improved error handling dan progress
  Future<List<String>> uploadMultipleToCloudinary({
    VoidCallback? onUploadStart,
    Function(int current, int total)? onProgress,
    VoidCallback? onUploadComplete,
  }) async {
    if (_selectedImages.isEmpty || _isDisposed || !context.mounted) return [];

    _isUploadingImages = true;
    _safeNotifyStateChanged();
    onUploadStart?.call();

    List<String> uploadedUrls = [];

    try {
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      for (int i = 0; i < _selectedImages.length; i++) {
        // Check if disposed during loop
        if (_isDisposed || !context.mounted) break;

        onProgress?.call(i + 1, _selectedImages.length);

        final imageFile = _selectedImages[i];

        try {
          Uint8List imageBytes = await imageFile.readAsBytes();

          // Check if disposed after async operation
          if (_isDisposed || !context.mounted) break;

          final request =
              http.MultipartRequest('POST', url)
                ..fields['upload_preset'] = uploadPreset
                ..fields['resource_type'] = 'image'
                ..fields['folder'] = 'laporan'
                ..files.add(
                  http.MultipartFile.fromBytes(
                    'file',
                    imageBytes,
                    filename:
                        'laporan_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
                    contentType: MediaType('image', 'jpeg'),
                  ),
                );

          final response = await request.send();

          // Check if disposed after async operation
          if (_isDisposed || !context.mounted) break;

          if (response.statusCode == 200) {
            final res = await http.Response.fromStream(response);
            if (_isDisposed || !context.mounted) break;

            final data = json.decode(res.body);
            final imageUrl = data['secure_url'] as String;

            if (_isValidUrl(imageUrl)) {
              uploadedUrls.add(imageUrl);
            }
          } else {
            final res = await http.Response.fromStream(response);
            print(
              'Cloudinary upload failed for image $i: ${response.statusCode}',
            );
            print('Response body: ${res.body}');

            if (context.mounted && !_isDisposed) {
              _showSnackBar('Gagal mengupload gambar ${i + 1}', Colors.orange);
            }
          }
        } catch (e) {
          print('Error uploading image $i: $e');
          if (context.mounted && !_isDisposed) {
            _showSnackBar('Error pada gambar ${i + 1}: $e', Colors.orange);
          }
        }
      }

      // Simpan uploaded URLs
      if (!_isDisposed) {
        _uploadedImageUrls = uploadedUrls;

        if (uploadedUrls.isNotEmpty && context.mounted) {
          _showSnackBar(
            '${uploadedUrls.length} gambar berhasil diupload',
            Colors.green,
          );
        }
      }

      return uploadedUrls;
    } catch (e) {
      if (context.mounted && !_isDisposed) {
        print('Cloudinary upload error: $e');
        _showSnackBar('Error uploading images: $e', Colors.red);
      }
      return [];
    } finally {
      if (!_isDisposed) {
        _isUploadingImages = false;
        _safeNotifyStateChanged();
        onUploadComplete?.call();
      }
    }
  }

  // Validate image file
  Future<bool> validateImageFile(File imageFile) async {
    try {
      // Check file size (max 5MB)
      final fileSize = await imageFile.length();
      if (fileSize > 5 * 1024 * 1024) {
        if (context.mounted && !_isDisposed) {
          _showSnackBar(
            'Ukuran gambar terlalu besar (maksimal 5MB)',
            Colors.red,
          );
        }
        return false;
      }

      // Check file extension
      final extension = imageFile.path.toLowerCase().split('.').last;
      if (!['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
        if (context.mounted && !_isDisposed) {
          _showSnackBar('Format gambar tidak didukung', Colors.red);
        }
        return false;
      }

      return true;
    } catch (e) {
      print('Error validating image: $e');
      return false;
    }
  }

  // Get image summary for logging/debugging
  Map<String, dynamic> getImageSummary() {
    return {
      'selectedImages': _selectedImages.length,
      'existingImages': _existingImageUrls.length,
      'uploadedImages': _uploadedImageUrls.length,
      'totalImages': totalImages,
      'isUploading': _isUploadingImages,
      'isProcessing': _isProcessing,
      'isDisposed': _isDisposed,
      'existingUrls': _existingImageUrls,
      'uploadedUrls': _uploadedImageUrls,
    };
  }

  // Debug print method
  void debugPrintImages() {
    final summary = getImageSummary();
    print('=== IMAGE HANDLER DEBUG ===');
    summary.forEach((key, value) {
      print('$key: $value');
    });
    print('==========================');
  }

  // ===== PRIVATE HELPER METHODS =====

  // Validate URL
  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          url.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Show snackbar dengan safe check
  void _showSnackBar(String message, Color backgroundColor) {
    if (context.mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
