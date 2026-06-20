import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/angsuran.dart';
import '../repositories/angsuran_repository.dart';

class GetTunggakan {
  final AngsuranRepository repository;

  GetTunggakan(this.repository);

  Future<Either<Failure, List<Angsuran>>> execute() async {
    return await repository.getTunggakan();
  }
}