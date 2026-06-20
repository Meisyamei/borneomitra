import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/angsuran.dart';
import '../repositories/angsuran_repository.dart';

class GetAngsuranByPinjaman {
  final AngsuranRepository repository;

  GetAngsuranByPinjaman(this.repository);

  Future<Either<Failure, List<Angsuran>>> execute(int pinjamanId) async {
    if (pinjamanId <= 0) {
      return Left(ValidationFailure('ID pinjaman tidak valid'));
    }
    return await repository.getAngsuranByPinjaman(pinjamanId);
  }
}