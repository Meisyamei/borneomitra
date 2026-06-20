import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/anggota.dart';
import '../repositories/anggota_repository.dart';

class GetAnggotaById {
  final AnggotaRepository repository;

  GetAnggotaById(this.repository);

  Future<Either<Failure, Anggota>> execute(int id) async {
    if (id <= 0) {
      return Left(ValidationFailure('ID anggota tidak valid'));
    }
    return await repository.getAnggotaById(id);
  }
}