// import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class PengaturanScreen extends StatefulWidget {
  const PengaturanScreen({super.key});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  String _nama = '';
  String _email = '';
  final String _idUser = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadNamaDariLocal();
  }

  Future<void> loadNamaDariLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || JwtDecoder.isExpired(token)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token tidak tersedia atau kedaluwarsa")),
      );
      return;
    }

    final decodedToken = JwtDecoder.decode(token);
    final email =
        decodedToken['email'] ??
        decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] ??
        '';
    final displayName = prefs.getString('display_name') ?? '';

    setState(() {
      _email = email;
      _nama =
          displayName.isEmpty
              ? decodedToken['username'] ??
                  decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] ??
                  'User'
              : displayName;
      _loading = false;
    });
  }

  void _showEditProfil() {
    final TextEditingController namaController = TextEditingController(
      text: _nama,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: namaController,
                      decoration: const InputDecoration(labelText: 'Nama'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString(
                          'display_name',
                          namaController.text,
                        );

                        setState(() => _nama = namaController.text);
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Nama profil diperbarui (Hanya di aplikasi)",
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.save),
                      label: const Text("Simpan"),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // void _konfirmasiHapusAkun() {
  //   showDialog(
  //     context: context,
  //     builder:
  //         (_) => AlertDialog(
  //           title: const Text("Hapus Akun"),
  //           content: const Text("Apakah Anda yakin ingin menghapus akun?"),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context),
  //               child: const Text("Batal"),
  //             ),
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.pop(context);
  //                 ScaffoldMessenger.of(context).showSnackBar(
  //                   const SnackBar(content: Text("Akun telah dihapus")),
  //                 );
  //                 // Arahkan ke halaman login jika perlu
  //               },
  //               child: const Text("Hapus", style: TextStyle(color: Colors.red)),
  //             ),
  //           ],
  //         ),
  //   );
  //}

  Widget _buildItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green,
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pengaturan")),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                children: [
                  _buildItem(Icons.settings, "Edit Profil", _showEditProfil),
                  // _buildItem(Icons.delete, "Hapus Akun", _konfirmasiHapusAkun),
                ],
              ),
    );
  }
}
