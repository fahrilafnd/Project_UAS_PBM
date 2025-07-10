import 'package:flutter/material.dart';

class TentangScreen extends StatelessWidget {
  const TentangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tentang")),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            "PocketFarm adalah aplikasi digital yang dirancang khusus untuk membantu Petugas Penyuluh Pertanian (PPL) dalam mendampingi petani secara efektif dan berbasis data. "
            "Melalui fitur Pemetaan Lahan, PPL dapat membuat peta digital kebun atau lahan petani lengkap dengan batas wilayah, nama, dan jenis tanaman. "
            "Aplikasi ini juga terintegrasi dengan informasi cuaca lokal, sehingga setiap lahan yang dipantau dapat disesuaikan pengelolaannya berdasarkan kondisi cuaca terkini.\n\n"
            "Untuk mendukung aktivitas harian PPL, tersedia fitur Manajemen Tanaman dan Lahan, mulai dari pencatatan tanaman, jadwal penyiraman, pemupukan, hingga panen. "
            "Setiap aktivitas bisa didokumentasikan secara berkala melalui foto langsung dari lapangan. "
            "Selain itu, PocketFarm juga menyediakan fitur Analisis Hasil Panen dan Produktivitas, serta laporan kegiatan dan ekspor data sebagai dokumentasi resmi ke dinas atau lembaga terkait. "
            "Dengan PocketFarm, proses penyuluhan menjadi lebih modern, terstruktur, dan tepat sasaran.",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.justify,
          ),
        ),
      ),
    );
  }
}
