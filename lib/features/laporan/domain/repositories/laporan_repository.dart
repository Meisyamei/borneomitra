import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import '../entities/laporan.dart';
import '../entities/laporan_bulanan.dart';

abstract class LaporanRepository {
  Future<Either<Failure, LaporanKeuangan>> getLaporanHarian(DateTime tanggal);
  Future<Either<Failure, LaporanKeuangan>> getLaporanBulanan(int bulan, int tahun);
  Future<Either<Failure, LaporanKeuangan>> getLaporanTahunan(int tahun);
  
  // 🔴 TAMBAHKAN INI
  Future<Either<Failure, LaporanTahunanDetail>> getLaporanTahunanDetail(int tahun);
  
  Future<Either<Failure, String>> exportToPdf(LaporanKeuangan laporan);
}