import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import '../entities/laporan.dart';
import '../repositories/laporan_repository.dart';

class GetLaporanHarian {
  final LaporanRepository repository;

  GetLaporanHarian(this.repository);

  Future<Either<Failure, LaporanKeuangan>> execute(DateTime tanggal) async {
    if (tanggal.isAfter(DateTime.now())) {
      return Left(ValidationFailure('Tanggal tidak boleh melebihi hari ini'));
    }
    return await repository.getLaporanHarian(tanggal);
  }
}