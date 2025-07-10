import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projek_uas/screen/Akun/pengaturan_screen.dart';
import 'package:projek_uas/screen/Akun/tentang_screen.dart';
import 'package:projek_uas/providers/auth_provider.dart';
import '../Akun/profile_menu_item.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  String _displayName = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh saat kembali dari pengaturan
    Future.delayed(Duration.zero, () => _loadDisplayName());
  }

  Future<void> _loadDisplayName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && !JwtDecoder.isExpired(token)) {
        final decoded = JwtDecoder.decode(token);
        final defaultName =
            decoded['username'] ??
            decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
            'User';
        final customName = prefs.getString('display_name') ?? defaultName;

        if (mounted) {
          setState(() {
            _displayName = customName;
            _isLoading = false;
          });
        }
      } else {
        // Token expired atau tidak ada, redirect ke login
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (_) => false,
          );
        }
      }
    } catch (e) {
      print('Error loading display name: $e');
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (_) => false,
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Keluar"),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      // Gunakan AuthProvider jika tersedia, atau fallback ke manual
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.logout();
      } catch (e) {
        // Fallback manual logout
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('display_name');
      }
      
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Profil",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              _displayName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 30),
            ProfileMenuItem(
              icon: Icons.info,
              label: "Tentang",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TentangScreen()),
                );
              },
            ),
            ProfileMenuItem(
              icon: Icons.settings,
              label: "Pengaturan",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PengaturanScreen()),
                );
              },
            ),
            ProfileMenuItem(
              icon: Icons.logout,
              label: "Keluar",
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }
}