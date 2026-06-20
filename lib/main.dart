import 'package:Koperasi/core/services/database_service.dart';
import 'package:Koperasi/features/arisan/pages/arisan_page.dart';
import 'package:flutter/material.dart';
import 'injection_container.dart' as di;
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/anggota/presentation/pages/anggota_page.dart';
import 'features/simpanan/presentation/pages/simpanan_page.dart';
import 'features/pinjaman/presentation/pages/pinjaman_page.dart';
import 'features/angsuran/presentation/pages/angsuran_page.dart';
import 'features/tunggakan/presentation/pages/tunggakan_page.dart';
import 'features/laporan/presentation/pages/laporan_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await di.init();
    print('✅ Dependency injection berhasil');
  } catch (e) {
    print('❌ Error saat init: $e');
  }
  final dbService = DatabaseService();
  await dbService.database;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMSS Koperasi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      initialRoute: '/login',
      onGenerateRoute: _onGenerateRoute,
    );
  }
  
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case '/anggota':
        return MaterialPageRoute(builder: (_) => const AnggotaPage());
      case '/simpanan':
        return MaterialPageRoute(builder: (_) => const SimpananPage());
      case '/pinjaman':
        return MaterialPageRoute(builder: (_) => const PinjamanPage());
      case '/angsuran':
        return MaterialPageRoute(builder: (_) => const AngsuranPage());
      case '/arisan':
        return MaterialPageRoute(builder: (_) => const ArisanPage());
      case '/tunggakan':
        return MaterialPageRoute(builder: (_) => const TunggakanPage());
      case '/laporan':
        return MaterialPageRoute(builder: (_) => const LaporanPage());
      default:
        return MaterialPageRoute(builder: (_) => const LoginPage());
    }
  }
}