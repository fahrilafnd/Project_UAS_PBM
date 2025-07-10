import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projek_uas/screen/admin/admin_detail/detail_add_tips.dart';
import 'package:projek_uas/providers/tips_provider.dart';

class AddTipsPage extends StatefulWidget {
  const AddTipsPage({super.key});

  @override
  State<AddTipsPage> createState() => _AddTipsPageState();
}

class _AddTipsPageState extends State<AddTipsPage> {
  @override
  void initState() {
    super.initState();
    // Fetch tips data when page loads and ensure token sync
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
      
      // Ensure sync with AuthProvider before fetching data
      await tipsProvider.ensureSyncWithAuthProvider();
      
      // Check if user is logged in before fetching
      final isLoggedIn = await tipsProvider.isLoggedIn();
      if (isLoggedIn) {
        tipsProvider.fetchAllTips();
      } else {
        // Handle case where user is not logged in
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi telah berakhir. Silakan login kembali.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
        elevation: 0,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 32,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Pocketfarm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF999999),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () async {
              final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
              
              // Ensure token sync before refresh
              await tipsProvider.ensureSyncWithAuthProvider();
              
              // Check if still logged in
              final isLoggedIn = await tipsProvider.isLoggedIn();
              if (isLoggedIn) {
                tipsProvider.refresh();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sesi telah berakhir. Silakan login kembali.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: Consumer<TipsProvider>(
        builder: (context, tipsProvider, child) {
          if (tipsProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            );
          }

          if (tipsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi Kesalahan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      tipsProvider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[400],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      tipsProvider.clearError();
                      
                      // Ensure token sync before retry
                      await tipsProvider.ensureSyncWithAuthProvider();
                      
                      final isLoggedIn = await tipsProvider.isLoggedIn();
                      if (isLoggedIn) {
                        tipsProvider.refresh();
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sesi telah berakhir. Silakan login kembali.'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          if (tipsProvider.isEmpty) {
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
                    'Belum Ada Tips',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tambahkan tips pertama dengan menekan tombol +',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Ensure token sync before refresh
              await tipsProvider.ensureSyncWithAuthProvider();
              
              final isLoggedIn = await tipsProvider.isLoggedIn();
              if (isLoggedIn) {
                return tipsProvider.refresh();
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sesi telah berakhir. Silakan login kembali.'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            color: Colors.green,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tipsProvider.tips.length,
              itemBuilder: (context, index) {
                final tip = tipsProvider.tips[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        onPressed: () async {
          final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
          
          // Ensure token sync and check login status before navigation
          await tipsProvider.ensureSyncWithAuthProvider();
          
          final isLoggedIn = await tipsProvider.isLoggedIn();
          if (!isLoggedIn) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sesi telah berakhir. Silakan login kembali.'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DetailAddTipsPage(),
            ),
          );
          
          // Refresh data if tip was added successfully
          if (result == true) {
            // Ensure sync again after returning from add page
            await tipsProvider.ensureSyncWithAuthProvider();
            tipsProvider.refresh();
          }
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTipsCard({
    required BuildContext context,
    required Map<String, dynamic> tip,
    required TipsProvider tipsProvider,
  }) {
    final String imageUrl = tip['gambar']?.toString() ?? '';
    final String title = tip['judul']?.toString() ?? 'Judul tidak tersedia';
    final String description = tip['deskripsi']?.toString() ?? 'Deskripsi tidak tersedia';
    final String formattedDate = tipsProvider.formatTanggal(tip['tanggal_tips']?.toString());
    final String author = tip['username']?.toString() ?? 'Admin';
    final int tipId = tip['id_tips'] ?? 0;

    return Card(
      color: const Color(0xFFF9F9F9),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
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
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Gambar tidak dapat dimuat',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tidak ada gambar',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          
          // Content section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date and author info
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      author,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Action buttons
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          // Check login status before allowing edit
                          await tipsProvider.ensureSyncWithAuthProvider();
                          
                          final isLoggedIn = await tipsProvider.isLoggedIn();
                          if (!isLoggedIn) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sesi telah berakhir. Silakan login kembali.'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            return;
                          }

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailAddTipsPage(
                                isEdit: true,
                                tipData: tip,
                              ),
                            ),
                          );
                          
                          // Refresh data if tip was updated successfully
                          if (result == true) {
                            await tipsProvider.ensureSyncWithAuthProvider();
                            tipsProvider.refresh();
                          }
                        },
                        tooltip: 'Edit Tips',
                      ),
                      
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Check login status before allowing delete
                          await tipsProvider.ensureSyncWithAuthProvider();
                          
                          final isLoggedIn = await tipsProvider.isLoggedIn();
                          if (!isLoggedIn) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Sesi telah berakhir. Silakan login kembali.'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                            return;
                          }

                          _showDeleteConfirmation(context, tipId, title, tipsProvider);
                        },
                        tooltip: 'Hapus Tips',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    int tipId,
    String title,
    TipsProvider tipsProvider,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Apakah Anda yakin ingin menghapus tips ini?'),
              const SizedBox(height: 8),
              Text(
                'Tips: "$title"',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tindakan ini tidak dapat dibatalkan.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteTip(context, tipId, tipsProvider);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTip(
    BuildContext context,
    int tipId,
    TipsProvider tipsProvider,
  ) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      ),
    );

    try {
      // Ensure token sync before attempting delete
      await tipsProvider.ensureSyncWithAuthProvider();
      
      // Use the TipsProvider's deleteTip method which handles token management automatically
      final success = await tipsProvider.deleteTip(idTips: tipId);

      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();

      if (success) {
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tips berhasil dihapus'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Show error message - error is already set in the provider
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tipsProvider.error ?? 'Gagal menghapus tips'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) Navigator.of(context).pop();
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}