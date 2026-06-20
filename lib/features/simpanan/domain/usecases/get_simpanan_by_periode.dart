import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import 'package:Koperasi/features/simpanan/domain/entities/simpanan.dart';
import 'package:Koperasi/features/simpanan/domain/repositories/simpanan_repository.dart';

class GetSimpananByPeriode {
  final SimpananRepository repository;

  GetSimpananByPeriode(this.repository);

  Future<Either<Failure, List<Simpanan>>> execute(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (startDate.isAfter(endDate)) {
      return Left(ValidationFailure('Tanggal mulai tidak boleh setelah tanggal akhir'));
    }
    return await repository.getSimpananByPeriode(startDate, endDate);
  }
}