import 'package:Koperasi/features/laporan/domain/entities/laporan_bulanan.dart';
import 'package:dartz/dartz.dart';
import 'package:sqflite/sqflite.dart';
import 'package:Koperasi/core/errors/failures.dart';
import 'package:Koperasi/core/services/database_service.dart';
import 'package:Koperasi/features/laporan/domain/entities/laporan.dart';
import 'package:Koperasi/features/laporan/domain/repositories/laporan_repository.dart';
import 'package:Koperasi/features/laporan/presentation/widgets/laporan_pdf.dart';

class LaporanRepositoryImpl implements LaporanRepository {
  final DatabaseService dbService;

  LaporanRepositoryImpl(this.dbService);

  Future<Database> get _db async => await dbService.database;

  @override
  Future<Either<Failure, LaporanKeuangan>> getLaporanHarian(
    DateTime tanggal,
  ) async {
    try {
      final db = await _db;
      final startDate = DateTime(tanggal.year, tanggal.month, tanggal.day);
      final endDate = startDate.add(const Duration(days: 1));

      final laporan = await _getLaporanData(
        db,
        startDate,
        endDate,
        _formatPeriode(tanggal),
      );
      return Right(laporan);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil laporan harian: $e'));
    }
  }

  @override
  Future<Either<Failure, LaporanKeuangan>> getLaporanBulanan(
    int bulan,
    int tahun,
  ) async {
    try {
      final db = await _db;
      final startDate = DateTime(tahun, bulan, 1);
      final endDate = DateTime(tahun, bulan + 1, 1);

      final laporan = await _getLaporanData(
        db,
        startDate,
        endDate,
        _formatPeriodeBulan(bulan, tahun),
      );
      return Right(laporan);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil laporan bulanan: $e'));
    }
  }

  @override
  Future<Either<Failure, LaporanKeuangan>> getLaporanTahunan(int tahun) async {
    try {
      final db = await _db;
      final startDate = DateTime(tahun, 1, 1);
      final endDate = DateTime(tahun + 1, 1, 1);

      final laporan = await _getLaporanData(
        db,
        startDate,
        endDate,
        'Tahun $tahun',
      );
      return Right(laporan);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil laporan tahunan: $e'));
    }
  }

