import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/pinjaman_repository.dart';

class UpdateSisaPinjaman {
  final PinjamanRepository repository;

  UpdateSisaPinjaman(this.repository);

  Future<Either<Failure, void>> execute(int id, double sisaBaru) async {
    if (id <= 0) {
      return Left(ValidationFailure('ID pinjaman tidak valid'));
    }
    if (sisaBaru < 0) {
      return Left(ValidationFailure('Sisa pinjaman tidak boleh negatif'));
    }
    return await repository.updateSisaPinjaman(id, sisaBaru);
  }
}