// import 'package:flutter/material.dart';

// class MasukanScreen extends StatefulWidget {
//   const MasukanScreen({super.key});

//   @override
//   State<MasukanScreen> createState() => _MasukanScreenState();
// }

// class _MasukanScreenState extends State<MasukanScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _controller = TextEditingController();

//   void _kirimMasukan() {
//     if (_formKey.currentState!.validate()) {
//       // Di sini masukan bisa dikirim ke server atau disimpan secara lokal

//       // Kosongkan kolom input
//       _controller.clear();

//       // Tampilkan snackbar sebagai notifikasi
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text("Terima kasih atas masukan Anda!"),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Masukan")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               const Text(
//                 "Kami menghargai setiap masukan Anda untuk meningkatkan kualitas aplikasi PocketFarm.",
//                 style: TextStyle(fontSize: 16),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 20),
//               TextFormField(
//                 controller: _controller,
//                 maxLines: 5,
//                 decoration: const InputDecoration(
//                   hintText: "Tulis masukan atau saran Anda...",
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Masukan tidak boleh kosong';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton.icon(
//                   onPressed: _kirimMasukan,
//                   icon: const Icon(Icons.send),
//                   label: const Text("Kirim"),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
