import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/core/utils/date_formatter.dart';
import 'package:Koperasi/injection_container.dart';
import 'package:Koperasi/features/laporan/domain/entities/laporan.dart';
import 'package:Koperasi/features/laporan/domain/entities/laporan_bulanan.dart';
import 'package:Koperasi/features/laporan/domain/usecases/get_laporan_harian.dart';
import 'package:Koperasi/features/laporan/domain/usecases/get_laporan_bulanan.dart';
import 'package:Koperasi/features/laporan/domain/usecases/get_laporan_tahunan.dart';
import 'package:Koperasi/features/laporan/domain/usecases/export_laporan_pdf.dart';
import 'package:Koperasi/features/laporan/domain/usecases/get_laporan_tahunan_detail.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({super.key});

  @override
  State<LaporanPage> createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  String _selectedType = 'bulanan';
  DateTime _selectedDate = DateTime.now();
  LaporanKeuangan? _laporan;
  LaporanTahunanDetail? _laporanTahunanDetail;
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

  // ============ GENERATE LAPORAN ============
  Future<void> _generateLaporan() async {
    setState(() => _isLoading = true);

    if (_selectedType == 'tahunan') {
      // Laporan Tahunan Detail
      final result = await sl<GetLaporanTahunanDetail>().execute(_selectedDate.year);
      result.fold(
        (failure) => _showError('Gagal generate laporan: ${failure.message}'),
        (data) => setState(() {
          _laporanTahunanDetail = data;
          _laporan = null;
        }),
      );
    } else {
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
        (laporan) => setState(() {
          _laporan = laporan;
          _laporanTahunanDetail = null;
        }),
      );
    }

    setState(() => _isLoading = false);
  }

  // ============ EXPORT PDF ============
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

  // ============ BUILD ============
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== FILTER CARD =====
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Jenis Laporan
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
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

                    // Pilih Periode
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(_getPeriodText()),
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
                            _selectedDate = date!;
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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

            // ===== HASIL LAPORAN =====

            // ---- LAPORAN HARIAN / BULANAN ----
            if (_laporan != null) ...[
              // Ringkasan Card
              Card(
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Ringkasan Keuangan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSummaryRow(
                        'Saldo Simpanan',
                        NumberFormatter.formatRupiah(_laporan!.totalSimpanan),
                        Colors.blue,
                        isBold: true,
                      ),
                      const Divider(),
                      _buildSummaryRow(
                        'Total Angsuran Masuk',
                        NumberFormatter.formatRupiah(_laporan!.totalAngsuran),
                        Colors.green,
                      ),
                      _buildSummaryRow(
                        'Total Denda',
                        NumberFormatter.formatRupiah(_laporan!.totalDenda),
                        Colors.orange,
                      ),
                      const Divider(),
                      _buildSummaryRow(
                        'Total Bunga Pinjaman',
                        NumberFormatter.formatRupiah(_laporan!.totalBunga),
                        Colors.purple,
                        isBold: true,
                      ),
                      _buildSummaryRow(
                        'Total Pemasukan',
                        NumberFormatter.formatRupiah(_laporan!.totalPemasukan),
                        Colors.green,
                        isBold: true,
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'Total Pinjaman Keluar',
                        NumberFormatter.formatRupiah(_laporan!.totalPinjamanBaru),
                        Colors.red,
                      ),
                      const Divider(),
                      _buildSummaryRow(
                        'Saldo Akhir',
                        NumberFormatter.formatRupiah(_laporan!.saldoAkhir),
                        _laporan!.saldoAkhir >= 0 ? Colors.green : Colors.red,
                        isBold: true,
                        fontSize: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Detail Simpanan per Jenis
              if (_laporan!.simpananPerJenis.isNotEmpty)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detail Simpanan per Jenis',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildJenisTotal(
                          'Sukarela',
                          _laporan!.simpananPerJenis['sukarela'] ?? 0,
                          Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Informasi Tambahan
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildAdditionalInfo(
                        'Anggota Baru',
                        '${_laporan!.jumlahAnggotaBaru}',
                        Icons.person_add,
                        Colors.blue,
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      _buildAdditionalInfo(
                        'Pinjaman Aktif',
                        '${_laporan!.jumlahPinjamanAktif}',
                        Icons.credit_card,
                        Colors.orange,
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: Colors.grey.shade300,
                      ),
                      _buildAdditionalInfo(
                        'Periode',
                        _laporan!.periode,
                        Icons.calendar_today,
                        Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // ---- LAPORAN TAHUNAN DETAIL ----
            if (_laporanTahunanDetail != null) ...[
              _buildTahunanDetailCard(_laporanTahunanDetail!),
            ],
          ],
        ),
      ),
    );
  }

  // ============ BUILD SUMMARY ROW ============
  Widget _buildSummaryRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
    double fontSize = 14,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color,
                fontSize: fontSize,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============ BUILD JENIS TOTAL ============
  Widget _buildJenisTotal(String label, double total, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label),
          ),
          Text(
            NumberFormatter.formatRupiah(total),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ============ BUILD ADDITIONAL INFO ============
  Widget _buildAdditionalInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ============ BUILD LAPORAN TAHUNAN DETAIL ============
  Widget _buildTahunanDetailCard(LaporanTahunanDetail data) {
    return Column(
      children: [
        // Header Tahun
        Card(
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '📊 Laporan Tahunan ${data.tahun}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem(
                      'Total Pemasukan',
                      NumberFormatter.formatRupiah(data.totalPemasukanTahun),
                      Colors.green,
                    ),
                    _buildSummaryItem(
                      'Total Pengeluaran',
                      NumberFormatter.formatRupiah(data.totalPengeluaranTahun),
                      Colors.red,
                    ),
                    _buildSummaryItem(
                      'Saldo Akhir',
                      NumberFormatter.formatRupiah(data.saldoAkhirTahun),
                      data.saldoAkhirTahun >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'Anggota Baru: ${data.totalAnggotaBaruTahun} orang',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Detail Per Bulan
        const Text(
          '📋 Detail Per Bulan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.dataPerBulan.length,
          itemBuilder: (context, index) {
            final bulan = data.dataPerBulan[index];
            return _buildBulanCard(bulan);
          },
        ),
      ],
    );
  }

  // ============ BUILD BULAN CARD ============
  Widget _buildBulanCard(LaporanBulanan bulan) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          radius: 18,
          child: Text(
            bulan.namaBulan.substring(0, 3),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          bulan.namaBulan,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Pemasukan: ${NumberFormatter.formatRupiah(bulan.totalPemasukan)} | Saldo: ${NumberFormatter.formatRupiah(bulan.saldoAkhir)}',
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildBulanRow(
                  'Total Setoran',
                  NumberFormatter.formatRupiah(bulan.totalSimpananMasuk),
                  Colors.green,
                ),
                _buildBulanRow(
                  'Total Penarikan',
                  NumberFormatter.formatRupiah(bulan.totalSimpananKeluar),
                  Colors.red,
                ),
                _buildBulanRow(
                  'Saldo Simpanan',
                  NumberFormatter.formatRupiah(bulan.totalSimpanan),
                  Colors.blue,
                  isBold: true,
                ),
                const Divider(),
                _buildBulanRow(
                  'Total Angsuran',
                  NumberFormatter.formatRupiah(bulan.totalAngsuran),
                  Colors.green,
                ),
                _buildBulanRow(
                  'Total Bunga',
                  NumberFormatter.formatRupiah(bulan.totalBunga),
                  Colors.purple,
                ),
                _buildBulanRow(
                  'Total Denda',
                  NumberFormatter.formatRupiah(bulan.totalDenda),
                  Colors.orange,
                ),
                const Divider(),
                _buildBulanRow(
                  'Total Pinjaman Keluar',
                  NumberFormatter.formatRupiah(bulan.totalPinjamanBaru),
                  Colors.red,
                ),
                const Divider(),
                _buildBulanRow(
                  'Anggota Baru',
                  '${bulan.jumlahAnggotaBaru} orang',
                  Colors.blue,
                ),
                _buildBulanRow(
                  'Saldo Akhir',
                  NumberFormatter.formatRupiah(bulan.saldoAkhir),
                  bulan.saldoAkhir >= 0 ? Colors.green : Colors.red,
                  isBold: true,
                  fontSize: 15,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============ BUILD BULAN ROW ============
  Widget _buildBulanRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
    double fontSize = 13,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
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

  // ============ BUILD SUMMARY ITEM ============
  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}