import 'package:flutter/material.dart';
import 'package:Koperasi/features/arisan/services/arisan_service.dart';
import 'package:Koperasi/features/anggota/domain/entities/anggota.dart';
import 'package:Koperasi/features/anggota/domain/usecases/get_all_anggota.dart';
import 'package:Koperasi/injection_container.dart';

class TambahPesertaPage extends StatefulWidget {
  final int arisanId;

  const TambahPesertaPage({super.key, required this.arisanId});

  @override
  State<TambahPesertaPage> createState() => _TambahPesertaPageState();
}

class _TambahPesertaPageState extends State<TambahPesertaPage> {
  final ArisanService _arisanService = ArisanService();
  List<Anggota> _anggotaList = [];
  List<Anggota> _filteredList = [];
  List<int> _selectedAnggotaIds = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAnggota();
  }

  Future<void> _loadAnggota() async {
    setState(() => _isLoading = true);
    final result = await sl<GetAllAnggota>().execute();
    result.fold(
      (failure) => _showError('Gagal load anggota: ${failure.message}'),
      (anggota) {
        setState(() {
          _anggotaList = anggota;
          _filteredList = anggota;
          _isLoading = false;
        });
      },
    );
  }

  void _filterAnggota(String query) {
    setState(() {
      _filteredList = _anggotaList
          .where((a) => a.nama.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleSelection(Anggota anggota) {
    setState(() {
      if (_selectedAnggotaIds.contains(anggota.id)) {
        _selectedAnggotaIds.remove(anggota.id);
      } else {
        _selectedAnggotaIds.add(anggota.id!);
      }
    });
  }

  Future<void> _savePeserta() async {
    if (_selectedAnggotaIds.isEmpty) {
      _showError('Pilih minimal 1 anggota');
      return;
    }

    setState(() => _isSaving = true);

    // 🔴 PERBAIKI: Ganti getPesertaWithPayment → getPeserta
    final existingPeserta = await _arisanService.getPeserta(widget.arisanId);
    int nextNomor = existingPeserta.length + 1;

    for (var anggotaId in _selectedAnggotaIds) {
      await _arisanService.addPeserta(widget.arisanId, anggotaId, nextNomor);
      nextNomor++;
    }

    setState(() => _isSaving = false);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Peserta Arisan'),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari anggota...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterAnggota,
            ),
          ),

          // Info selection
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_selectedAnggotaIds.length} anggota dipilih',
              style: const TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 8),

          // List Anggota
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredList.isEmpty
                    ? const Center(child: Text('Tidak ada anggota'))
                    : ListView.builder(
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final anggota = _filteredList[index];
                          final isSelected = _selectedAnggotaIds.contains(anggota.id);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(anggota),
                            title: Text(anggota.nama),
                            subtitle: Text('NIK: ${anggota.nik}'),
                            secondary: CircleAvatar(
                              backgroundColor: isSelected ? Colors.purple : Colors.grey.shade300,
                              child: Text(
                                anggota.nama.substring(0, 1).toUpperCase(),
                                style: TextStyle(color: isSelected ? Colors.white : Colors.black54),
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.trailing,
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isSaving ? null : _savePeserta,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.purple,
            ),
            child: _isSaving
                ? const CircularProgressIndicator()
                : Text(
                    'Tambahkan ${_selectedAnggotaIds.length} Peserta',
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ),
      ),
    );
  }
}