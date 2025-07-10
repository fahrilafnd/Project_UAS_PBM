import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projek_uas/providers/tips_provider.dart';

class DetailTips extends StatelessWidget {
  final Map<String, dynamic> tip;

  const DetailTips({
    super.key,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TipsProvider>(
      builder: (context, tipsProvider, child) {
        final String imageUrl = tip['gambar']?.toString() ?? '';
        final String judul = tip['judul']?.toString() ?? 'Tips Tanpa Judul';
        final String deskripsi = tip['deskripsi']?.toString() ?? 'Tidak ada deskripsi';
        final String tanggal = tipsProvider.formatTanggal(tip['tanggal_tips']?.toString());
        final String username = tip['username']?.toString() ?? 'Admin';

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Detail Tips',
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar tips
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                  ),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 220,
                              color: Colors.grey[300],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image_not_supported,
                                    size: 64,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Gambar tidak dapat dimuat',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: 220,
                              color: Colors.grey[300],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Memuat gambar...',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: double.infinity,
                          height: 220,
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.article,
                                size: 64,
                                color: Colors.grey[500],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tidak ada gambar',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul
                      Text(
                        judul,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Info tanggal dan penulis
                      Row(
                        children: [
                          // Tanggal
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.black.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tanggal,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          // Penulis
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.black.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                username,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Deskripsi lengkap
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          deskripsi,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black.withOpacity(0.8),
                            height: 1.6,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Info tambahan (jika ada)
                      if (tip['id_tips'] != null) ...[
                        Divider(color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'ID Tips: ${tip['id_tips']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}