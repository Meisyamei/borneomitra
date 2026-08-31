import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/features/pinjaman/domain/entities/pinjaman.dart';

class PinjamanCard extends StatelessWidget {
  final Pinjaman pinjaman;
  final VoidCallback onTap;

  const PinjamanCard({
    super.key,
    required this.pinjaman,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    switch (pinjaman.status) {
      case 'aktif':
        statusColor = Colors.green;
        statusText = 'Aktif';
        break;
      case 'menunggak':
        statusColor = Colors.red;
        statusText = 'Menunggak';
        break;
      default:
        statusColor = Colors.blue;
        statusText = 'Lunas';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pinjaman.namaAnggota,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jumlah Pinjaman', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          NumberFormatter.formatRupiah(pinjaman.jumlah),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Angsuran/Bulan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          NumberFormatter.formatRupiah(pinjaman.angsuranPerBulan),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tenor', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('${pinjaman.tenor} Bulan', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sisa Pinjaman', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          NumberFormatter.formatRupiah(pinjaman.sisaPinjaman),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: pinjaman.progressPelunasan / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(pinjaman.progressColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    pinjaman.progressDisplay,  // ← PAKAI INI
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: pinjaman.progressColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}