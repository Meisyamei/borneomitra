import 'package:flutter/material.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/angsuran.dart';
import 'bayar_angsuran_page.dart';

class AngsuranPage extends StatefulWidget {
  final int? pinjamanId;
  final String? namaAnggota;
  
  const AngsuranPage({super.key, this.pinjamanId, this.namaAnggota});

  @override
  State<AngsuranPage> createState() => _AngsuranPageState();
}

class _AngsuranPageState extends State<AngsuranPage> {
  final DatabaseService _dbService = DatabaseService();
  List<Angsuran> _angsuranList = [];
  bool _isLoading = true;
  String _filterStatus = 'semua';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAngsuran();
  }

  Future<void> _loadAngsuran() async {
    setState(() => _isLoading = true);
    
    final db = await _dbService.database;
    
    String query = '''
      SELECT a.*, p.anggota_id, ag.nama as nama_anggota, p.jumlah as jumlah_pinjaman
      FROM angsuran a
      JOIN pinjaman p ON a.pinjaman_id = p.id
      JOIN anggota ag ON p.anggota_id = ag.id
    ''';
    
    if (widget.pinjamanId != null) {
      query += ' WHERE a.pinjaman_id = ${widget.pinjamanId}';
    }
    
    query += ' ORDER BY a.tanggal_jatuh_tempo DESC';
    
    final result = await db.rawQuery(query);
    
    setState(() {
      _angsuranList = result.map((map) => Angsuran(
        id: map['id'] as int?,
        pinjamanId: map['pinjaman_id'] as int,
        angsuranKe: map['angsuran_ke'] as int,
        nominal: double.parse(map['nominal'].toString()),
        denda: double.parse(map['denda'].toString()),
        tanggalJatuhTempo: DateTime.parse(map['tanggal_jatuh_tempo'].toString()),
        tanggalBayar: map['tanggal_bayar'] == null 
            ? null 
            : DateTime.parse(map['tanggal_bayar'].toString()),
        status: map['status'].toString(),
        namaAnggota: map['nama_anggota'] as String?,
        jumlahPinjaman: map['jumlah_pinjaman'] == null 
            ? null 
            : double.parse(map['jumlah_pinjaman'].toString()),
      )).toList();
      _isLoading = false;
    });
  }

  List<Angsuran> get _filteredList {
    var filtered = _angsuranList;
    
    if (_filterStatus != 'semua') {
      filtered = filtered.where((a) => a.status == _filterStatus).toList();
    }
    
    if (_searchQuery.isNotEmpty && widget.pinjamanId == null) {
      filtered = filtered.where((a) =>
          a.namaAnggota?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false
      ).toList();
    }
    
    return filtered;
  }

  int get _totalBelumBayar {
    return _filteredList.where((a) => a.status == 'belum_bayar').length;
  }

  int get _totalTerlambat {
    return _filteredList.where((a) => a.isTerlambat).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.namaAnggota != null 
            ? 'Angsuran ${widget.namaAnggota}' 
            : 'Data Angsuran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAngsuran,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (widget.pinjamanId == null)
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari nama anggota...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                const SizedBox(height: 12),
                // Filter Chips
                Row(
                  children: [
                    _buildFilterChip('semua', 'Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('belum_bayar', 'Belum Bayar', color: Colors.orange),
                    const SizedBox(width: 8),
                    _buildFilterChip('lunas', 'Lunas', color: Colors.green),
                  ],
                ),
              ],
            ),
          ),
          
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Belum Dibayar',
                    '$_totalBelumBayar',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Terlambat',
                    '$_totalTerlambat',
                    Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Total Angsuran',
                    '${_filteredList.length}',
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Belum ada data angsuran'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final angsuran = _filteredList[index];
                          return AngsuranCard(
                            angsuran: angsuran,
                            onBayar: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BayarAngsuranPage(
                                    angsuranId: angsuran.id!,
                                    pinjamanId: angsuran.pinjamanId,
                                    nominal: angsuran.nominal,
                                    angsuranKe: angsuran.angsuranKe,
                                    tanggalJatuhTempo: angsuran.tanggalJatuhTempo,
                                    namaAnggota: angsuran.namaAnggota,
                                  ),
                                ),
                              );
                              if (result == true) _loadAngsuran();
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, {Color color = Colors.grey}) {
    return FilterChip(
      label: Text(label),
      selected: _filterStatus == value,
      selectedColor: color.withOpacity(0.2),
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// Angsuran Card Widget
class AngsuranCard extends StatelessWidget {
  final Angsuran angsuran;
  final VoidCallback onBayar;

  const AngsuranCard({super.key, required this.angsuran, required this.onBayar});

  @override
  Widget build(BuildContext context) {
    final isLunas = angsuran.isLunas;
    final isTerlambat = angsuran.isTerlambat;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isTerlambat ? Colors.red.shade50 : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isLunas 
                          ? Colors.green 
                          : (isTerlambat ? Colors.red : Colors.orange),
                      child: Text(
                        '${angsuran.angsuranKe}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (angsuran.namaAnggota != null)
                          Text(
                            angsuran.namaAnggota!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        Text(
                          'Jatuh tempo: ${DateFormatter.formatDate(angsuran.tanggalJatuhTempo)}',
                          style: TextStyle(
                            color: isTerlambat ? Colors.red : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isLunas)
                  const Chip(
                    label: Text('LUNAS'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nominal', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      NumberFormatter.formatRupiah(angsuran.nominal),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                if (angsuran.denda > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Denda', style: TextStyle(fontSize: 12, color: Colors.red)),
                      Text(
                        NumberFormatter.formatRupiah(angsuran.denda),
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                if (!isLunas)
                  ElevatedButton(
                    onPressed: onBayar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(80, 32),
                    ),
                    child: const Text('Bayar', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}