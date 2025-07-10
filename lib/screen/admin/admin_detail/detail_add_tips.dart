import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:projek_uas/providers/tips_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DetailAddTipsPage extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? tipData;

  const DetailAddTipsPage({
    super.key,
    this.isEdit = false,
    this.tipData,
  });

  @override
  State<DetailAddTipsPage> createState() => _DetailAddTipsPageState();
}

class _DetailAddTipsPageState extends State<DetailAddTipsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _judulController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();
  
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  // Cloudinary configuration
  static const String _cloudName = 'dxwzt2mhr';
  static const String _uploadPreset = 'PocketFarm_Tips';

  // === CONSISTENT TOKEN KEYS - SAMA DENGAN TipsProvider ===
  static const String _tokenKey = 'token'; // Main token untuk AuthProvider
  static const String _accessTokenKey = 'access_token'; // Untuk access token API
  static const String _refreshTokenKey = 'refresh_token'; // Untuk refresh token API

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.tipData != null) {
      _initializeEditData();
    }
  }

  void _initializeEditData() {
    final tipData = widget.tipData!;
    _judulController.text = tipData['judul']?.toString() ?? '';
    _deskripsiController.text = tipData['deskripsi']?.toString() ?? '';
    _existingImageUrl = tipData['gambar']?.toString();
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  // === TOKEN MANAGEMENT METHODS - KONSISTEN DENGAN TipsProvider ===
  
  /// Check if user is logged in using TipsProvider method
  Future<bool> _isUserLoggedIn() async {
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    return await tipsProvider.isLoggedIn();
  }

  /// Get valid token using TipsProvider method
  Future<String?> _getValidToken() async {
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    return await tipsProvider.getValidToken();
  }

  /// Get current user ID using TipsProvider method
  Future<int?> _getCurrentUserId() async {
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    return await tipsProvider.getCurrentUserId();
  }

  /// Ensure sync with AuthProvider using TipsProvider method
  Future<void> _ensureSyncWithAuthProvider() async {
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    await tipsProvider.ensureSyncWithAuthProvider();
  }

  /// Clear tokens using consistent keys
  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    
    // Clear additional auth data jika ada
    await prefs.remove('user_info');
    await prefs.remove('user_data');
    await prefs.remove('user_profile');
  }

  /// Upload image to Cloudinary
  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      Uint8List imageBytes = await imageFile.readAsBytes();
      
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
      );
      
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = 'tips'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageBytes,
            filename: 'tip_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );

      final response = await request.send();
      
      if (response.statusCode == 200) {
        final res = await http.Response.fromStream(response);
        final data = json.decode(res.body);
        return data['secure_url'];
      } else {
        return null;
      }
    } catch (e) {
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _existingImageUrl = null;
        });
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil gambar: $e', isError: true);
    }
  }

  Future<void> _showImageSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _existingImageUrl = null;
        });
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil gambar dari kamera: $e', isError: true);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _existingImageUrl = null;
    });
  }

  bool _hasImage() {
    return _selectedImage != null || (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);
  }

  Widget _buildImageSection() {
    return GestureDetector(
      onTap: _isUploadingImage ? null : _showImageSourceDialog,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey),
        ),
        child: _hasImage()
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedImage != null
                        ? Image.file(
                            _selectedImage!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            _existingImageUrl!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey[300],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                    Text('Gambar tidak dapat dimuat'),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  // Upload progress overlay
                  if (_isUploadingImage)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 8),
                            Text(
                              'Mengunggah gambar...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Remove button
                  if (!_isUploadingImage)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: _removeImage,
                          tooltip: 'Hapus Gambar',
                        ),
                      ),
                    ),
                  // Edit button
                  if (!_isUploadingImage)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                          onPressed: _showImageSourceDialog,
                          tooltip: 'Ganti Gambar',
                        ),
                      ),
                    ),
                ],
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo, 
                      size: 40, 
                      color: _isUploadingImage ? Colors.grey : Colors.black54,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isUploadingImage ? 'Mengunggah...' : 'Tambah Foto',
                      style: TextStyle(
                        fontSize: 16,
                        color: _isUploadingImage ? Colors.grey : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isUploadingImage ? 'Mohon tunggu' : 'Ketuk untuk menambah gambar',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isUploadingImage ? Colors.grey : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String? _validateJudul(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Judul tips tidak boleh kosong';
    }
    if (value.length > 84) {
      return 'Judul tips tidak boleh lebih dari 84 karakter';
    }
    return null;
  }

  String? _validateDeskripsi(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Deskripsi tips tidak boleh kosong';
    }
    if (value.length < 50) {
      return 'Deskripsi tips minimal 50 karakter';
    }
    return null;
  }

  /// Get the tip owner's user ID for edit mode - KONSISTEN DENGAN TipsProvider
  int? _getTipOwnerUserId() {
    if (widget.isEdit && widget.tipData != null) {
      final tipData = widget.tipData!;
      
      // Konsisten dengan field yang digunakan di TipsProvider
      if (tipData['id_users'] != null) {
        return int.tryParse(tipData['id_users'].toString());
      } else if (tipData['Id_Users'] != null) {
        return int.tryParse(tipData['Id_Users'].toString());
      } else if (tipData['user_id'] != null) {
        return int.tryParse(tipData['user_id'].toString());
      }
    }
    return null;
  }

  /// Enhanced ownership validation using TipsProvider method
  Future<bool> _validateOwnership(int tipId) async {
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
    return await tipsProvider.canUserUpdateTip(tipId);
  }

  Future<void> _submitForm() async {
    print('=== SUBMIT FORM START ===');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }

    if (_isUploadingImage) {
      _showSnackBar('Mohon tunggu hingga gambar selesai diunggah', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
      
      // === ENHANCED TOKEN VALIDATION ===
      print('=== TOKEN VALIDATION START ===');
      
      // Ensure sync with AuthProvider first
      await _ensureSyncWithAuthProvider();
      
      // Check if user is logged in using TipsProvider method
      final isLoggedInCheck = await _isUserLoggedIn();
      if (!isLoggedInCheck) {
        _showSnackBar('Sesi Anda telah berakhir. Silakan login ulang.', isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }
      print('✅ User is logged in');
      
      // Get valid token using TipsProvider method
      final validToken = await _getValidToken();
      if (validToken == null) {
        _showSnackBar('Token tidak tersedia, silakan login ulang', isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }
      print('✅ Valid token obtained');
      
      // Get current user ID using TipsProvider method
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) {
        _showSnackBar('Gagal mendapatkan informasi user. Silakan login ulang.', isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }
      print('✅ Current user ID: $currentUserId');
      
      // === OWNERSHIP VALIDATION FOR EDIT MODE ===
      if (widget.isEdit) {
        print('=== OWNERSHIP VALIDATION ===');
        
        final tipOwnerId = _getTipOwnerUserId();
        if (tipOwnerId == null) {
          _showSnackBar('Gagal mendapatkan informasi pemilik tips', isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }
        print('Tip owner ID: $tipOwnerId');

        // Double validation: local check + TipsProvider check
        if (currentUserId != tipOwnerId) {
          _showSnackBar('Anda hanya bisa mengupdate tips yang Anda buat sendiri', isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }

        // Additional validation using TipsProvider method
        final tipId = widget.tipData!['id_tips'] ?? widget.tipData!['Id_Tips'] ?? 0;
        if (tipId > 0) {
          final canUpdate = await _validateOwnership(tipId);
          if (!canUpdate) {
            _showSnackBar('Validasi kepemilikan gagal. Anda hanya bisa mengupdate tips milik Anda sendiri.', isError: true);
            setState(() {
              _isLoading = false;
            });
            return;
          }
          print('✅ Ownership validation passed');
        }
      }
      
      // === PREPARE FORM DATA ===
      final String judul = _judulController.text.trim();
      final String deskripsi = _deskripsiController.text.trim();
      final DateTime tanggalTips = DateTime.now();

      print('=== FORM DATA ===');
      print('Judul: $judul');
      print('Deskripsi length: ${deskripsi.length}');
      print('Current User ID: $currentUserId');
      print('Tanggal: $tanggalTips');

      // Validate form data using TipsProvider method
      final validationErrors = tipsProvider.validateTipData(
        judul: judul,
        deskripsi: deskripsi,
        tanggalTips: tanggalTips,
        idUsers: currentUserId,
      );
      
      if (validationErrors.isNotEmpty) {
        final firstError = validationErrors.values.first;
        if (firstError != null) {
          _showSnackBar(firstError, isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }
      print('✅ Form data validation passed');
      
      // === HANDLE IMAGE UPLOAD ===
      String? imageUrl;
      if (_selectedImage != null) {
        print('=== UPLOADING IMAGE ===');
        _showSnackBar('Mengunggah gambar ke Cloudinary...', isError: false);
        imageUrl = await _uploadToCloudinary(_selectedImage!);
        
        if (imageUrl == null) {
          _showSnackBar('Gagal mengunggah gambar ke Cloudinary', isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        _showSnackBar('Gambar berhasil diunggah', isError: false);
        print('✅ Image uploaded: $imageUrl');
      } else if (_existingImageUrl != null) {
        imageUrl = _existingImageUrl;
        print('Using existing image URL: $imageUrl');
      }
      
      // === SUBMIT FORM USING TipsProvider ===
      bool success;
      if (widget.isEdit && widget.tipData != null) {
        print('=== UPDATING TIP ===');
        final int tipId = widget.tipData!['id_tips'] ?? widget.tipData!['Id_Tips'] ?? 0;
        
        if (tipId == 0) {
          _showSnackBar('ID Tips tidak valid', isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }

        success = await tipsProvider.updateTip(
          idTips: tipId,
          judul: judul,
          deskripsi: deskripsi,
          gambar: imageUrl,
          tanggalTips: tanggalTips,
          idUsers: currentUserId,
        );
      } else {
        print('=== ADDING NEW TIP ===');
        success = await tipsProvider.addTip(
          judul: judul,
          deskripsi: deskripsi,
          gambar: imageUrl,
          tanggalTips: tanggalTips,
          idUsers: currentUserId,
        );
      }

      // === HANDLE RESULT ===
      if (success) {
        print('✅ Operation successful');
        _showSnackBar(
          widget.isEdit ? 'Tips berhasil diperbarui!' : 'Tips berhasil dipublikasikan!',
          isError: false,
        );
        
        await Future.delayed(const Duration(seconds: 1));
        
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        print('❌ Operation failed');
        final errorMessage = tipsProvider.error ?? (widget.isEdit ? 'Gagal memperbarui tips' : 'Gagal mempublikasikan tips');
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      print('❌ Exception during submit: $e');
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: isError ? 4 : 2),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_isUploadingImage) {
      _showSnackBar('Mohon tunggu hingga gambar selesai diunggah', isError: true);
      return false;
    }

    if (_judulController.text.trim().isNotEmpty || 
        _deskripsiController.text.trim().isNotEmpty || 
        _hasImage()) {
      return await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Keluar Tanpa Menyimpan?'),
          content: const Text(
            'Perubahan yang Anda buat akan hilang jika keluar sekarang.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Lanjut Edit'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Keluar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ) ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            widget.isEdit ? 'Edit Tips' : 'Tambah Tips',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        body: Consumer<TipsProvider>(
          builder: (context, tipsProvider, child) {
            return Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    // Show error message if exists
                    if (tipsProvider.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tipsProvider.error!,
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => tipsProvider.clearError(),
                            ),
                          ],
                        ),
                      ),

                    // Image Section
                    _buildImageSection(),
                    const SizedBox(height: 24),

                    // Input Judul Tips
                    const Text(
                      'Judul Tips',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _judulController,
                      validator: _validateJudul,
                      maxLength: 84,
                      enabled: !_isUploadingImage && !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Masukkan judul tips',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorMaxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input Deskripsi Tips
                    const Text(
                      'Deskripsi Tips',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _deskripsiController,
                      validator: _validateDeskripsi,
                      maxLines: 8,
                      enabled: !_isUploadingImage && !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Masukkan deskripsi tips (minimal 50 karakter)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        errorMaxLines: 2,
                        helperText: '${_deskripsiController.text.length} karakter',
                      ),
                      onChanged: (value) {
                        setState(() {}); // Rebuild to update character count
                      },
                    ),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              onPressed: (_isLoading || _isUploadingImage) ? null : _submitForm,
              child: (_isLoading || _isUploadingImage)
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isUploadingImage ? 'Mengunggah Gambar...' : 'Memproses...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      widget.isEdit ? 'Perbarui' : 'Publikasi',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}