import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projek_uas/providers/tips_provider.dart';
import 'package:projek_uas/screen/admin/add_tips.dart';
import 'package:projek_uas/screen/admin/admin_profile.dart';
import 'package:projek_uas/screen/admin/tips_management.dart'; // Page baru untuk manajemen tips

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Initialize pages
    _pages = [
      const TipsManagementPage(), // Halaman untuk melihat semua tips
      const AddTipsPage(), // Halaman untuk menambah tips
      const AdminProfilePage(), // Halaman profil admin
    ];

    // Load tips data saat pertama kali masuk
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final tipsProvider = Provider.of<TipsProvider>(context, listen: false);

    try {
      await tipsProvider.fetchAllTips();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data tips: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Refresh data tips saat masuk ke halaman management
    if (index == 0) {
      final tipsProvider = Provider.of<TipsProvider>(context, listen: false);
      tipsProvider.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TipsProvider>(
        builder: (context, tipsProvider, child) {
          // Show loading indicator if needed
          if (tipsProvider.isLoading && _selectedIndex == 0) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
            );
          }

          // Show error if any
          if (tipsProvider.error != null && _selectedIndex == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tipsProvider.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => tipsProvider.refresh(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          return _pages[_selectedIndex];
        },
      ),
      bottomNavigationBar: Consumer<TipsProvider>(
        builder: (context, tipsProvider, child) {
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: const Color(0xFFF9F9F9),
            selectedItemColor: const Color(0xFF4CAF50),
            unselectedItemColor: Colors.grey[600],
            items: [
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    Image.asset(
                      _selectedIndex == 0
                          ? 'assets/Hasil Laporan_hijau.png'
                          : 'assets/Hasil Laporan.png',
                      width: 20,
                      height: 20,
                    ),
                    // Badge untuk menampilkan jumlah tips
                    if (tipsProvider.totalTips > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${tipsProvider.totalTips}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Tips (${tipsProvider.totalTips})',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  _selectedIndex == 1
                      ? 'assets/Kebun Saya_hijau.png'
                      : 'assets/Kebun Saya.png',
                  width: 20,
                  height: 20,
                ),
                label: 'Tambah Tips',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  _selectedIndex == 2
                      ? 'assets/Akun_hijau.png'
                      : 'assets/Akun.png',
                  width: 20,
                  height: 20,
                ),
                label: 'Admin',
              ),
            ],
          );
        },
      ),
      // Floating Action Button untuk refresh data
      floatingActionButton:
          _selectedIndex == 0
              ? Consumer<TipsProvider>(
                builder: (context, tipsProvider, child) {
                  return FloatingActionButton(
                    onPressed:
                        tipsProvider.isLoading
                            ? null
                            : () {
                              tipsProvider.refresh();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Memperbarui data tips...'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            },
                    backgroundColor: const Color(0xFF4CAF50),
                    child:
                        tipsProvider.isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : const Icon(Icons.refresh, color: Colors.white),
                  );
                },
              )
              : null,
    );
  }
}

// Extension untuk menambahkan fungsi helper
extension AdminPageExtension on _AdminPageState {
  void showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
