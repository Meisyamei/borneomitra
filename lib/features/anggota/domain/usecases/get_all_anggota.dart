import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/anggota.dart';
import '../repositories/anggota_repository.dart';

class GetAllAnggota {
  final AnggotaRepository repository;
  
  GetAllAnggota(this.repository);
  
  Future<Either<Failure, List<Anggota>>> execute() async {
    return await repository.getAllAnggota();
  }
}