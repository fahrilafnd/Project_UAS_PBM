import 'package:flutter/material.dart';

class KendalaDiLapanganSection extends StatelessWidget {
  final TextEditingController deskripsiKendalaController;


  const KendalaDiLapanganSection ({
    super.key,
    required this.deskripsiKendalaController
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
            'Kendala di Lapangan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: deskripsiKendalaController,
            decoration: const InputDecoration(
              labelText: 'DeskripsiKendala',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
