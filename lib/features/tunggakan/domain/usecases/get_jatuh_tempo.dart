import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import '../entities/hampir_jatuh_tempo.dart';
import '../repositories/tunggakan_repository.dart';

class GetJatuhTempo {
  final TunggakanRepository repository;

  GetJatuhTempo(this.repository);

  Future<Either<Failure, List<HampirJatuhTempo>>> execute() async {
    return await repository.getJatuhTempo();
  }
}