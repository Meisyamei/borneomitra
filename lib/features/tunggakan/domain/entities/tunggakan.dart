import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class Tunggakan extends Equatable {
  final int id;
  final int anggotaId;
  final String namaAnggota;
  final String nik;
  final String noHp;
  final int pinjamanId;
  final double jumlahPinjaman;
  final double sisaPinjaman;
  final int jumlahBulanTunggakan;
  final double totalTunggakan;
  final double dendaTotal;
  final DateTime tanggalJatuhTempoTerakhir;
  final String status; // 'ringan', 'sedang', 'kritis'

  const Tunggakan({
    required this.id,
    required this.anggotaId,
    required this.namaAnggota,
    required this.nik,
    required this.noHp,
    required this.pinjamanId,
    required this.jumlahPinjaman,
    required this.sisaPinjaman,
    required this.jumlahBulanTunggakan,
    required this.totalTunggakan,
    required this.dendaTotal,
    required this.tanggalJatuhTempoTerakhir,
    required this.status,
  });

  String get statusDisplay {
    switch (status) {
      case 'ringan':
        return 'Ringan (1-14 hari)';
      case 'sedang':
        return 'Sedang (15-29 hari)';
      case 'kritis':
        return 'Kritis (>30 hari)';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'ringan':
        return Color(0xFFFFA500);
      case 'sedang':
        return Color(0xFFFF6B35); 
      case 'kritis':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int get hariTerlambat {
    return DateTime.now().difference(tanggalJatuhTempoTerakhir).inDays;
  }
  
  @override
  List<Object?> get props => [
    id, anggotaId, namaAnggota, jumlahBulanTunggakan, totalTunggakan, status
  ];
}
