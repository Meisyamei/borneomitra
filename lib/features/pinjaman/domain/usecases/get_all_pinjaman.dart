import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/pinjaman.dart';
import '../repositories/pinjaman_repository.dart';

class GetAllPinjaman {
  final PinjamanRepository repository;

  GetAllPinjaman(this.repository);

  Future<Either<Failure, List<Pinjaman>>> execute() async {
    return await repository.getAllPinjaman();
  }
}