  @override
  Future<Either<Failure, LaporanTahunanDetail>> getLaporanTahunanDetail(
    int tahun,
  ) async {
    try {
      final db = await _db;

      List<LaporanBulanan> dataPerBulan = [];
      double totalPemasukanTahun = 0;
      double totalPengeluaranTahun = 0;
      int totalAnggotaBaruTahun = 0;

      final bulanNama = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];

      for (int bulan = 1; bulan <= 12; bulan++) {
        final startDate = DateTime(tahun, bulan, 1);
        final endDate = DateTime(tahun, bulan + 1, 1);
        final startStr = startDate.toIso8601String();
        final endStr = endDate.toIso8601String();

        // Total Simpanan
        final simpananResult = await db.rawQuery(
          '''
          SELECT 
            COALESCE(SUM(CASE WHEN tipe = 'masuk' THEN nominal ELSE 0 END), 0) as total_masuk,
            COALESCE(SUM(CASE WHEN tipe = 'keluar' THEN nominal ELSE 0 END), 0) as total_keluar
          FROM simpanan
          WHERE tanggal >= ? AND tanggal < ?
        ''',
          [startStr, endStr],
        );

        final totalMasuk =
            (simpananResult.first['total_masuk'] as num?)?.toDouble() ?? 0;
        final totalKeluar =
            (simpananResult.first['total_keluar'] as num?)?.toDouble() ?? 0;
        final totalSimpanan = totalMasuk - totalKeluar;

        // Total Angsuran & Denda
        final angsuranResult = await db.rawQuery(
          '''
          SELECT 
            COALESCE(SUM(a.nominal), 0) as total_angsuran,
            COALESCE(SUM(a.denda), 0) as total_denda
          FROM angsuran a
          WHERE a.tanggal_bayar >= ? AND a.tanggal_bayar < ? AND a.status = 'lunas'
        ''',
          [startStr, endStr],
        );

        final totalAngsuran =
            (angsuranResult.first['total_angsuran'] as num?)?.toDouble() ?? 0;
        final totalDenda =
            (angsuranResult.first['total_denda'] as num?)?.toDouble() ?? 0;

        // Total Bunga
        // final bungaResult = await db.rawQuery('''
        //   SELECT
        //     COALESCE(SUM(
        //       CASE
        //         WHEN a.status = 'lunas' AND a.tanggal_bayar >= ? AND a.tanggal_bayar < ?
        //         THEN (p.jumlah * (p.bunga / 100)) / p.tenor
        //         ELSE 0
        //       END
        //     ), 0) as total_bunga
        //   FROM angsuran a
        //   JOIN pinjaman p ON a.pinjaman_id = p.id
        //   WHERE a.status = 'lunas'
        // ''', [startStr, endStr]);

        // final totalBunga = (bungaResult.first['total_bunga'] as num?)?.toDouble() ?? 0;

        // Total Pinjaman Baru
        final pinjamanResult = await db.rawQuery(
          '''
          SELECT COALESCE(SUM(jumlah), 0) as total
          FROM pinjaman
          WHERE tanggal_pinjam >= ? AND tanggal_pinjam < ?
        ''',
          [startStr, endStr],
        );
        final totalPinjamanBaru =
            (pinjamanResult.first['total'] as num?)?.toDouble() ?? 0;

        // Jumlah Anggota Baru
        final anggotaResult = await db.rawQuery(
          '''
          SELECT COUNT(*) as total
          FROM anggota
          WHERE tanggal_daftar >= ? AND tanggal_daftar < ?
        ''',
          [startStr, endStr],
        );
        final jumlahAnggotaBaru = (anggotaResult.first['total'] as int?) ?? 0;

        final totalPemasukan = totalSimpanan + totalAngsuran + totalDenda;
        final totalPengeluaran = totalPinjamanBaru;
        final saldoAkhir = totalPemasukan - totalPengeluaran;

        // Hanya tambahkan bulan yang ada transaksi
        if (totalPemasukan != 0 ||
            totalPengeluaran != 0 ||
            totalAngsuran != 0) {
          dataPerBulan.add(
            LaporanBulanan(
              bulan: bulan,
              tahun: tahun,
              namaBulan: bulanNama[bulan - 1],
              totalSimpanan: totalSimpanan,
              totalSimpananMasuk: totalMasuk,
              totalSimpananKeluar: totalKeluar,
              totalAngsuran: totalAngsuran,
              totalDenda: totalDenda,
              totalBunga: 0.0, // totalBunga,
              totalPinjamanBaru: totalPinjamanBaru,
              totalPemasukan: totalPemasukan,
              totalPengeluaran: totalPengeluaran,
              saldoAkhir: saldoAkhir,
              jumlahAnggotaBaru: jumlahAnggotaBaru,
            ),
          );

          totalPemasukanTahun += totalPemasukan;
          totalPengeluaranTahun += totalPengeluaran;
          totalAnggotaBaruTahun += jumlahAnggotaBaru;
        }
      }

      final saldoAkhirTahun = totalPemasukanTahun - totalPengeluaranTahun;

      return Right(
        LaporanTahunanDetail(
          tahun: tahun,
          dataPerBulan: dataPerBulan,
          totalPemasukanTahun: totalPemasukanTahun,
          totalPengeluaranTahun: totalPengeluaranTahun,
          saldoAkhirTahun: saldoAkhirTahun,
          totalAnggotaBaruTahun: totalAnggotaBaruTahun,
        ),
      );
    } catch (e) {
      return Left(
        DatabaseFailure('Gagal mengambil laporan tahunan detail: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> exportToPdf(LaporanKeuangan laporan) async {
    try {
      final pdfPath = await LaporanPdf.generate(laporan);
      return Right(pdfPath);
    } catch (e) {
      return Left(DatabaseFailure('Gagal export PDF: $e'));
    }
  }

  // Helper Methods
  Future<LaporanKeuangan> _getLaporanData(
    Database db,
    DateTime startDate,
    DateTime endDate,
    String periode,
  ) async {
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();

    // ===== 1. TOTAL SIMPANAN =====
    final simpananResult = await db.rawQuery(
      '''
    SELECT 
      COALESCE(SUM(CASE WHEN tipe = 'masuk' THEN nominal ELSE 0 END), 0) as total_masuk,
      COALESCE(SUM(CASE WHEN tipe = 'keluar' THEN nominal ELSE 0 END), 0) as total_keluar
    FROM simpanan
    WHERE tanggal >= ? AND tanggal < ?
  ''',
      [startStr, endStr],
    );

    final totalSimpananMasuk =
        (simpananResult.first['total_masuk'] as num?)?.toDouble() ?? 0.0;
    final totalSimpananKeluar =
        (simpananResult.first['total_keluar'] as num?)?.toDouble() ?? 0.0;
    final totalSimpanan = totalSimpananMasuk - totalSimpananKeluar;

    // ===== 2. TOTAL ANGSURAN =====
    final angsuranResult = await db.rawQuery(
      '''
    SELECT 
      COALESCE(SUM(a.nominal), 0) as total_angsuran,
      COALESCE(SUM(a.denda), 0) as total_denda
    FROM angsuran a
    WHERE a.tanggal_bayar >= ? AND a.tanggal_bayar < ? AND a.status = 'lunas'
  ''',
      [startStr, endStr],
    );

    final totalAngsuran =
        (angsuranResult.first['total_angsuran'] as num?)?.toDouble() ?? 0.0;
    final totalDenda =
        (angsuranResult.first['total_denda'] as num?)?.toDouble() ?? 0.0;

    // ===== 3. TOTAL PINJAMAN BARU (PENGELUARAN) =====
    final pinjamanResult = await db.rawQuery(
      '''
    SELECT COALESCE(SUM(jumlah), 0) as total
    FROM pinjaman
    WHERE tanggal_pinjam >= ? AND tanggal_pinjam < ?
  ''',
      [startStr, endStr],
    );
    final totalPinjamanBaru =
        (pinjamanResult.first['total'] as num?)?.toDouble() ?? 0.0;

    // ===== 4. SIMPANAN PER JENIS =====
    final simpananJenisResult = await db.rawQuery(
      '''
    SELECT 
      jenis,
      COALESCE(SUM(CASE WHEN tipe = 'masuk' THEN nominal ELSE 0 END), 0) as total_masuk,
      COALESCE(SUM(CASE WHEN tipe = 'keluar' THEN nominal ELSE 0 END), 0) as total_keluar
    FROM simpanan
    WHERE tanggal >= ? AND tanggal < ?
    GROUP BY jenis
  ''',
      [startStr, endStr],
    );

    final Map<String, double> simpananPerJenis = {};
    for (var row in simpananJenisResult) {
      final jenis = row['jenis'] as String;
      final totalMasuk = (row['total_masuk'] as num?)?.toDouble() ?? 0.0;
      final totalKeluar = (row['total_keluar'] as num?)?.toDouble() ?? 0.0;
      simpananPerJenis[jenis] = totalMasuk - totalKeluar;
    }

    // ===== 5. JUMLAH ANGGOTA BARU =====
    final anggotaResult = await db.rawQuery(
      '''
    SELECT COALESCE(COUNT(*), 0) as total
    FROM anggota
    WHERE tanggal_daftar >= ? AND tanggal_daftar < ?
  ''',
      [startStr, endStr],
    );
    final jumlahAnggotaBaru = (anggotaResult.first['total'] as int?) ?? 0;

    // ===== 6. JUMLAH PINJAMAN AKTIF =====
    final pinjamanAktifResult = await db.rawQuery('''
    SELECT COALESCE(COUNT(*), 0) as total
    FROM pinjaman
    WHERE status = 'aktif'
  ''');
    final jumlahPinjamanAktif =
        (pinjamanAktifResult.first['total'] as int?) ?? 0;

    // ===== 7. PERHITUNGAN =====
    // 🔴 PINJAMAN = PENGELUARAN (BUKAN PEMASUKAN)
    final totalPemasukan = totalSimpanan + totalAngsuran + totalDenda;
    final totalPengeluaran = totalPinjamanBaru;
    final saldoAkhir = totalPemasukan - totalPengeluaran;

    return LaporanKeuangan(
      periode: periode,
      startDate: startDate,
      endDate: endDate.subtract(const Duration(days: 1)),
      totalSimpanan: totalSimpanan,
      totalSimpananKeluar: totalSimpananKeluar,
      totalAngsuran: totalAngsuran,
      totalDenda: totalDenda,
      totalBunga: 0.0, // totalBunga,
      totalPinjamanBaru: totalPinjamanBaru,
      totalPemasukan: totalPemasukan,
      totalPengeluaran: totalPengeluaran,
      saldoAkhir: saldoAkhir,
      simpananPerJenis: simpananPerJenis,
      jumlahAnggotaBaru: jumlahAnggotaBaru,
      jumlahPinjamanAktif: jumlahPinjamanAktif,
    );
  }

  String _formatPeriode(DateTime tanggal) {
    return '${tanggal.day}/${tanggal.month}/${tanggal.year}';
  }

  String _formatPeriodeBulan(int bulan, int tahun) {
    final bulanNama = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${bulanNama[bulan - 1]} $tahun';
  }
}
