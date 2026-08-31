import 'package:equatable/equatable.dart';

class LaporanKeuangan extends Equatable {
  final String periode;
  final DateTime startDate;
  final DateTime endDate;
  
  // Pemasukan
  final double totalSimpanan;
  final double totalAngsuran;
  final double totalDenda;
  final double totalBunga; 
  
  // Pengeluaran
  final double totalPinjamanBaru;
  
  // Hasil
  final double totalPemasukan;
  final double totalPengeluaran;
  final double saldoAkhir;
  
  // Detail
  final Map<String, double> simpananPerJenis;
  final int jumlahAnggotaBaru;
  final int jumlahPinjamanAktif;

  const LaporanKeuangan({
    required this.periode,
    required this.startDate,
    required this.endDate,
    required this.totalSimpanan,
    required this.totalAngsuran,
    required this.totalDenda,
    required this.totalPinjamanBaru,
    required this.totalPemasukan,
    required this.totalPengeluaran,
    required this.saldoAkhir,
    required this.totalBunga,
    required this.simpananPerJenis,
    required this.jumlahAnggotaBaru,
    required this.jumlahPinjamanAktif, required double totalSimpananKeluar,
  });

  @override
  List<Object?> get props => [
    periode, startDate, endDate, totalPemasukan, totalPengeluaran, saldoAkhir
  ];
}