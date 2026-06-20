import 'package:dartz/dartz.dart';
import 'package:Koperasi/core/errors/failures.dart';
import '../entities/laporan.dart';
import '../repositories/laporan_repository.dart';

class ExportLaporanPdf {
  final LaporanRepository repository;

  ExportLaporanPdf(this.repository);

  Future<Either<Failure, String>> execute(LaporanKeuangan laporan) async {
    return await repository.exportToPdf(laporan);
  }
}