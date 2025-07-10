// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:geolocator/geolocator.dart';

// class AddMappingBerjalan extends StatefulWidget {
//   const AddMappingBerjalan({super.key});

//   @override
//   State<AddMappingBerjalan> createState() => _AddMappingBerjalanState();
// }

// class _AddMappingBerjalanState extends State<AddMappingBerjalan> {
//   final MapController _mapController = MapController();
//   LatLng? userLocation;

//   Future<void> _getUserLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Layanan lokasi tidak aktif')),
//       );
//       return;
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Izin lokasi ditolak')),
//         );
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Izin lokasi ditolak permanen')),
//       );
//       return;
//     }

//     Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);

//     setState(() {
//       userLocation = LatLng(position.latitude, position.longitude);
//     });

//     _mapController.move(userLocation!, 18);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Dengan berjalan'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 1,
//       ),
//       body: Stack(
//         children: [
//           FlutterMap(
//             mapController: _mapController,
//             options: MapOptions(
//               center: const LatLng(-6.200000, 106.816666),
//               zoom: 16.0,
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate:
//                     'https://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
//                 userAgentPackageName: 'com.example.yourapp',
//               ),
//               if (userLocation != null)
//                 MarkerLayer(
//                   markers: [
//                     Marker(
//                       point: userLocation!,
//                       width: 40,
//                       height: 40,
//                       child: const Icon(
//                         Icons.my_location,
//                         color: Colors.red,
//                         size: 30,
//                       ),
//                     ),
//                   ],
//                 ),
//             ],
//           ),
//           Positioned(
//             top: 16,
//             left: 0,
//             right: 0,
//             child: Center(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(0.7),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: const Text(
//                   'Jarak 0 meter',
//                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                 ),
//               ),
//             ),
//           ),
//           Positioned(
//             top: 70,
//             left: 20,
//             right: 20,
//             child: Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 children: const [
//                   Icon(Icons.info_outline, color: Colors.blue),
//                   SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       "Ketuk ‘Mulai Pengukuran’ dan kelilingi batas-batas tanaman Anda",
//                       style: TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: _getUserLocation,
//         label: const Text('Temukan saya'),
//         icon: Image.asset(
//           'assets/cursor.png',
//           width: 20,
//           height: 20,
//         ),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
//       bottomNavigationBar: Container(
//         padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
//         color: Colors.white,
//         child: SizedBox(
//           width: double.infinity,
//           height: 48,
//           child: ElevatedButton(
//             onPressed: () {
//               // logika tracking nanti di sini
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF4CAF50),
//               foregroundColor: Colors.white,
//             ),
//             child: const Text('Mulai Pengukuran'),
//           ),
//         ),
//       ),
//     );
//   }
// }