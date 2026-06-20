import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/anggota_repository.dart';

class DeleteAnggota {
  final AnggotaRepository repository;

  DeleteAnggota(this.repository);

  Future<Either<Failure, void>> execute(int id) async {
    if (id <= 0) {
      return Left(ValidationFailure('ID anggota tidak valid'));
    }
    return await repository.deleteAnggota(id);
  }
}