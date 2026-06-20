import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/core/utils/date_formatter.dart';
import 'package:Koperasi/features/laporan/domain/entities/laporan.dart';

class LaporanPdf {
  static Future<String> generate(LaporanKeuangan laporan) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Column(
              children: [
                pw.Text(
                  'Koperasi - Borneo Mitra Senjaya',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Laporan Keuangan',
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.Text(
                  'Periode: ${laporan.periode}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                ),
                pw.Divider(),
              ],
            ),
          ),
          
          // Ringkasan Keuangan
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'A. RINGKASAN KEUANGAN',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                _buildRow('Total Simpanan Masuk', NumberFormatter.formatRupiah(laporan.totalSimpanan)),
                _buildRow('Total Angsuran Masuk', NumberFormatter.formatRupiah(laporan.totalAngsuran)),
                _buildRow('Total Denda', NumberFormatter.formatRupiah(laporan.totalDenda)),
                _buildRow('Total Pemasukan', NumberFormatter.formatRupiah(laporan.totalPemasukan), isBold: true),
                _buildRow('Total Pinjaman Keluar', NumberFormatter.formatRupiah(laporan.totalPinjamanBaru)),
                pw.Divider(),
                _buildRow('Saldo Akhir', NumberFormatter.formatRupiah(laporan.saldoAkhir), isBold: true),
              ],
            ),
          ),
          
          // Detail Simpanan per Jenis
          if (laporan.simpananPerJenis.isNotEmpty)
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'B. DETAIL SIMPANAN PER JENIS',
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  _buildRow('Simpanan Wajib', NumberFormatter.formatRupiah(laporan.simpananPerJenis['wajib'] ?? 0)),
                  _buildRow('Simpanan Sukarela', NumberFormatter.formatRupiah(laporan.simpananPerJenis['sukarela'] ?? 0)),
                  _buildRow('Simpanan Pokok', NumberFormatter.formatRupiah(laporan.simpananPerJenis['pokok'] ?? 0)),
                ],
              ),
            ),
          
          // Informasi Tambahan
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'C. INFORMASI TAMBAHAN',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                _buildRow('Jumlah Anggota Baru', '${laporan.jumlahAnggotaBaru} anggota'),
                _buildRow('Jumlah Pinjaman Aktif', '${laporan.jumlahPinjamanAktif} pinjaman'),
              ],
            ),
          ),
          
          // Footer
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 40),
            child: pw.Column(
              children: [
                pw.Divider(),
                pw.SizedBox(height: 10),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('Mengetahui,', style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 30),
                        pw.Text('Ketua Koperasi', style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Banjarmasin, ${DateFormatter.formatDate(DateTime.now())}', 
                            style: pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 30),
                        pw.Text('Admin Koperasi', style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          pw.SizedBox(height: 20),
          pw.Text(
            '* Laporan ini digenerate secara otomatis oleh sistem BMSS Koperasi',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey),
          ),
        ],
      ),
    );

    final output = await getTemporaryDirectory();
    final filePath = '${output.path}/laporan_keuangan_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    
    return filePath;
  }

  static pw.Widget _buildRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 11)),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}