import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/pinjaman_repository.dart';

class UpdateStatusPinjaman {
  final PinjamanRepository repository;

  UpdateStatusPinjaman(this.repository);

  Future<Either<Failure, void>> execute(int id, String status) async {
    if (id <= 0) {
      return Left(ValidationFailure('ID pinjaman tidak valid'));
    }
    
    final validStatus = ['aktif', 'lunas', 'menunggak'];
    if (!validStatus.contains(status)) {
      return Left(ValidationFailure('Status tidak valid'));
    }
    
    return await repository.updateStatusPinjaman(id, status);
  }
}