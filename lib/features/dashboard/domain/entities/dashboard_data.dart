import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class DashboardData extends Equatable {
  // Statistik Anggota
  final int totalAnggota;
  final int anggotaAktif;
  final int anggotaBaruBulanIni;
  
  // Statistik Simpanan
  final double totalSimpanan;
  final double simpananWajib;
  final double simpananSukarela;
  final double simpananPokok;
  final double simpananMasukBulanIni;
  
  // Statistik Pinjaman
  final double totalPinjamanAktif;
  final int jumlahPinjamanAktif;
  final double pinjamanBaruBulanIni;
  final int jumlahPinjamanBaruBulanIni;
  
  // Statistik Pembayaran
  final double angsuranMasukBulanIni;
  final int jumlahAngsuranBulanIni;
  
  // ← TAMBAHKAN: Statistik Tunggakan
  final int totalTunggakan;          
  final int tunggakanKritis;         
  final int hampirJatuhTempo;        
  final int jatuhTempoHariIni;       
  final double nominalTunggakan;
  
  // Transaksi Terbaru
  final List<TransaksiTerbaru> transaksiTerbaru;

  const DashboardData({
    required this.totalAnggota,
    required this.anggotaAktif,
    required this.anggotaBaruBulanIni,
    required this.totalSimpanan,
    required this.simpananWajib,
    required this.simpananSukarela,
    required this.simpananPokok,
    required this.simpananMasukBulanIni,
    required this.totalPinjamanAktif,
    required this.jumlahPinjamanAktif,
    required this.pinjamanBaruBulanIni,
    required this.jumlahPinjamanBaruBulanIni,
    required this.angsuranMasukBulanIni,
    required this.jumlahAngsuranBulanIni,
    required this.totalTunggakan,
    required this.tunggakanKritis,
    required this.hampirJatuhTempo,
    required this.jatuhTempoHariIni,
    required this.nominalTunggakan,
    required this.transaksiTerbaru,
  });

  @override
  List<Object?> get props => [
    totalAnggota, totalSimpanan, totalPinjamanAktif, totalTunggakan
  ];
}

class TransaksiTerbaru extends Equatable {
  final int id;
  final String jenis;
  final String judul;
  final String subtitle;
  final double nominal;
  final DateTime tanggal;
  final String status;

  const TransaksiTerbaru({
    required this.id,
    required this.jenis,
    required this.judul,
    required this.subtitle,
    required this.nominal,
    required this.tanggal,
    required this.status,
  });

  String get jenisDisplay {
    switch (jenis) {
      case 'simpanan': return 'Simpanan';
      case 'angsuran': return 'Angsuran';
      case 'pinjaman': return 'Pinjaman';
      default: return jenis;
    }
  }

  Color get jenisColor {
    switch (jenis) {
      case 'simpanan':
        return Colors.green;
      case 'angsuran':
        return Colors.blue;
      case 'pinjaman':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData get jenisIcon {
    switch (jenis) {
      case 'simpanan':
        return Icons.savings;
      case 'angsuran':
        return Icons.payment;
      case 'pinjaman':
        return Icons.credit_card;
      default:
        return Icons.receipt;
    }
  }

  @override
  List<Object?> get props => [id, jenis, judul, nominal, tanggal];
}