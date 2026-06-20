import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

class HampirJatuhTempo extends Equatable {
  final int anggotaId;
  final String namaAnggota;
  final String nik;
  final int pinjamanId;
  final int angsuranId;
  final int angsuranKe;
  final double nominal;
  final DateTime tanggalJatuhTempo;
  final int hariTersisa;

  const HampirJatuhTempo({
    required this.anggotaId,
    required this.namaAnggota,
    required this.nik,
    required this.pinjamanId,
    required this.angsuranId,
    required this.angsuranKe,
    required this.nominal,
    required this.tanggalJatuhTempo,
    required this.hariTersisa,
  });

  String get statusLabel {
    if (hariTersisa <= 0) return 'LEWAT JATUH TEMPO';
    if (hariTersisa == 1) return 'BESOK JATUH TEMPO';
    if (hariTersisa == 2) return 'LUSA JATUH TEMPO';
    return '${hariTersisa} HARI LAGI';
  }

  Color get statusColor {
    if (hariTersisa <= 0) return Color(0xFFFF0000);
    if (hariTersisa <= 2) return Color(0xFFFFA500);
    return Color(0xFF008000);
  }

  @override
  List<Object?> get props => [
    anggotaId, namaAnggota, pinjamanId, angsuranId, hariTersisa
  ];
}