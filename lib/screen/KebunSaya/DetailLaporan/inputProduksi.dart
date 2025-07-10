import 'package:flutter/material.dart';

class InputProduksiSection extends StatelessWidget {
  final TextEditingController jenisTanamanController;
  final TextEditingController jumlahPupukController;
  final TextEditingController jumlahPestisidaController;
  final TextEditingController teknikPengolahanController;

  final String satuanPupuk;
  final String satuanPestisida;
  final List<String> satuanPupukOptions;
  final List<String> satuanPestisidaOptions;

  final Function(String?) onSatuanPupukChanged;
  final Function(String?) onSatuanPestisidaChanged;

  const InputProduksiSection({
    super.key,
    required this.jenisTanamanController,
    required this.jumlahPupukController,
    required this.jumlahPestisidaController,
    required this.teknikPengolahanController,
    required this.satuanPupuk,
    required this.satuanPestisida,
    required this.satuanPupukOptions,
    required this.satuanPestisidaOptions,
    required this.onSatuanPupukChanged,
    required this.onSatuanPestisidaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Input Produksi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),

          // Jenis Tanaman
          TextFormField(
            controller: jenisTanamanController,
            decoration: const InputDecoration(
              labelText: 'Jenis Tanaman',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Jumlah Pupuk
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: jumlahPupukController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Pupuk',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: satuanPupuk,
                  items: satuanPupukOptions.map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
                  onChanged: onSatuanPupukChanged,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Jumlah Pestisida
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: jumlahPestisidaController,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Pestisida',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: satuanPestisida,
                  items: satuanPestisidaOptions.map((e) {
                    return DropdownMenuItem(value: e, child: Text(e));
                  }).toList(),
                  onChanged: onSatuanPestisidaChanged,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Teknik Pengolahan Tanah
          TextFormField(
            controller: teknikPengolahanController,
            decoration: const InputDecoration(
              labelText: 'Teknik Pengolahan Tanah',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
