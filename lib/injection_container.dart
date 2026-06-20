import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'core/security/aes_service.dart';
import 'core/services/database_service.dart';
import 'core/services/connectivity_service.dart';

// Auth
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/datasources/auth_local_datasource.dart';
import 'features/auth/presentation/bloc/login_bloc.dart';

// Anggota
import 'features/anggota/domain/repositories/anggota_repository.dart';
import 'features/anggota/domain/usecases/get_all_anggota.dart';
import 'features/anggota/domain/usecases/get_anggota_by_id.dart';
import 'features/anggota/domain/usecases/create_anggota.dart';
import 'features/anggota/domain/usecases/update_anggota.dart';
import 'features/anggota/domain/usecases/delete_anggota.dart';
import 'features/anggota/domain/usecases/search_anggota.dart';
import 'features/anggota/data/repositories/anggota_repository_impl.dart';

// Angsuran
import 'features/angsuran/domain/repositories/angsuran_repository.dart';
import 'features/angsuran/domain/usecases/get_angsuran_by_pinjaman.dart';
import 'features/angsuran/domain/usecases/bayar_angsuran.dart';
import 'features/angsuran/domain/usecases/hitung_denda.dart';
import 'features/angsuran/domain/usecases/get_tunggakan.dart';
import 'features/angsuran/data/repositories/angsuran_repository_impl.dart';

// Pinjaman
import 'features/pinjaman/domain/repositories/pinjaman_repository.dart';
import 'features/pinjaman/domain/usecases/get_all_pinjaman.dart';
import 'features/pinjaman/domain/usecases/get_pinjaman_by_id.dart';
import 'features/pinjaman/domain/usecases/create_pinjaman.dart';
import 'features/pinjaman/domain/usecases/update_status_pinjaman.dart';
import 'features/pinjaman/data/repositories/pinjaman_repository_impl.dart';
import 'features/pinjaman/domain/usecases/get_pinjaman_by_anggota.dart';
import 'features/pinjaman/domain/usecases/update_sisa_pinjaman.dart';
import 'features/pinjaman/domain/usecases/hitung_angsuran.dart';

//Simpanan
import 'package:Koperasi/features/simpanan/domain/repositories/simpanan_repository.dart';
import 'package:Koperasi/features/simpanan/domain/usecases/get_all_simpanan.dart';
import 'package:Koperasi/features/simpanan/domain/usecases/get_simpanan_by_anggota.dart';
import 'package:Koperasi/features/simpanan/domain/usecases/create_simpanan.dart';
import 'package:Koperasi/features/simpanan/domain/usecases/get_total_simpanan_per_jenis.dart';
import 'package:Koperasi/features/simpanan/domain/usecases/get_simpanan_by_periode.dart';
import 'package:Koperasi/features/simpanan/data/repositories/simpanan_repository_impl.dart';

//laporan
import 'package:Koperasi/features/laporan/domain/repositories/laporan_repository.dart';
import 'package:Koperasi/features/laporan/domain/usecases/get_laporan_harian.dart';
import 'package:Koperasi/features/laporan/domain/usecases/get_laporan_bulanan.dart';
import 'package:Koperasi/features/laporan/domain/usecases/get_laporan_tahunan.dart';
import 'package:Koperasi/features/laporan/domain/usecases/export_laporan_pdf.dart';
import 'package:Koperasi/features/laporan/data/repositories/laporan_repository_impl.dart';

//tunggakan
import 'package:Koperasi/features/tunggakan/domain/repositories/tunggakan_repository.dart';
import 'package:Koperasi/features/tunggakan/domain/usecases/get_all_tunggakan.dart';
import 'package:Koperasi/features/tunggakan/domain/usecases/get_tunggakan_kritis.dart';
import 'package:Koperasi/features/tunggakan/domain/usecases/get_tunggakan_by_anggota.dart';
import 'package:Koperasi/features/tunggakan/domain/usecases/get_hampir_jatuh_tempo.dart';
import 'package:Koperasi/features/tunggakan/domain/usecases/get_jatuh_tempo.dart';
import 'package:Koperasi/features/tunggakan/data/repositories/tunggakan_repository_impl.dart';

//dashboard
import 'package:Koperasi/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:Koperasi/features/dashboard/domain/usecases/get_dashboard_data.dart';
import 'package:Koperasi/features/dashboard/data/repositories/dashboard_repository_impl.dart';

final sl = GetIt.instance;

