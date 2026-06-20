import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import '../entities/laporan.dart';
import '../repositories/laporan_repository.dart';

class GetLaporanTahunan {
  final LaporanRepository repository;

  GetLaporanTahunan(this.repository);

  Future<Either<Failure, LaporanKeuangan>> execute(int tahun) async {
    if (tahun < 2000 || tahun > DateTime.now().year) {
      return Left(ValidationFailure('Tahun tidak valid'));
    }
    return await repository.getLaporanTahunan(tahun);
  }
}