import 'package:Koperasi/features/arisan/models/peserta_arisan_model.dart';
import 'package:Koperasi/features/arisan/pages/detail_arisan_page.dart';
import 'package:flutter/material.dart';
import 'package:Koperasi/core/utils/number_formatter.dart';
import 'package:Koperasi/core/utils/date_formatter.dart';
import '../models/arisan_model.dart';
import '../services/arisan_service.dart';
import 'tambah_arisan_page.dart';

class ArisanPage extends StatefulWidget {
  const ArisanPage({super.key});

  @override
  State<ArisanPage> createState() => _ArisanPageState();
}

class _ArisanPageState extends State<ArisanPage> {
  final ArisanService _arisanService = ArisanService();
  List<ArisanModel> _arisanList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArisan();
  }

  // 🔴 HAPUS SEMUA METHOD INI (sudah pindah ke service):
  // - getPesertaWithPayment
  // - bayarArisanPerBulan
  // - cekBayarBulan
  // - nextBulan

  Future<void> _loadArisan() async {
    setState(() => _isLoading = true);
    _arisanList = await _arisanService.getAllArisan();
    setState(() => _isLoading = false);
  }

  Future<void> _deleteArisan(int id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Arisan'),
        content: Text('Apakah Anda yakin ingin menghapus arisan "$nama"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _arisanService.deleteArisan(id);
      _loadArisan();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arisan berhasil dihapus'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Arisan'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArisan,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _arisanList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.groups, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Belum ada data arisan'),
                      Text('Tekan tombol + untuk menambah arisan'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _arisanList.length,
                  itemBuilder: (context, index) {
                    final arisan = _arisanList[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: arisan.status == 'aktif' ? Colors.purple : Colors.grey,
                          child: const Icon(Icons.groups, color: Colors.white),
                        ),
                        title: Text(arisan.nama),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Iuran: ${NumberFormatter.formatRupiah(arisan.iuran)}'),
                            Text('Mulai: ${DateFormatter.formatDate(arisan.tanggalMulai)}'),
                            if (arisan.status == 'selesai')
                              const Text('Selesai', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: arisan.status == 'aktif' ? Colors.green : Colors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                arisan.status == 'aktif' ? 'AKTIF' : 'SELESAI',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteArisan(arisan.id!, arisan.nama),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailArisanPage(arisan: arisan),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TambahArisanPage()),
          );
          if (result == true) _loadArisan();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Arisan'),
        backgroundColor: Colors.purple,
      ),
    );
  }
}