Future<void> init() async {
  print('🔵 1. START INIT');
  
  try {
    await sl.reset();
    print('🔵 2. GetIt reset berhasil');
  } catch (e) {
    print('❌ Error reset: $e');
  }
  
  // Core
  try {
    await AesService.init();
    print('🔵 3. AesService init berhasil');
  } catch (e) {
    print('❌ AesService error: $e');
  }
  
  try {
    await _initSharedPreferences();
    print('🔵 4. SharedPreferences berhasil');
  } catch (e) {
    print('❌ SharedPreferences error: $e');
  }
  
  try {
    sl.registerLazySingleton(() => DatabaseService());
    sl.registerLazySingleton(() => ConnectivityService());
    print('🔵 5. DatabaseService & ConnectivityService registered');
  } catch (e) {
    print('❌ Service registration error: $e');
  }
  
  // Database
  Database? database;
  try {
    final dbService = sl<DatabaseService>();
    database = await dbService.database;
    sl.registerLazySingleton<Database>(() => database!);
    print('🔵 6. Database berhasil: $database');
  } catch (e) {
    print('❌ Database error: $e');
    // Jangan lanjut jika database error
    return;
  }
  
  // Auth - INI YANG PALING PENTING
  try {
    sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSource(sl(), sl()),
    );
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl()),
    );
    sl.registerLazySingleton(() => LoginUseCase(sl()));
    sl.registerLazySingleton(() => LogoutUseCase(sl()));
    print('🔵 7. Auth dependencies registered');
  } catch (e) {
    print('❌ Auth dependencies error: $e');
  }
  
  try {
    sl.registerFactory(() => LoginBloc(
          loginUseCase: sl(),
          logoutUseCase: sl(),
        ));
    print('🔵 8. ✅✅✅ LoginBloc BERHASIL DIREGISTER! ✅✅✅');
  } catch (e) {
    print('❌❌❌ LoginBloc REGISTRATION ERROR: $e ❌❌❌');
  }
  
  // Anggota
  try {
    sl.registerLazySingleton<AnggotaRepository>(
      () => AnggotaRepositoryImpl(sl<Database>()),
    );
    sl.registerLazySingleton(() => GetAllAnggota(sl()));
    sl.registerLazySingleton(() => GetAnggotaById(sl()));
    sl.registerLazySingleton(() => CreateAnggota(sl()));
    sl.registerLazySingleton(() => UpdateAnggota(sl()));
    sl.registerLazySingleton(() => DeleteAnggota(sl()));
    sl.registerLazySingleton(() => SearchAnggota(sl()));
    print('🔵 9. Anggota registered');
  } catch (e) {
    print('❌ Anggota error: $e');
  }

  // Angsuran
  try {
    sl.registerLazySingleton<AngsuranRepository>(
      () => AngsuranRepositoryImpl(sl<Database>()),
    );
    sl.registerLazySingleton(() => GetAngsuranByPinjaman(sl()));
    sl.registerLazySingleton(() => BayarAngsuran(sl()));
    sl.registerLazySingleton(() => HitungDenda());
    sl.registerLazySingleton(() => GetTunggakan(sl()));
    print('🔵 10. Angsuran registered');
  } catch (e) {
    print('❌ Angsuran error: $e');
  }

  // Pinjaman
  try {
    sl.registerLazySingleton<PinjamanRepository>(
      () => PinjamanRepositoryImpl(sl<Database>()),
    );
    sl.registerLazySingleton(() => GetAllPinjaman(sl()));
    sl.registerLazySingleton(() => GetPinjamanById(sl()));
    sl.registerLazySingleton(() => CreatePinjaman(sl()));
    sl.registerLazySingleton(() => UpdateStatusPinjaman(sl()));
    sl.registerLazySingleton(() => UpdateSisaPinjaman(sl()));
    sl.registerLazySingleton(() => HitungAngsuran());
    sl.registerLazySingleton(() => GetPinjamanByAnggota(sl()));
    print('🔵 11. Pinjaman registered');
  } catch (e) {
    print('❌ Pinjaman error: $e');
  }

  // Simpanan
  try {
    sl.registerLazySingleton<SimpananRepository>(
      () => SimpananRepositoryImpl(sl<DatabaseService>()),
    );
    sl.registerLazySingleton(() => GetAllSimpanan(sl()));
    sl.registerLazySingleton(() => GetSimpananByAnggota(sl()));
    sl.registerLazySingleton(() => CreateSimpanan(sl()));
    sl.registerLazySingleton(() => GetTotalSimpanan(sl()));
    sl.registerLazySingleton(() => GetTotalSimpananByAnggota(sl()));
    sl.registerLazySingleton(() => GetTotalSimpananPerJenis(sl()));
    sl.registerLazySingleton(() => GetSimpananByPeriode(sl()));
    print('🔵 12. Simpanan registered');
  } catch (e) {
    print('❌ Simpanan error: $e');
  }

  // Laporan
  try {
    sl.registerLazySingleton<LaporanRepository>(
      () => LaporanRepositoryImpl(sl<DatabaseService>()),
    );
    sl.registerLazySingleton(() => GetLaporanHarian(sl()));
    sl.registerLazySingleton(() => GetLaporanBulanan(sl()));
    sl.registerLazySingleton(() => GetLaporanTahunan(sl()));
    sl.registerLazySingleton(() => ExportLaporanPdf(sl()));
    print('🔵 13. Laporan registered');
  } catch (e) {
    print('❌ Laporan error: $e');
  }

  // Tunggakan
  try {
    sl.registerLazySingleton<TunggakanRepository>(
      () => TunggakanRepositoryImpl(sl<DatabaseService>()),
    );
    sl.registerLazySingleton(() => GetAllTunggakan(sl()));
    sl.registerLazySingleton(() => GetTunggakanKritis(sl()));
    sl.registerLazySingleton(() => GetTunggakanByAnggota(sl()));
    sl.registerLazySingleton(() => GetHampirJatuhTempo(sl()));
    sl.registerLazySingleton(() => GetJatuhTempo(sl()));
    print('🔵 14. Tunggakan registered');
  } catch (e) {
    print('❌ Tunggakan error: $e');
  }

  // Dashboard
  try {
    sl.registerLazySingleton<DashboardRepository>(
      () => DashboardRepositoryImpl(sl<DatabaseService>()),
    );
    sl.registerLazySingleton(() => GetDashboardData(sl()));
    print('🔵 15. Dashboard registered');
  } catch (e) {
    print('❌ Dashboard error: $e');
  }
  
  print('🟢 INIT COMPLETED!');
}
  
Future<void> _initSharedPreferences() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
}