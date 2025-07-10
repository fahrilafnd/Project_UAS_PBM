import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:projek_uas/screen/KebunSaya/detailLahan.dart';
import 'package:projek_uas/screen/KebunSaya/DetailLahan/detail_add_lahan.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';

class MappingPage extends StatefulWidget {
  final int? idLahan;
  const MappingPage({super.key, this.idLahan});

  @override
  State<MappingPage> createState() => _MappingPageState();
}

class _MappingPageState extends State<MappingPage> {
  List<Map<String, dynamic>> lahanList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLahan();
  }

  Future<void> fetchLahan() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || JwtDecoder.isExpired(token)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Token tidak valid")));
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.43.143:5042/api/Laporan/lahan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          lahanList = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kesalahan saat mengambil data: $e")),
      );
    }
  }

  Future<Map<String, dynamic>?> cekLaporanLahan(int idLahan) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || JwtDecoder.isExpired(token)) {
      return null;
    }

    try {
      // Cek apakah ada laporan untuk lahan ini
      final response = await http.get(
        Uri.parse('http://192.168.43.143:5042/api/Laporan/laporan/$idLahan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Jika ada data laporan, hitung jumlah detail laporan
        int totalLaporan = 0;
        if (data != null && data is Map) {
          // Hitung total item laporan
          if (data['hasilPanen'] != null && data['hasilPanen'] is List) {
            totalLaporan += (data['hasilPanen'] as List).length;
          }
          if (data['musimTanam'] != null && data['musimTanam'] is List) {
            totalLaporan += (data['musimTanam'] as List).length;
          }
          if (data['pendampingan'] != null && data['pendampingan'] is List) {
            totalLaporan += (data['pendampingan'] as List).length;
          }
          if (data['kendala'] != null && data['kendala'] is List) {
            totalLaporan += (data['kendala'] as List).length;
          }
          if (data['catatan'] != null && data['catatan'] is List) {
            totalLaporan += (data['catatan'] as List).length;
          }
          if (data['inputProduksi'] != null && data['inputProduksi'] is List) {
            totalLaporan += (data['inputProduksi'] as List).length;
          }
          if (data['gambar'] != null && data['gambar'] is List) {
            totalLaporan += (data['gambar'] as List).length;
          }
        }

        return {
          'adaLaporan': totalLaporan > 0,
          'jumlahLaporan': totalLaporan,
          'data': data
        };
      } else {
        // Tidak ada laporan untuk lahan ini
        return {
          'adaLaporan': false,
          'jumlahLaporan': 0,
          'data': null
        };
      }
    } catch (e) {
      // Error saat mengecek laporan, anggap tidak ada laporan
      return {
        'adaLaporan': false,
        'jumlahLaporan': 0,
        'data': null
      };
    }
  }

  Future<void> hapusLahan(int idLahan) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || JwtDecoder.isExpired(token)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token tidak valid")),
      );
      return;
    }

    try {
      // Tampilkan loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Gunakan endpoint delete lahan yang sudah dibuat
      // Endpoint ini akan menghapus lahan beserta semua laporan terkait
      final response = await http.delete(
        Uri.parse('http://192.168.43.143:5042/api/Laporan/lahan/$idLahan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Tutup loading indicator
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Tampilkan pesan sukses dengan informasi jumlah laporan yang terhapus
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Lahan berhasil dihapus',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh data setelah hapus
        fetchLahan();
      } else if (response.statusCode == 404) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lahan tidak ditemukan'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              responseData['message'] ?? 'Gagal menghapus lahan: ${response.statusCode}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Tutup loading indicator jika masih terbuka
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Kesalahan saat menghapus lahan: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void showDeleteConfirmation(int idLahan, String namaLahan) async {
    // Tampilkan loading sementara saat mengecek laporan
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text("Mengecek data laporan..."),
          ],
        ),
      ),
    );

    // Cek dulu apakah ada laporan untuk menentukan pesan konfirmasi
    final laporanInfo = await cekLaporanLahan(idLahan);
    
    // Tutup loading dialog
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    if (laporanInfo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mengecek data laporan"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bool adaLaporan = laporanInfo['adaLaporan'] ?? false;
    final int jumlahLaporan = laporanInfo['jumlahLaporan'] ?? 0;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black, fontSize: 16),
            children: [
              const TextSpan(text: "Apakah Anda yakin ingin menghapus lahan "),
              TextSpan(
                text: namaLahan,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: "?\n\n"),
              if (adaLaporan) ...[
                const TextSpan(
                  text: "⚠️ Peringatan: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                TextSpan(
                  text: "Lahan ini memiliki $jumlahLaporan data laporan terkait. ",
                  style: const TextStyle(color: Colors.red),
                ),
                const TextSpan(
                  text: "Semua data laporan akan ikut terhapus dan tidak dapat dikembalikan.",
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                ),
              ] else ...[
                const TextSpan(
                  text: "ℹ️ Info: ",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const TextSpan(
                  text: "Lahan ini tidak memiliki laporan terkait, hanya data lahan yang akan dihapus.",
                  style: TextStyle(color: Colors.blue),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              hapusLahan(idLahan);
            },
            child: const Text("Hapus"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Daftar Lahan",
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : lahanList.isEmpty
              ? const Center(child: Text("Belum ada lahan ditambahkan."))
              : ListView.builder(
                  itemCount: lahanList.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final lahan = lahanList[index];
                    final title =
                        '${lahan['nama_lahan'] ?? 'Nama Tidak Ada'}, ${lahan['koordinat'] ?? 'Koordinat Tidak Ada'}';
                    final desc = '${lahan['luas_lahan']} ${lahan['satuan_luas']}';
                    final imageUrl = lahan['polygon_img'];
                    final idLahan = lahan['id_lahan']; // Gunakan id_lahan yang asli
                    final namaLahan = lahan['nama_lahan'] ?? 'Lahan Tidak Dikenal';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(128, 128, 128, 0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Gambar peta polygon
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    height: 160,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(
                                      height: 160,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  )
                                : Container(
                                    height: 160,
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 50,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                          ),
                          // Info lahan
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            title: Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              desc,
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tombol buka detail
                                IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailLahan(
                                          title: title,
                                          imageUrl: imageUrl,
                                          idLahan: lahan['id_lahan'],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Tombol hapus
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    showDeleteConfirmation(idLahan, namaLahan);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DetailTambahLahan()),
          );
        },
        backgroundColor: const Color(0xFFC9E5BA),
        shape: const CircleBorder(),
        elevation: 0,
        highlightElevation: 0,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}