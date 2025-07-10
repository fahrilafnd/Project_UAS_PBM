import 'package:flutter/material.dart';

class KegiatanPendampinganSection extends StatelessWidget {
  final TextEditingController tanggalKunjunganController;
  final TextEditingController materiPenyuluhanController;
  final TextEditingController kritikDanSaranController;

  const KegiatanPendampinganSection({
    super.key,
    required this.tanggalKunjunganController,
    required this.materiPenyuluhanController,
    required this.kritikDanSaranController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kegiatan Pendampingan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: tanggalKunjunganController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Tanggal Kunjungan',
              border: OutlineInputBorder(),
              suffixIcon: Icon(Icons.calendar_today),
            ),
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
              );
              if (pickedDate != null) {
                // Format yyyy-MM-dd (ISO format yang diharapkan oleh backend)
                tanggalKunjunganController.text =
                    pickedDate.toIso8601String().split('T').first;
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: materiPenyuluhanController,
            decoration: const InputDecoration(
              labelText: 'Materi Penyuluhan',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: kritikDanSaranController,
            decoration: const InputDecoration(
              labelText: 'Kritik dan Saran',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
