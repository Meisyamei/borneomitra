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
  Future<Either<Failure, LaporanKeuangan>> getLaporanHarian(DateTime tanggal) async {
    try {
      final db = await _db;
      final startDate = DateTime(tanggal.year, tanggal.month, tanggal.day);
      final endDate = startDate.add(const Duration(days: 1));
      
      final laporan = await _getLaporanData(db, startDate, endDate, _formatPeriode(tanggal));
      return Right(laporan);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil laporan harian: $e'));
    }
  }

  @override
  Future<Either<Failure, LaporanKeuangan>> getLaporanBulanan(int bulan, int tahun) async {
    try {
      final db = await _db;
      final startDate = DateTime(tahun, bulan, 1);
      final endDate = DateTime(tahun, bulan + 1, 1);
      
      final laporan = await _getLaporanData(db, startDate, endDate, _formatPeriodeBulan(bulan, tahun));
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
      
      final laporan = await _getLaporanData(db, startDate, endDate, 'Tahun $tahun');
      return Right(laporan);
    } catch (e) {
      return Left(DatabaseFailure('Gagal mengambil laporan tahunan: $e'));
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
  Future<LaporanKeuangan> _getLaporanData(Database db, DateTime startDate, DateTime endDate, String periode) async {
    final startStr = startDate.toIso8601String();
    final endStr = endDate.toIso8601String();

    // Total Simpanan
    final simpananResult = await db.rawQuery('''
      SELECT COALESCE(SUM(nominal), 0) as total
      FROM simpanan
      WHERE tanggal >= ? AND tanggal < ?
    ''', [startStr, endStr]);

    // Total Angsuran Masuk
    final angsuranResult = await db.rawQuery('''
      SELECT COALESCE(SUM(nominal), 0) as total
      FROM angsuran
      WHERE tanggal_bayar >= ? AND tanggal_bayar < ? AND status = 'lunas'
    ''', [startStr, endStr]);

    // Total Denda
    final dendaResult = await db.rawQuery('''
      SELECT COALESCE(SUM(denda), 0) as total
      FROM angsuran
      WHERE tanggal_bayar >= ? AND tanggal_bayar < ? AND status = 'lunas'
    ''', [startStr, endStr]);

    // Total Pinjaman Baru
    final pinjamanResult = await db.rawQuery('''
      SELECT COALESCE(SUM(jumlah), 0) as total
      FROM pinjaman
      WHERE tanggal_pinjam >= ? AND tanggal_pinjam < ?
    ''', [startStr, endStr]);

    // Simpanan per Jenis
    final simpananJenisResult = await db.rawQuery('''
      SELECT jenis, COALESCE(SUM(nominal), 0) as total
      FROM simpanan
      WHERE tanggal >= ? AND tanggal < ?
      GROUP BY jenis
    ''', [startStr, endStr]);

    // Jumlah Anggota Baru
    final anggotaResult = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM anggota
      WHERE tanggal_daftar >= ? AND tanggal_daftar < ?
    ''', [startStr, endStr]);

    // Jumlah Pinjaman Aktif
    final pinjamanAktifResult = await db.rawQuery('''
      SELECT COUNT(*) as total
      FROM pinjaman
      WHERE status = 'aktif'
    ''');

    final totalSimpanan = (simpananResult.first['total'] as num?)?.toDouble() ?? 0;
    final totalAngsuran = (angsuranResult.first['total'] as num?)?.toDouble() ?? 0;
    final totalDenda = (dendaResult.first['total'] as num?)?.toDouble() ?? 0;
    final totalPinjamanBaru = (pinjamanResult.first['total'] as num?)?.toDouble() ?? 0;
    final totalPemasukan = totalSimpanan + totalAngsuran + totalDenda;
    final totalPengeluaran = totalPinjamanBaru;
    final saldoAkhir = totalPemasukan - totalPengeluaran;

    final Map<String, double> simpananPerJenis = {};
    for (var row in simpananJenisResult) {
      simpananPerJenis[row['jenis'] as String] = (row['total'] as num?)?.toDouble() ?? 0;
    }

    return LaporanKeuangan(
      periode: periode,
      startDate: startDate,
      endDate: endDate.subtract(const Duration(days: 1)),
      totalSimpanan: totalSimpanan,
      totalAngsuran: totalAngsuran,
      totalDenda: totalDenda,
      totalPinjamanBaru: totalPinjamanBaru,
      totalPemasukan: totalPemasukan,
      totalPengeluaran: totalPengeluaran,
      saldoAkhir: saldoAkhir,
      simpananPerJenis: simpananPerJenis,
      jumlahAnggotaBaru: (anggotaResult.first['total'] as int?) ?? 0,
      jumlahPinjamanAktif: (pinjamanAktifResult.first['total'] as int?) ?? 0,
    );
  }

  String _formatPeriode(DateTime tanggal) {
    return '${tanggal.day}/${tanggal.month}/${tanggal.year}';
  }

  String _formatPeriodeBulan(int bulan, int tahun) {
    final bulanNama = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
                       'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${bulanNama[bulan - 1]} $tahun';
  }
}