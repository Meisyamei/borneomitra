import 'package:flutter/material.dart';
import 'package:Koperasi/core/services/database_service.dart';  // ← TAMBAHKAN INI
import '../../domain/entities/anggota.dart';
import '../../domain/usecases/get_all_anggota.dart';
import '../../domain/usecases/delete_anggota.dart';
import 'package:Koperasi/features/anggota/domain/usecases/search_anggota.dart';
import 'tambah_anggota_page.dart';
import 'detail_anggota_page.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../injection_container.dart';

class AnggotaPage extends StatefulWidget {
  const AnggotaPage({super.key});

  @override
  State<AnggotaPage> createState() => _AnggotaPageState();
}

class _AnggotaPageState extends State<AnggotaPage> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();  // ← TAMBAHKAN INI
  
  List<Anggota> _anggotaList = [];
  List<Anggota> _filteredList = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAnggota();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    _performSearch();
  }

  // ← TAMBAHAN: Debug untuk cek data di database
  Future<void> _debugCheckDatabase() async {
    try {
      final db = await _dbService.database;
      final allData = await db.query('anggota');
      print('📊 ===== CEK DATABASE ANGGOTA =====');
      print('📊 Total data di database: ${allData.length}');
      for (var row in allData) {
        print('📊 ID: ${row['id']}, Nama: ${row['nama']}, NIK: ${row['nik']}');
      }
      print('📊 ===== END CEK DATABASE =====');
    } catch (e) {
      print('❌ Error cek database: $e');
    }
  }

  Future<void> _performSearch() async {
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredList = _anggotaList;
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final result = await sl<SearchAnggota>().execute(_searchQuery);
    
    result.fold(
      (failure) {
        _showError('Gagal mencari: ${failure.message}');
        setState(() {
          _filteredList = [];
          _isSearching = false;
        });
      },
      (anggota) {
        setState(() {
          _filteredList = anggota;
          _isSearching = false;
        });
      },
    );
  }

  void _resetSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filteredList = _anggotaList;
    });
  }

  Future<void> _loadAnggota() async {
    setState(() => _isLoading = true);
    
    // ← TAMBAHAN: Debug cek database sebelum load
    await _debugCheckDatabase();
    
    final result = await sl<GetAllAnggota>().execute();
    result.fold(
      (failure) {
        _showError('Gagal load data: ${failure.message}');
        print('❌ Error load anggota: ${failure.message}');
      },
      (anggota) {
        print('✅ Anggota loaded: ${anggota.length} data');
        for (var a in anggota) {
          print('✅ ${a.nama} - ${a.nik} - Total Simpanan: ${a.totalSimpanan}');
        }
        setState(() {
          _anggotaList = anggota;
          _filteredList = anggota;
          _isLoading = false;
        });
      },
    );
  }

  Future<void> _deleteAnggota(int id, String nama) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Anggota'),
        content: Text('Apakah Anda yakin ingin menghapus anggota "$nama"?'),
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
      final result = await sl<DeleteAnggota>().execute(id);
      result.fold(
        (failure) => _showError('Gagal hapus: ${failure.message}'),
        (_) {
          _showSuccess('Anggota berhasil dihapus');
          _loadAnggota();
        },
      );
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isLoading = false);
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
        title: const Text('Data Anggota'),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _resetSearch,
              tooltip: 'Reset Pencarian',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnggota,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau NIK...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          if (_searchQuery.isNotEmpty && !_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Menampilkan ${_filteredList.length} hasil untuk "$_searchQuery"',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          
          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text('Total Anggota'),
                          Text(
                            '${_filteredList.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Text('Total Simpanan'),
                          Text(
                            NumberFormatter.formatRupiah(
                              _filteredList.fold(0, (sum, a) => sum + a.totalSimpanan),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // List Anggota
          Expanded(
            child: _isLoading || _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty 
                                  ? 'Tidak ada data anggota' 
                                  : 'Tidak ada anggota dengan nama "$_searchQuery"',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final anggota = _filteredList[index];
                          return AnggotaCard(
                            anggota: anggota,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailAnggotaPage(anggota: anggota),
                                ),
                              );
                              if (result == true) _loadAnggota();
                            },
                            onDelete: () => _deleteAnggota(anggota.id!, anggota.nama),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TambahAnggotaPage()),
          );
          if (result == true) _loadAnggota();
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Anggota'),
      ),
    );
  }
}

// Anggota Card Widget (SAMA SEPERTI SEBELUMNYA, TIDAK BERUBAH)
class AnggotaCard extends StatelessWidget {
  final Anggota anggota;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AnggotaCard({
    super.key,
    required this.anggota,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  anggota.nama.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anggota.nama,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIK: ${anggota.nik}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'No HP: ${anggota.noHp}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.savings, size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          NumberFormatter.formatRupiah(anggota.totalSimpanan),
                          style: const TextStyle(fontSize: 12, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.credit_card, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          NumberFormatter.formatRupiah(anggota.totalPinjaman),
                          style: const TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: anggota.isAktif ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      anggota.isAktif ? 'Aktif' : 'Non-Aktif',
                      style: TextStyle(
                        fontSize: 10,
                        color: anggota.isAktif ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
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