import 'dart:io';
import 'package:flutter/material.dart';

class ImageWidgets {
  static const int maxImages = 5;
  
  // Build main image section
  static Widget buildImageSection({
    required int totalImages,
    required List<String> existingImageUrls,
    required List<File> selectedImages,
    required bool isUploadingImages,
    required VoidCallback onAddImagePressed,
    required Function(int index, {bool isExisting}) onRemoveImage,
    required Function(dynamic image, {bool isNetwork}) onShowFullImage,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Foto Laporan (Opsional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '$totalImages/$maxImages',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (isUploadingImages)
              _buildUploadingIndicator()
            else if (totalImages > 0)
              _buildImageGrid(
                totalImages: totalImages,
                existingImageUrls: existingImageUrls,
                selectedImages: selectedImages,
                onAddImagePressed: onAddImagePressed,
                onRemoveImage: onRemoveImage,
                onShowFullImage: onShowFullImage,
              )
            else
              _buildEmptyState(onAddImagePressed),
          ],
        ),
      ),
    );
  }
  
  // Build uploading indicator
  static Widget _buildUploadingIndicator() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('Mengupload gambar...'),
          ],
        ),
      ),
    );
  }
  
  // Build image grid
  static Widget _buildImageGrid({
    required int totalImages,
    required List<String> existingImageUrls,
    required List<File> selectedImages,
    required VoidCallback onAddImagePressed,
    required Function(int index, {bool isExisting}) onRemoveImage,
    required Function(dynamic image, {bool isNetwork}) onShowFullImage,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: totalImages + (totalImages < maxImages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < existingImageUrls.length) {
          // Existing images
          return buildImageThumbnail(
            existingImageUrls[index],
            index,
            isNetwork: true,
            isExisting: true,
            onRemove: onRemoveImage,
            onTap: onShowFullImage,
          );
        } else if (index < totalImages) {
          // New selected images
          final newImageIndex = index - existingImageUrls.length;
          return buildImageThumbnail(
            selectedImages[newImageIndex],
            newImageIndex,
            isNetwork: false,
            isExisting: false,
            onRemove: onRemoveImage,
            onTap: onShowFullImage,
          );
        } else {
          // Add button
          return buildAddImageButton(onAddImagePressed);
        }
      },
    );
  }
  
  // Build empty state
  static Widget _buildEmptyState(VoidCallback onAddImagePressed) {
    return GestureDetector(
      onTap: onAddImagePressed,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Tap untuk menambahkan foto',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Text(
              '(Opsional)',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Build image thumbnail
  static Widget buildImageThumbnail(
    dynamic image,
    int index, {
    required bool isNetwork,
    required bool isExisting,
    required Function(int index, {bool isExisting}) onRemove,
    required Function(dynamic image, {bool isNetwork}) onTap,
  }) {
    return GestureDetector(
      onTap: () => onTap(image, isNetwork: isNetwork),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isNetwork
                  ? Image.network(
                      image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        );
                      },
                    )
                  : Image.file(
                      image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onRemove(index, isExisting: isExisting),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build add image button
  static Widget buildAddImageButton(VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[300]!,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 24,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                'Tambah',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Show full image dialog
  static void showFullImage(
    BuildContext context,
    dynamic image, {
    bool isNetwork = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: isNetwork
                  ? Image.network(
                      image,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            'Gagal memuat gambar',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    )
                  : Image.file(
                      image,
                      fit: BoxFit.contain,
                    ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}