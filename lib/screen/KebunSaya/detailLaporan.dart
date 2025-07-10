import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:projek_uas/logic/detailLaporanLogic.dart';
import 'package:projek_uas/screen/KebunSaya/DetailLaporan/image_widget.dart';
import 'package:projek_uas/screen/KebunSaya/DetailLaporan/catatanTambahan.dart';
import 'package:projek_uas/screen/KebunSaya/DetailLaporan/dataMusimTanam.dart';
import 'package:projek_uas/screen/KebunSaya/DetailLaporan/hasilPanen.dart';
import 'package:projek_uas/screen/KebunSaya/DetailLaporan/inputProduksi.dart';
import 'package:projek_uas/screen/KebunSaya/DetailLaporan/kegiatanPendampingan.dart';
import 'package:projek_uas/screen/KebunSaya/DetailLaporan/kendalaDiLapangan.dart';
import 'package:projek_uas/providers/laporan_provider.dart';

class DetailLaporan extends StatefulWidget {
  final int idLahan;
  final VoidCallback? onSaved;
  final bool isEdit;

  const DetailLaporan({
    super.key,
    required this.idLahan,
    this.onSaved,
    this.isEdit = false,
  });

  @override
  State<DetailLaporan> createState() => _DetailLaporanState();
}

class _DetailLaporanState extends State<DetailLaporan> {
  final _formKey = GlobalKey<FormState>();
  late DetailLaporanLogic _logic;

  @override
  void initState() {
    super.initState();
    _logic = DetailLaporanLogic(
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    _logic.initialize(context);
    _logic.initializeData(context, widget.idLahan, widget.isEdit);
  }

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final success = await _logic.saveLaporan(context, widget.idLahan, widget.isEdit);
      if (success) {
        if (widget.onSaved != null) {
          widget.onSaved!();
        }
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LaporanProvider>(
      builder: (context, laporanProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F9),
          appBar: _buildAppBar(),
          body: Stack(
            children: [
              if (_logic.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                _buildBody(),
              if (laporanProvider.isLoading || _logic.isUploadingImages)
                _buildLoadingOverlay(),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF9F9F9),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        widget.isEdit ? "Edit Laporan" : "Tambahkan Laporan",
        style: const TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildImageSection(),
            const SizedBox(height: 24),
            _buildDataMusimTanamSection(),
            _buildInputProduksiSection(),
            const SizedBox(height: 24),
            _buildKegiatanPendampinganSection(),
            _buildKendalaDiLapanganSection(),
            _buildHasilPanenSection(),
            _buildCatatanTambahanSection(),
            const SizedBox(height: 24),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return ImageWidgets.buildImageSection(
      totalImages: _logic.totalImages,
      existingImageUrls: _logic.imageHandler.existingImageUrls,
      selectedImages: _logic.imageHandler.selectedImages,
      isUploadingImages: _logic.isUploadingImages,
      onAddImagePressed: () {
        _logic.showImagePicker();
      },
      onRemoveImage: (index, {bool isExisting = false}) {
        _logic.imageHandler.removeImage(index, isExisting: isExisting);
      },
      onShowFullImage: (image, {bool isNetwork = false}) {
        ImageWidgets.showFullImage(context, image, isNetwork: isNetwork);
      },
    );
  }

  Widget _buildDataMusimTanamSection() {
    return DataMusimTanamSection(
      tanggalTanamController: _logic.tanggalTanamController,
      jenisTanamanController: _logic.jenisTanamanController,
      sumberBenih: _logic.sumberBenih,
      sumberBenihOptions: _logic.sumberBenihOptions,
      onSumberBenihChanged: _logic.updateSumberBenih,
    );
  }

  Widget _buildInputProduksiSection() {
    return InputProduksiSection(
      jenisTanamanController: _logic.jenisTanamanController,
      // ADDED: jenisPupuk field that was missing
      jumlahPupukController: _logic.jumlahPupukController,
      jumlahPestisidaController: _logic.jumlahPestisidaController,
      teknikPengolahanController: _logic.teknikPengolahanController,
      satuanPupuk: _logic.satuanPupuk,
      satuanPestisida: _logic.satuanPestisida,
      satuanPupukOptions: _logic.satuanPupukOptions,
      satuanPestisidaOptions: _logic.satuanPestisidaOptions,
      onSatuanPupukChanged: _logic.updateSatuanPupuk,
      onSatuanPestisidaChanged: _logic.updateSatuanPestisida,
    );
  }

  Widget _buildKegiatanPendampinganSection() {
    return KegiatanPendampinganSection(
      tanggalKunjunganController: _logic.tanggalKunjunganController,
      materiPenyuluhanController: _logic.materiPenyuluhanController,
      kritikDanSaranController: _logic.kritikDanSaranController,
    );
  }

  Widget _buildKendalaDiLapanganSection() {
    return KendalaDiLapanganSection(
      deskripsiKendalaController: _logic.deskripsiKendalaController,
    );
  }

  Widget _buildHasilPanenSection() {
    return HasilPanenSection(
      tanggalPanenController: _logic.tanggalPanenController,
      satuanPanenController: _logic.totalPanenController,
      kualitasHasilController: _logic.kualitasHasilController,
      satuanPanen: _logic.satuanPanen,
      kualitasHasil: _logic.kualitasHasil,
      satuanPanenOptions: _logic.satuanPanenOptions,
      kualitasHasilOptions: _logic.kualitasHasilOptions,
      onSatuanPanenChanged: _logic.updateSatuanPanen,
      onKualitasHasilChanged: _logic.updateKualitasHasil,
    );
  }

  Widget _buildCatatanTambahanSection() {
    return CatatanTambahanSection(
      deskripsiCatatanController: _logic.deskripsiCatatanController,
    );
  }

  Widget _buildSaveButton() {
    return Consumer<LaporanProvider>(
      builder: (context, laporanProvider, child) {
        final isLoading = laporanProvider.isLoading || _logic.isUploadingImages;
        
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: isLoading ? null : _handleSave,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.isEdit ? 'Update Laporan' : 'Simpan Laporan',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}