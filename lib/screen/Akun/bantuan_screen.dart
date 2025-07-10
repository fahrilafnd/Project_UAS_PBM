// import 'package:flutter/material.dart';

// class BantuanScreen extends StatelessWidget {
//   const BantuanScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Bantuan"),
//         backgroundColor: const Color(0xFF4CAF50),
//         foregroundColor: Colors.white,
//       ),
//       backgroundColor: const Color(0xFFF7F7F7),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             children: [
//               const Icon(Icons.support_agent, size: 100, color: Colors.green),
//               const SizedBox(height: 16),
//               const Text(
//                 "Butuh Bantuan?",
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 "Kami siap membantu Anda. Pilih salah satu opsi di bawah ini untuk mendapatkan bantuan.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 14, color: Colors.grey),
//               ),
//               const SizedBox(height: 32),
//               _buildHelpOption(
//                 icon: Icons.question_answer,
//                 title: "Pertanyaan Umum (FAQ)",
//                 subtitle: "Lihat jawaban untuk pertanyaan yang sering diajukan.",
//                 onTap: () {
//                   // Arahkan ke halaman FAQ jika tersedia
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Fitur FAQ belum tersedia')),
//                   );
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildHelpOption(
//                 icon: Icons.chat,
//                 title: "Chat dengan Support",
//                 subtitle: "Tim kami siap membantu Anda secara langsung.",
//                 onTap: () {
//                   // Arahkan ke fitur chat support jika tersedia
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Fitur Chat belum tersedia')),
//                   );
//                 },
//               ),
//               const SizedBox(height: 16),
//               _buildHelpOption(
//                 icon: Icons.email,
//                 title: "Kirim Email",
//                 subtitle: "Hubungi kami melalui email untuk bantuan lebih lanjut.",
//                 onTap: () {
//                   // Kirim email atau buka form email
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Fitur Email belum tersedia')),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHelpOption({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: const [
//             BoxShadow(
//               color: Colors.black12,
//               blurRadius: 6,
//               offset: Offset(0, 2),
//             )
//           ],
//         ),
//         child: Row(
//           children: [
//             Icon(icon, size: 36, color: Colors.green),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(title,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       )),
//                   const SizedBox(height: 4),
//                   Text(subtitle,
//                       style: const TextStyle(
//                         fontSize: 13,
//                         color: Colors.grey,
//                       )),
//                 ],
//               ),
//             ),
//             const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
//           ],
//         ),
//       ),
//     );
//   }
// }
