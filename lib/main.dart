import 'package:flutter/material.dart';
import 'package:Koperasi/injection_container.dart' as di;
import 'package:Koperasi/core/services/database_service.dart';
import 'package:Koperasi/core/services/server_config.dart';
import 'package:Koperasi/features/auth/presentation/pages/login_page.dart';
import 'package:Koperasi/features/notifikasi/services/notifikasi_service.dart';
import 'package:Koperasi/features/profile/presentation/pages/profile_page.dart';
import 'package:Koperasi/features/welcome/presentation/pages/welcome_page.dart';
import 'package:Koperasi/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:Koperasi/features/pinjaman/data/repositories/pinjaman_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔴 COMMENT: Auto-detect server (opsional)
  // await ServerConfig.init();
  
  await di.init();

  // ===== UPDATE STATUS PINJAMAN =====
  try {
    final db = await DatabaseService().database;
    final repo = PinjamanRepositoryImpl(db);
    await repo.updateAllPinjamanStatus(); 
    print('✅ Status pinjaman updated on startup');
  } catch (e) {
    print('⚠️ Error updating status: $e');
  }

  // ===== CEK & BUAT TABEL NOTIFIKASI =====
  try {
    final db = await DatabaseService().database;

    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='notifikasi'");
    print('📊 Tabel notifikasi ada: ${tables.isNotEmpty}');

    if (tables.isEmpty) {
      await db.execute('''
        CREATE TABLE notifikasi(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          judul TEXT,
          pesan TEXT,
          jenis TEXT,
          tanggal TEXT,
          dibaca INTEGER DEFAULT 0,
          dihapus INTEGER DEFAULT 0
        )
      ''');
      print('✅ Tabel notifikasi dibuat');
    }
  } catch (e) {
    print('⚠️ Error cek tabel: $e');
  }

  // ===== GENERATE NOTIFIKASI =====
  try {
    final notifService = NotifikasiService(DatabaseService());
    await notifService.generateNotifikasi();
    print('✅ Notifikasi generated');
  } catch (e) {
    print('⚠️ Error generate notifikasi: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koperasi BMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/welcome',
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/welcome':  
        return MaterialPageRoute(builder: (_) => const WelcomePage());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/dashboard':
        return MaterialPageRoute(builder: (_) => const DashboardPage());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfilePage());
      default:
        return MaterialPageRoute(builder: (_) => const WelcomePage());
    }
  }
}