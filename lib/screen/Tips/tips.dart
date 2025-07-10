import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:projek_uas/screen/Tips/detail_tips.dart';
import 'package:projek_uas/providers/tips_provider.dart';

class TipsPage extends StatefulWidget {
  const TipsPage({super.key});

  @override
  State<TipsPage> createState() => _TipsPageState();
}

class _TipsPageState extends State<TipsPage> {
  @override
  void initState() {
    super.initState();
    // Fetch tips saat halaman dimuat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TipsProvider>().fetchAllTips();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        title: const Text(
          "Tips",
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<TipsProvider>().refresh();
            },
          ),
        ],
      ),
      body: Consumer<TipsProvider>(
        builder: (context, tipsProvider, child) {
          // Loading state
          if (tipsProvider.isLoading && tipsProvider.tips.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state
          if (tipsProvider.error != null && tipsProvider.tips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tipsProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      tipsProvider.fetchAllTips();
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (tipsProvider.tips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada tips yang tersedia',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          // Tips list
          return RefreshIndicator(
            onRefresh: () => tipsProvider.refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tipsProvider.tips.length,
              itemBuilder: (context, index) {
                final tip = tipsProvider.tips[index];
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == tipsProvider.tips.length - 1 ? 0 : 16,
                  ),
                  child: _buildTipsCard(
                    context: context,
                    tip: tip,
                    tipsProvider: tipsProvider,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipsCard({
    required BuildContext context,
    required Map<String, dynamic> tip,
    required TipsProvider tipsProvider,
  }) {
    final String imageUrl = tip['gambar']?.toString() ?? '';
    final String judul = tip['judul']?.toString() ?? 'Tips Tanpa Judul';
    final String deskripsi = tip['deskripsi']?.toString() ?? 'Tidak ada deskripsi';
    final String tanggal = tipsProvider.formatTanggal(tip['tanggal_tips']?.toString());
    final String username = tip['username']?.toString() ?? 'Admin';

    return Card(
      color: const Color(0xFFF9F9F9),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar tips
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
            ),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey[500],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.article,
                      size: 64,
                      color: Colors.grey[500],
                    ),
                  ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tanggal dan username
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      tanggal,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          username,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Judul
                Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Deskripsi
                Text(
                  deskripsi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Tombol detail
                Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    icon: const Icon(
                      LucideIcons.arrowUpRight,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailTips(tip: tip),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}