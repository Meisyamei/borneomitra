import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import 'package:Koperasi/core/errors/failures.dart';
import 'package:Koperasi/core/services/database_service.dart';
import 'package:Koperasi/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:Koperasi/features/dashboard/domain/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DatabaseService dbService;

  DashboardRepositoryImpl(this.dbService);

  Future<Database> get _db async => await dbService.database;

  @override
  Future<Either<Failure, DashboardData>> getDashboardData() async {
    try {
      final db = await _db;
      
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfMonthStr = startOfMonth.toIso8601String();
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      final nextMonthStr = nextMonth.toIso8601String();

      // 1. Statistik Anggota
      final anggotaStats = await _getAnggotaStats(db);
      
      // 2. Statistik Simpanan
      final simpananStats = await _getSimpananStats(db, startOfMonthStr, nextMonthStr);
      
      // 3. Statistik Pinjaman
      final pinjamanStats = await _getPinjamanStats(db, startOfMonthStr, nextMonthStr);
      
      // 4. Statistik Pembayaran Angsuran
      final angsuranStats = await _getAngsuranStats(db, startOfMonthStr, nextMonthStr);
      
      // 5. Statistik Tunggakan
      final tunggakanStats = await _getTunggakanStats(db);
      
      // 6. Transaksi Terbaru
      final transaksiTerbaru = await _getTransaksiTerbaru(db);

      final dashboardData = DashboardData(
      totalAnggota: anggotaStats['total'] as int,
      anggotaAktif: anggotaStats['aktif'] as int,
      anggotaBaruBulanIni: anggotaStats['baru_bulan_ini'] as int,
      totalSimpanan: (simpananStats['total'] as num).toDouble(),
      simpananWajib: (simpananStats['wajib'] as num).toDouble(),
      simpananSukarela: (simpananStats['sukarela'] as num).toDouble(),
      simpananPokok: (simpananStats['pokok'] as num).toDouble(),
      simpananMasukBulanIni: (simpananStats['masuk_bulan_ini'] as num).toDouble(),
      totalPinjamanAktif: (pinjamanStats['total_aktif'] as num).toDouble(),
      jumlahPinjamanAktif: pinjamanStats['jumlah_aktif'] as int,
      pinjamanBaruBulanIni: (pinjamanStats['baru_bulan_ini'] as num).toDouble(),
      jumlahPinjamanBaruBulanIni: pinjamanStats['jumlah_baru_bulan_ini'] as int,
      angsuranMasukBulanIni: (angsuranStats['total_masuk'] as num).toDouble(),
      jumlahAngsuranBulanIni: angsuranStats['jumlah_masuk'] as int,
      totalTunggakan: tunggakanStats['total_anggota'] as int,
      tunggakanKritis: tunggakanStats['kritis'] as int,
      hampirJatuhTempo: tunggakanStats['hampir'] as int,
      jatuhTempoHariIni: tunggakanStats['hari_ini'] as int,
      nominalTunggakan: (tunggakanStats['nominal'] as num).toDouble(),
      transaksiTerbaru: transaksiTerbaru,
    );

      return Right(dashboardData);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil data dashboard: $e'));
    }
  }

  Future<Map<String, int>> _getAnggotaStats(Database db) async {
    // Total anggota
    final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM anggota');
    final total = (totalResult.first['total'] as int?) ?? 0;

    // Anggota aktif (total pinjaman < 50jt)
    final aktifResult = await db.rawQuery('''
      SELECT COUNT(*) as total FROM anggota WHERE total_pinjaman < 50000000
    ''');
    final aktif = (aktifResult.first['total'] as int?) ?? 0;

    // Anggota baru bulan ini
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfMonthStr = startOfMonth.toIso8601String();
    final baruResult = await db.rawQuery('''
      SELECT COUNT(*) as total FROM anggota WHERE tanggal_daftar >= ?
    ''', [startOfMonthStr]);
    final baru = (baruResult.first['total'] as int?) ?? 0;

    return {
      'total': total,
      'aktif': aktif,
      'baru_bulan_ini': baru,
    };
  }

  Future<Map<String, double>> _getSimpananStats(Database db, String startMonth, String endMonth) async {
    // Total simpanan
    final totalResult = await db.rawQuery('SELECT COALESCE(SUM(nominal), 0) as total FROM simpanan');
    final total = (totalResult.first['total'] as num?)?.toDouble() ?? 0;

    // Simpanan per jenis
    final jenisResult = await db.rawQuery('''
      SELECT jenis, COALESCE(SUM(nominal), 0) as total 
      FROM simpanan 
      GROUP BY jenis
    ''');
    
    double wajib = 0, sukarela = 0, pokok = 0;
    for (var row in jenisResult) {
      final jenis = row['jenis'] as String;
      final nominal = (row['total'] as num?)?.toDouble() ?? 0;
      if (jenis == 'wajib') wajib = nominal;
      else if (jenis == 'sukarela') sukarela = nominal;
      else if (jenis == 'pokok') pokok = nominal;
    }

    // Simpanan masuk bulan ini
    final masukResult = await db.rawQuery('''
      SELECT COALESCE(SUM(nominal), 0) as total 
      FROM simpanan 
      WHERE tanggal >= ? AND tanggal < ?
    ''', [startMonth, endMonth]);
    final masuk = (masukResult.first['total'] as num?)?.toDouble() ?? 0;

    return {
      'total': total,
      'wajib': wajib,
      'sukarela': sukarela,
      'pokok': pokok,
      'masuk_bulan_ini': masuk,
    };
  }

  Future<Map<String, dynamic>> _getPinjamanStats(Database db, String startMonth, String endMonth) async {
    // Total pinjaman aktif
    final aktifResult = await db.rawQuery('''
      SELECT COALESCE(SUM(sisa_pinjaman), 0) as total, COUNT(*) as jumlah 
      FROM pinjaman 
      WHERE status = 'aktif'
    ''');
    final totalAktif = (aktifResult.first['total'] as num?)?.toDouble() ?? 0;
    final jumlahAktif = (aktifResult.first['jumlah'] as int?) ?? 0;

    // Pinjaman baru bulan ini
    final baruResult = await db.rawQuery('''
      SELECT COALESCE(SUM(jumlah), 0) as total, COUNT(*) as jumlah 
      FROM pinjaman 
      WHERE tanggal_pinjam >= ? AND tanggal_pinjam < ?
    ''', [startMonth, endMonth]);
    final totalBaru = (baruResult.first['total'] as num?)?.toDouble() ?? 0;
    final jumlahBaru = (baruResult.first['jumlah'] as int?) ?? 0;

    return {
      'total_aktif': totalAktif,
      'jumlah_aktif': jumlahAktif,
      'baru_bulan_ini': totalBaru,
      'jumlah_baru_bulan_ini': jumlahBaru,
    };
  }

  Future<Map<String, dynamic>> _getAngsuranStats(Database db, String startMonth, String endMonth) async {
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(nominal), 0) as total, COUNT(*) as jumlah 
      FROM angsuran 
      WHERE tanggal_bayar >= ? AND tanggal_bayar < ? AND status = 'lunas'
    ''', [startMonth, endMonth]);

    return {
      'total_masuk': (result.first['total'] as num?)?.toDouble() ?? 0,
      'jumlah_masuk': (result.first['jumlah'] as int?) ?? 0,
    };
  }

  Future<Map<String, dynamic>> _getTunggakanStats(Database db) async {
    // Query total menunggak
    final menunggakResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT a.id) as total
      FROM anggota a
      JOIN pinjaman p ON a.id = p.anggota_id
      JOIN angsuran ang ON p.id = ang.pinjaman_id
      WHERE p.status = 'aktif'
        AND ang.status = 'belum_bayar'
        AND ang.tanggal_jatuh_tempo < date('now')
    ''');
    final totalMenunggak = (menunggakResult.first['total'] as int?) ?? 0;

    // Tunggakan kritis (> 30 hari)
    final kritisResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT a.id) as total
      FROM anggota a
      JOIN pinjaman p ON a.id = p.anggota_id
      JOIN angsuran ang ON p.id = ang.pinjaman_id
      WHERE p.status = 'aktif'
        AND ang.status = 'belum_bayar'
        AND julianday('now') - julianday(ang.tanggal_jatuh_tempo) > 30
    ''');
    final kritis = (kritisResult.first['total'] as int?) ?? 0;

    // Hampir jatuh tempo (1-3 hari)
    final hampirResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT a.id) as total
      FROM anggota a
      JOIN pinjaman p ON a.id = p.anggota_id
      JOIN angsuran ang ON p.id = ang.pinjaman_id
      WHERE p.status = 'aktif'
        AND ang.status = 'belum_bayar'
        AND ang.tanggal_jatuh_tempo >= date('now')
        AND ang.tanggal_jatuh_tempo <= date('now', '+3 days')
    ''');
    final hampir = (hampirResult.first['total'] as int?) ?? 0;

    // Jatuh tempo hari ini
    final hariIniResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT a.id) as total
      FROM anggota a
      JOIN pinjaman p ON a.id = p.anggota_id
      JOIN angsuran ang ON p.id = ang.pinjaman_id
      WHERE p.status = 'aktif'
        AND ang.status = 'belum_bayar'
        AND date(ang.tanggal_jatuh_tempo) = date('now')
    ''');
    final hariIni = (hariIniResult.first['total'] as int?) ?? 0;

    // Total nominal tunggakan
    final nominalResult = await db.rawQuery('''
      SELECT COALESCE(SUM(ang.nominal), 0) as total
      FROM angsuran ang
      JOIN pinjaman p ON ang.pinjaman_id = p.id
      WHERE p.status = 'aktif'
        AND ang.status = 'belum_bayar'
        AND ang.tanggal_jatuh_tempo < date('now')
    ''');
    final nominal = (nominalResult.first['total'] as num?)?.toDouble() ?? 0;

    return {
      'total_anggota': totalMenunggak,
      'kritis': kritis,
      'hampir': hampir,
      'hari_ini': hariIni,
      'nominal': nominal,
    };
  }
  Future<List<TransaksiTerbaru>> _getTransaksiTerbaru(Database db) async {
    final List<TransaksiTerbaru> transaksi = [];

    // Ambil simpanan terbaru (5 data)
    final simpananResult = await db.rawQuery('''
      SELECT s.id, s.anggota_id, s.nominal, s.tanggal, s.jenis, a.nama as nama_anggota
      FROM simpanan s
      JOIN anggota a ON s.anggota_id = a.id
      ORDER BY s.tanggal DESC
      LIMIT 5
    ''');

    for (var row in simpananResult) {
      final id = row['id'] as int?;
      if (id == null) continue; 
      
      final tanggalStr = row['tanggal'] as String?;
      if (tanggalStr == null) continue; 
      
      transaksi.add(TransaksiTerbaru(
        id: id,
        jenis: 'simpanan',
        judul: 'Simpanan ${_getJenisSimpanan(row['jenis'] as String? ?? '')}',
        subtitle: row['nama_anggota'] as String? ?? 'Unknown',
        nominal: (row['nominal'] as num?)?.toDouble() ?? 0,
        tanggal: DateTime.parse(tanggalStr),
        status: 'success',
      ));
    }

    // Ambil angsuran terbaru (5 data)
    final angsuranResult = await db.rawQuery('''
      SELECT ang.id, ang.pinjaman_id, ang.nominal, ang.tanggal_bayar, a.nama as nama_anggota
      FROM angsuran ang
      JOIN pinjaman p ON ang.pinjaman_id = p.id
      JOIN anggota a ON p.anggota_id = a.id
      WHERE ang.tanggal_bayar IS NOT NULL
      ORDER BY ang.tanggal_bayar DESC
      LIMIT 5
    ''');

    for (var row in angsuranResult) {
      final id = row['id'] as int?;
      if (id == null) continue;
      
      final tanggalBayarStr = row['tanggal_bayar'] as String?;
      if (tanggalBayarStr == null) continue;
      
      transaksi.add(TransaksiTerbaru(
        id: id,
        jenis: 'angsuran',
        judul: 'Pembayaran Angsuran',
        subtitle: row['nama_anggota'] as String? ?? 'Unknown',
        nominal: (row['nominal'] as num?)?.toDouble() ?? 0,
        tanggal: DateTime.parse(tanggalBayarStr),
        status: 'success',
      ));
    }

    // Urutkan berdasarkan tanggal terbaru dan ambil 10
    transaksi.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return transaksi.take(10).toList();
  }

  String _getJenisSimpanan(String jenis) {
    switch (jenis) {
      case 'wajib': return 'Wajib';
      case 'sukarela': return 'Sukarela';
      case 'pokok': return 'Pokok';
      default: return jenis;
    }
  }
}