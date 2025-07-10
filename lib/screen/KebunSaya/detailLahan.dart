import 'package:flutter/material.dart';
import 'package:projek_uas/logic/detailLahanLogic.dart';
// import 'package:projek_uas/providers/auth_provider.dart';
import 'package:provider/provider.dart';
// import 'package:projek_uas/screen/detail/detailLaporan.dart';
import 'package:projek_uas/providers/lahan_provider.dart';
import 'package:projek_uas/providers/laporan_provider.dart';

extension FirstOrNullExt<T> on List<T> {
  T? firstOrNull() => isEmpty ? null : first;
}

class DetailLahan extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final int idLahan;

  const DetailLahan({
    super.key,
    required this.title,
    this.imageUrl,
    required this.idLahan,
  });

  @override
  State<DetailLahan> createState() => _DetailLahanState();
}

class _DetailLahanState extends State<DetailLahan> {
  late DetailLahanLogic _logic;
  
  @override
  void initState() {
    super.initState();
    _logic = DetailLahanLogic(context, widget.idLahan);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _logic.initializeData();
  }

  // ===== UI BUILDING METHODS =====
  Widget buildSection(String title, Map<String, String> data) {
    // Jangan tampilkan section jika semua data kosong
    if (data.isEmpty || data.values.every((value) => value == '-' || value.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          ...data.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      "${e.key}:",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value.isEmpty ? '-' : e.value,
                      style: TextStyle(
                        color: e.value.isEmpty ? Colors.grey : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.blue.shade600,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada laporan untuk lahan ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan buat laporan dengan menekan tombol "+" di bawah',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionButtons(bool hasLaporan) {
    if (!hasLaporan) {
      return FloatingActionButton(
        onPressed: _logic.createLaporan,
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "edit_fab",
          onPressed: _logic.editLaporan,
          backgroundColor: const Color(0xFF2196F3),
          child: const Icon(Icons.edit, color: Colors.white),
        ),
        const SizedBox(width: 16),
        FloatingActionButton(
          heroTag: "delete_fab",
          onPressed: _logic.deleteLaporan,
          backgroundColor: const Color(0xFFF44336),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
      ],
    );
  }

  Widget buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Terjadi kesalahan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _logic.refreshLaporan,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget buildImageGrid(List<String> imageUrls) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dokumentasi",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E7D32),
            ),
          ),
          const SizedBox(height: 12),
          imageUrls.isEmpty
              ? Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 40,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gambar tidak ditambahkan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrls[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget buildHeaderImage() {
    return Center(
      child: widget.imageUrl != null && widget.imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.broken_image,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          : Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.landscape,
                size: 60,
                color: Colors.grey,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LahanProvider, LaporanProvider>(
      builder: (context, lahanProvider, laporanProvider, child) {
        final laporan = laporanProvider.getLaporan(widget.idLahan);
        final isLaporanEmpty = laporanProvider.isLaporanEmpty(widget.idLahan);
        final isLoading = laporanProvider.isLoading;
        final error = laporanProvider.error;

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F9),
          appBar: AppBar(
            backgroundColor: const Color(0xFF4CAF50),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _logic.getNamaLahan(lahanProvider, widget.title),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _logic.refreshLaporan,
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? buildErrorState(error)
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Header dengan gambar lahan
                        buildHeaderImage(),
                        const SizedBox(height: 20),

                        // Dokumentasi/Gambar - tampilkan di atas Informasi Lahan jika ada laporan
                        if (!isLaporanEmpty && laporan != null)
                          buildImageGrid(_logic.getImageUrls(laporan)),

                        // Informasi Lahan - selalu ditampilkan
                        buildSection(
                          "Informasi Lahan",
                          _logic.getInformasiLahanData(lahanProvider, widget.title),
                        ),

                        // Jika tidak ada laporan, tampilkan empty state
                        if (isLaporanEmpty) buildEmptyState(),

                        // Jika ada laporan, tampilkan sections
                        if (!isLaporanEmpty && laporan != null) ...[
                          // Data Musim Tanam
                          buildSection(
                            "Data Musim Tanam",
                            _logic.getMusimTanamData(laporan),
                          ),

                          // Input Produksi
                          buildSection(
                            "Input Produksi",
                            _logic.getInputProduksiData(laporan),
                          ),

                          // Hasil Panen
                          buildSection(
                            "Hasil Panen",
                            _logic.getHasilPanenData(laporan),
                          ),

                          // Pendampingan
                          buildSection(
                            "Kegiatan Pendampingan",
                            _logic.getPendampinganData(laporan),
                          ),

                          // Kendala
                          buildSection(
                            "Kendala di Lapangan",
                            _logic.getKendalaData(laporan),
                          ),

                          // Catatan
                          buildSection(
                            "Catatan Tambahan",
                            _logic.getCatatanData(laporan),
                          ),
                        ],

                        const SizedBox(height: 80), // Space for FAB
                      ],
                    ),
          floatingActionButton: buildActionButtons(!isLaporanEmpty),
          floatingActionButtonLocation: !isLaporanEmpty
              ? FloatingActionButtonLocation.endFloat
              : FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }
}