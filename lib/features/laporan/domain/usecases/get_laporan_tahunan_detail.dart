import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import '../entities/laporan_bulanan.dart';
import '../repositories/laporan_repository.dart';

class GetLaporanTahunanDetail {
  final LaporanRepository repository;

  GetLaporanTahunanDetail(this.repository);

  Future<Either<Failure, LaporanTahunanDetail>> execute(int tahun) async {
    if (tahun < 2000 || tahun > DateTime.now().year) {
      return Left(ValidationFailure('Tahun tidak valid'));
    }
    return await repository.getLaporanTahunanDetail(tahun);
  }
}