import 'package:flutter/material.dart';

class CatatanTambahanSection extends StatelessWidget {
  final TextEditingController deskripsiCatatanController;


  const CatatanTambahanSection ({
    super.key,
    required this.deskripsiCatatanController
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
            'Catatan Tambahan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: deskripsiCatatanController,
            decoration: const InputDecoration(
              labelText: 'Deskripsi',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
