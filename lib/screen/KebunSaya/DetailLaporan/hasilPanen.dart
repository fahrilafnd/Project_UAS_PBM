import 'package:flutter/material.dart';

class HasilPanenSection extends StatelessWidget {
  final TextEditingController tanggalPanenController;
  final TextEditingController satuanPanenController;
  final TextEditingController kualitasHasilController;
  final String satuanPanen;
  final String kualitasHasil;
  final List<String> satuanPanenOptions;
  final List<String> kualitasHasilOptions;
  final ValueChanged<String?> onSatuanPanenChanged;
  final ValueChanged<String?> onKualitasHasilChanged;

  const HasilPanenSection({
    super.key,
    required this.tanggalPanenController,
    required this.satuanPanenController,
    required this.kualitasHasilController,
    required this.satuanPanen,
    required this.kualitasHasil,
    required this.satuanPanenOptions,
    required this.kualitasHasilOptions,
    required this.onSatuanPanenChanged,
    required this.onKualitasHasilChanged,
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
            'Hasil Panen',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),

          // Tanggal Panen
          TextFormField(
            controller: tanggalPanenController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Tanggal Panen',
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
                tanggalPanenController.text =
                    pickedDate.toIso8601String().split('T').first;
              }
            },
          ),
          const SizedBox(height: 12),

          // Total Hasil Panen
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: satuanPanenController,
                  decoration: const InputDecoration(
                    labelText: 'Total Hasil Panen',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  value: satuanPanen,
                  items:
                      satuanPanenOptions.map((e) {
                        return DropdownMenuItem(value: e, child: Text(e));
                      }).toList(),
                  onChanged: onSatuanPanenChanged,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Kualitas Hasil
          DropdownButtonFormField<String>(
            value: kualitasHasil,
            items:
                kualitasHasilOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            onChanged: onKualitasHasilChanged,
            decoration: const InputDecoration(
              labelText: 'Kualitas Hasil',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
