import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/core/utils/date_formatter.dart';
import 'package:Koperasi/injection_container.dart';
import 'package:Koperasi/features/laporan/domain/entities/laporan.dart';
import 'package:Koperasi/features/laporan/domain/usecases/get_laporan_harian.dart';
import 'package:Koperasi/features/laporan/domain/usecases/get_laporan_bulanan.dart';
import 'package:Koperasi/features/laporan/domain/usecases/get_laporan_tahunan.dart';
import 'package:Koperasi/features/laporan/domain/usecases/export_laporan_pdf.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  String _selectedType = 'bulanan';
  DateTime _selectedDate = DateTime.now();
  LaporanKeuangan? _laporan;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _laporanTypes = [
    {'value': 'harian', 'label': 'Laporan Harian', 'icon': Icons.today},
    {'value': 'bulanan', 'label': 'Laporan Bulanan', 'icon': Icons.calendar_month},
    {'value': 'tahunan', 'label': 'Laporan Tahunan', 'icon': Icons.calendar_today},
  ];

  // ============ FUNGSI GET PERIOD TEXT ============
  String _getPeriodText() {
    switch (_selectedType) {
      case 'harian':
        return DateFormatter.formatDate(_selectedDate);
      case 'bulanan':
        return '${_selectedDate.month}/${_selectedDate.year}';
      case 'tahunan':
        return '${_selectedDate.year}';
      default:
        return '';
    }
  }
  // ================================================

  Future<void> _generateLaporan() async {
    setState(() => _isLoading = true);

    late final result;

    switch (_selectedType) {
      case 'harian':
        result = await sl<GetLaporanHarian>().execute(_selectedDate);
        break;
      case 'bulanan':
        result = await sl<GetLaporanBulanan>().execute(_selectedDate.month, _selectedDate.year);
        break;
      default:
        result = await sl<GetLaporanTahunan>().execute(_selectedDate.year);
    }

    result.fold(
      (failure) => _showError('Gagal generate laporan: ${failure.message}'),
      (laporan) => setState(() => _laporan = laporan),
    );

    setState(() => _isLoading = false);
  }

  Future<void> _exportPdf() async {
    if (_laporan == null) return;

    final result = await sl<ExportLaporanPdf>().execute(_laporan!);

    result.fold(
      (failure) => _showError('Gagal export PDF: ${failure.message}'),
      (path) => _showSuccess('Laporan PDF berhasil disimpan'),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
        backgroundColor: Colors.blue,
        actions: [
          if (_laporan != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: _exportPdf,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filter Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Jenis Laporan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _laporanTypes.map((type) {
                        final isSelected = _selectedType == type['value'];
                        return ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(type['icon'], size: 16),
                              const SizedBox(width: 4),
                              Text(type['label']),
                            ],
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedType = type['value']);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Pilih Periode - YANG DIPERBAIKI
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(_getPeriodText()),  // ← Sekarang kebaca
                      subtitle: const Text('Klik untuk mengubah periode'),
                      onTap: () async {
                        DateTime? date;
                        if (_selectedType == 'tahunan') {
                          date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDatePickerMode: DatePickerMode.year,
                          );
                        } else {
                          date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                        }
                        if (date != null) {
                          setState(() {
                            _selectedDate = date!;  // ← Sekarang kebaca
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _generateLaporan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text('Generate Laporan', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Hasil Laporan
            if (_laporan != null) ...[
              // Ringkasan Card
              Card(
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Ringkasan Keuangan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow('Total Simpanan Masuk', NumberFormatter.formatRupiah(_laporan!.totalSimpanan), Colors.green),
                      _buildSummaryRow('Total Angsuran Masuk', NumberFormatter.formatRupiah(_laporan!.totalAngsuran), Colors.green),
                      _buildSummaryRow('Total Denda', NumberFormatter.formatRupiah(_laporan!.totalDenda), Colors.orange),
                      const Divider(),
                      _buildSummaryRow('Total Pemasukan', NumberFormatter.formatRupiah(_laporan!.totalPemasukan), Colors.green, isBold: true),
                      const SizedBox(height: 8),
                      _buildSummaryRow('Total Pinjaman Keluar', NumberFormatter.formatRupiah(_laporan!.totalPinjamanBaru), Colors.red),
                      const Divider(),
                      _buildSummaryRow('Saldo Akhir', NumberFormatter.formatRupiah(_laporan!.saldoAkhir), 
                          _laporan!.saldoAkhir >= 0 ? Colors.green : Colors.red, isBold: true, fontSize: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Detail Simpanan per Jenis
              if (_laporan!.simpananPerJenis.isNotEmpty)
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detail Simpanan per Jenis',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        _buildJenisTotal('Wajib', _laporan!.simpananPerJenis['wajib'] ?? 0, Colors.blue),
                        _buildJenisTotal('Sukarela', _laporan!.simpananPerJenis['sukarela'] ?? 0, Colors.green),
                        _buildJenisTotal('Pokok', _laporan!.simpananPerJenis['pokok'] ?? 0, Colors.orange),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Informasi Tambahan
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAdditionalInfo('Anggota Baru', '${_laporan!.jumlahAnggotaBaru}', Icons.person_add, Colors.blue),
                      Container(height: 40, width: 1, color: Colors.grey.shade300),
                      _buildAdditionalInfo('Pinjaman Aktif', '${_laporan!.jumlahPinjamanAktif}', Icons.credit_card, Colors.orange),
                      Container(height: 40, width: 1, color: Colors.grey.shade300),
                      _buildAdditionalInfo('Periode', _laporan!.periode, Icons.calendar_today, Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, {bool isBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJenisTotal(String label, double total, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label),
            ],
          ),
          Text(NumberFormatter.formatRupiah(total)),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}