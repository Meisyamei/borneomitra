import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import '../entities/laporan.dart';
import '../repositories/laporan_repository.dart';

class GetLaporanBulanan {
  final LaporanRepository repository;

  GetLaporanBulanan(this.repository);

  Future<Either<Failure, LaporanKeuangan>> execute(int bulan, int tahun) async {
    if (bulan < 1 || bulan > 12) {
      return Left(ValidationFailure('Bulan harus antara 1-12'));
    }
    if (tahun < 2000 || tahun > DateTime.now().year) {
      return Left(ValidationFailure('Tahun tidak valid'));
    }
    return await repository.getLaporanBulanan(bulan, tahun);
  }
}