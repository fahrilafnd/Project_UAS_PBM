import 'package:flutter/material.dart';
import 'package:projek_uas/screen/KebunSaya/DetailLahan/detail_add_lahan.dart';
import 'package:projek_uas/weather/cuacaBeranda.dart';

class Beranda extends StatefulWidget {
  const Beranda({super.key});

  @override
  _BerandaState createState() => _BerandaState();
}

class _BerandaState extends State<Beranda> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
      appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color.fromRGBO(247, 247, 247, 1),
          elevation: 0,
          title: Row(
            children: [
              Image.asset('assets/logo.png', height: 28),
              const SizedBox(width: 8),
              const Text(
                'PocketFarm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          const CuacaBeranda(),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(76, 175, 80, 1),
              padding: const EdgeInsets.symmetric(
                vertical: 14,
              ), // Tambahkan padding vertikal
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  4,
                ), // Sudut tidak terlalu lancip (seperti scaffold)
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DetailTambahLahan()),
              );
            },
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Posisikan isi ke tengah
              mainAxisSize: MainAxisSize.max,
              children: const [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Tambahkan Lahan',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
