import 'package:equatable/equatable.dart';

class Angsuran extends Equatable {
  final int? id;
  final int pinjamanId;
  final int angsuranKe;
  final double nominal;
  final double denda;
  final DateTime tanggalJatuhTempo;
  final DateTime? tanggalBayar;
  final String status;
  final String? namaAnggota;
  final double? jumlahPinjaman;

  const Angsuran({
    this.id,
    required this.pinjamanId,
    required this.angsuranKe,
    required this.nominal,
    this.denda = 0,
    required this.tanggalJatuhTempo,
    this.tanggalBayar,
    this.status = 'belum_bayar',
    this.namaAnggota,
    this.jumlahPinjaman,
  });

  bool get isLunas => status == 'lunas';
  
  bool get isTerlambat {
    if (isLunas) return false;
    return DateTime.now().isAfter(tanggalJatuhTempo);
  }

  int get hariTerlambat {
    if (isLunas || !isTerlambat) return 0;
    return DateTime.now().difference(tanggalJatuhTempo).inDays;
  }

  double get totalHarusBayar {
    return nominal + denda;
  }

  @override
  List<Object?> get props => [
    id, 
    pinjamanId, 
    angsuranKe, 
    nominal, 
    denda, 
    tanggalJatuhTempo, 
    tanggalBayar, 
    status,
    namaAnggota,
    jumlahPinjaman,
  ];
}