// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:projek_uas/screen/profile/bantuan_screen.dart';
// import 'package:projek_uas/screen/profile/masukan_screen.dart';
import 'package:projek_uas/screen/Akun/pengaturan_screen.dart';
import 'package:projek_uas/screen/Akun/tentang_screen.dart';
import 'profile_menu_item.dart';

class Akun extends StatefulWidget {
  const Akun({super.key});

  @override
  State<Akun> createState() => _AkunState();
}

class _AkunState extends State<Akun> {
  String _displayName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Saat kembali dari pengaturan
    Future.delayed(Duration.zero, () => _loadDisplayName());
  }

  Future<void> _loadDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      final decoded = JwtDecoder.decode(token);
      final defaultName =
          decoded['username'] ??
          decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
          'User';
      final customName = prefs.getString('display_name') ?? defaultName;

      setState(() {
        _displayName = customName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
            // ProfileMenuItem(
            //   icon: Icons.help,
            //   label: "Bantuan",
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (_) => const BantuanScreen()),
            //     );
            //   },
            // ),
            // ProfileMenuItem(
            //   icon: Icons.feedback,
            //   label: "Masukan",
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (_) => const MasukanScreen()),
            //     );
            //   },
            // ),
            ProfileMenuItem(
              icon: Icons.logout,
              label: "Keluar",
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => AlertDialog(
                        title: const Text("Keluar"),
                        content: const Text("Apakah Anda yakin ingin keluar?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Batal"),
                          ),
                          TextButton(
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.remove('token');
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (_) => false,
                              );
                            },
                            child: const Text("Keluar"),
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
