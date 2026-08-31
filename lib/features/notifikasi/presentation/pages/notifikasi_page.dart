import 'package:flutter/material.dart';
import 'package:Koperasi/core/services/database_service.dart';
import 'package:Koperasi/features/notifikasi/data/datasources/notifikasi_local_datasource.dart';
import 'package:Koperasi/features/notifikasi/domain/entities/notifikasi.dart';
import 'package:Koperasi/features/notifikasi/services/notifikasi_service.dart';
import 'package:Koperasi/core/utils/date_formatter.dart';
import 'package:Koperasi/features/tunggakan/presentation/pages/tunggakan_page.dart';
import 'package:Koperasi/features/pinjaman/presentation/pages/pinjaman_page.dart';
import 'package:Koperasi/features/angsuran/presentation/pages/angsuran_page.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  final NotifikasiLocalDataSource _notifSource = NotifikasiLocalDataSource(DatabaseService());
  List<Notifikasi> _notifikasiList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifikasi();
  }

  Future<void> _loadNotifikasi() async {
    setState(() => _isLoading = true);
    
    try {
      final notifService = NotifikasiService(DatabaseService());
      await notifService.generateNotifikasi();
    } catch (e) {
      print('⚠️ Error generate: $e');
    }
    
    _notifikasiList = await _notifSource.getAllNotifikasi();
    print('📊 Notifikasi loaded: ${_notifikasiList.length}');
    
    setState(() => _isLoading = false);
  }

  Future<void> _markAsRead(int id) async {
    await _notifSource.markAsRead(id);
    _loadNotifikasi();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifikasi ditandai sudah dibaca'), backgroundColor: Colors.green),
    );
  }

  Future<void> _markAllAsRead() async {
    await _notifSource.markAllAsRead();
    _loadNotifikasi();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Semua notifikasi ditandai sudah dibaca'), backgroundColor: Colors.green),
    );
  }

  // 🔴 PERBAIKI: Hapus notifikasi (hard delete, bukan soft delete)
  Future<void> _deleteNotifikasi(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Notifikasi'),
        content: const Text('Apakah Anda yakin ingin menghapus notifikasi ini?'),
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
      // 🔴 HARD DELETE: Hapus langsung dari database
      final db = await DatabaseService().database;
      await db.delete('notifikasi', where: 'id = ?', whereArgs: [id]);
      
      _loadNotifikasi();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifikasi dihapus'), backgroundColor: Colors.green),
      );
    }
  }

  void _navigateToPage(String judul) {
    Navigator.pop(context);
    
    if (judul.contains('Tunggakan') || judul.contains('Kritis')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TunggakanPage()),
      );
    } else if (judul.contains('Jatuh Tempo')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AngsuranPage()),
      );
    } else if (judul.contains('Hampir')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TunggakanPage()),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifikasiList.where((n) => !n.dibaca).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifikasi'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.blue,
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _markAllAsRead,
              tooltip: 'Tandai semua sudah dibaca',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifikasi,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifikasiList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada notifikasi',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        'Semua aman!',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadNotifikasi,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _notifikasiList.length,
                  itemBuilder: (context, index) {
                    final notif = _notifikasiList[index];
                    final isUnread = !notif.dibaca;
                    
                    return Dismissible(
                      key: Key('${notif.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        _deleteNotifikasi(notif.id);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isUnread ? notif.color.withOpacity(0.1) : Colors.grey.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isUnread 
                              ? BorderSide(color: notif.color, width: 1)
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: notif.color.withOpacity(0.2),
                            child: Text(notif.icon, style: const TextStyle(fontSize: 20)),
                          ),
                          title: Text(
                            notif.judul,
                            style: TextStyle(
                              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notif.pesan),
                              const SizedBox(height: 4),
                              Text(
                                DateFormatter.formatDateTime(notif.tanggal),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isUnread ? Colors.grey.shade700 : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isUnread)
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline, size: 20, color: Colors.green),
                                  onPressed: () => _markAsRead(notif.id),
                                  tooltip: 'Tandai sudah dibaca',
                                ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20, color: Colors.red),
                                onPressed: () => _deleteNotifikasi(notif.id),
                                tooltip: 'Hapus',
                              ),
                            ],
                          ),
                          onTap: () {
                            if (isUnread) {
                              _markAsRead(notif.id);
                            }
                            _navigateToPage(notif.judul);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}