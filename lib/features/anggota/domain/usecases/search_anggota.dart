import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/anggota.dart';
import '../repositories/anggota_repository.dart';

class SearchAnggota {
  final AnggotaRepository repository;

  SearchAnggota(this.repository);

  Future<Either<Failure, List<Anggota>>> execute(String keyword) async {
    if (keyword.isEmpty) {
      return Left(ValidationFailure('Keyword pencarian tidak boleh kosong'));
    }
    return await repository.searchAnggota(keyword);
  }
}