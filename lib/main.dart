// main.dart - Updated dengan Provider
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:projek_uas/providers/tips_provider.dart';
import 'package:provider/provider.dart';
import 'package:projek_uas/providers/auth_provider.dart';
import 'package:projek_uas/providers/lahan_provider.dart';
import 'package:projek_uas/providers/laporan_provider.dart';
import 'package:projek_uas/providers/loading_provider.dart';
import 'package:projek_uas/screen/admin/admin.dart';
import 'package:projek_uas/screen/beranda.dart';
import 'package:projek_uas/screen/KebunSaya/kebunSaya.dart';
import 'package:projek_uas/screen/Tips/tips.dart';
import 'package:projek_uas/screen/Akun/akun.dart';
import 'package:projek_uas/screen/splash_screen1.dart';
import 'package:projek_uas/screen/splash_screen2.dart';
import 'package:projek_uas/screen/LoginRegister/login_screen.dart';
import 'package:projek_uas/screen/LoginRegister/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoadingProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LahanProvider()),
        ChangeNotifierProvider(create: (_) => LaporanProvider()),
        ChangeNotifierProvider(create: (_) => TipsProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Pocket Farm',
            theme: ThemeData(
              fontFamily: 'Roboto',
              scaffoldBackgroundColor: const Color(0xFFF9F9F9),
            ),
            initialRoute: '/splash1',
            routes: {
              '/splash1': (context) => const SplashScreen1(),
              '/splash2': (context) => SplashScreen2(),
              '/login': (context) => LoginScreen(),
              '/register': (context) => RegisterScreen(),
              '/home': (context) => const MyHomePage(title: 'Pocket Farm'),
              '/Akun': (context) => const Akun(),
              '/admin': (context) => const AdminPage(),
            },
            // Global loading overlay
            builder: (context, child) {
              return Consumer<LoadingProvider>(
                builder: (context, loadingProvider, _) {
                  return Stack(
                    children: [
                      child!,
                      if (loadingProvider.isGlobalLoading)
                        Container(
                          color: Colors.black26,
                          child: Center(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(),
                                    if (loadingProvider.globalMessage !=
                                        null) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        loadingProvider.globalMessage!,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Beranda(),
    const MappingPage(idLahan: null),
    TipsPage(),
    Akun(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeProviders();
  }

  Future<void> _initializeProviders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final lahanProvider = Provider.of<LahanProvider>(context, listen: false);
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );

    // Initialize auth first
    await authProvider.initializeAuth();

    // If authenticated, fetch lahan data
    if (authProvider.isAuthenticated) {
      await loadingProvider.withLoading(
        LoadingProvider.fetchLahan,
        lahanProvider.fetchLahan(authProvider.token!),
        message: 'Memuat data lahan...',
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFFF9F9F9),
        selectedItemColor: const Color(0xFF4CAF50),
        items: [
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 0
                  ? 'assets/Beranda_hijau.png'
                  : 'assets/Beranda.png',
              width: 20,
              height: 20,
            ),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 1
                  ? 'assets/Kebun Saya_hijau.png'
                  : 'assets/Kebun Saya.png',
              width: 20,
              height: 20,
            ),
            label: 'Kebun Saya',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 2
                  ? 'assets/Hasil Laporan_hijau.png'
                  : 'assets/Hasil Laporan.png',
              width: 20,
              height: 20,
            ),
            label: 'Tips',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 3 ? 'assets/Akun_hijau.png' : 'assets/Akun.png',
              width: 20,
              height: 20,
            ),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
