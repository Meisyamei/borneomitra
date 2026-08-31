import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/core/utils/date_formatter.dart';
import 'package:Koperasi/features/tunggakan/domain/entities/hampir_jatuh_tempo.dart';

class HampirJatuhTempoCard extends StatelessWidget {
  final HampirJatuhTempo data;
  final VoidCallback onTap;

  const HampirJatuhTempoCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ===== PERBAIKI LOGIKA STATUS =====
    String statusLabel;
    Color statusColor;
    
    if (data.hariTersisa < 0) {
      // Sudah lewat
      statusLabel = 'LEWAT ${data.hariTersisa.abs()} HARI';
      statusColor = Colors.red;
    } else if (data.hariTersisa == 0) {
      statusLabel = 'HARI INI JATUH TEMPO';
      statusColor = Colors.orange;
    } else if (data.hariTersisa == 1) {
      statusLabel = 'BESOK JATUH TEMPO';  // ← PERBAIKI: 1 hari = besok
      statusColor = Colors.orange.shade300;
    } else if (data.hariTersisa == 2) {
      statusLabel = 'LUSA JATUH TEMPO';   // ← PERBAIKI: 2 hari = lusa
      statusColor = Colors.orange.shade200;
    } else {
      statusLabel = '${data.hariTersisa} HARI LAGI';
      statusColor = Colors.green;
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: statusColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.2),
                child: Icon(
                  data.hariTersisa < 0 ? Icons.warning : Icons.timer,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.namaAnggota,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Angsuran ke-${data.angsuranKe} - ${NumberFormatter.formatRupiah(data.nominal)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Jatuh tempo: ${DateFormatter.formatDate(data.tanggalJatuhTempo)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}