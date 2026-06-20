import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/angsuran_repository.dart';

class BayarAngsuran {
  final AngsuranRepository repository;

  BayarAngsuran(this.repository);

  Future<Either<Failure, void>> execute(int angsuranId, DateTime tanggalBayar) async {
    if (angsuranId <= 0) {
      return Left(ValidationFailure('ID angsuran tidak valid'));
    }
    if (tanggalBayar.isAfter(DateTime.now())) {
      return Left(ValidationFailure('Tanggal bayar tidak boleh di masa depan'));
    }
    return await repository.bayarAngsuran(angsuranId, tanggalBayar);
  }
}