import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      
      // Di WSL, kadang result-nya empty, anggap connected
      if (result == ConnectivityResult.none) {
        return await _testConnection();
      }
      return result != ConnectivityResult.none;
    } catch (e) {
      print('⚠️ Connectivity error: $e, assuming connected');
      return true;
    }
  }

  Future<bool> _testConnection() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return true;
    }
  }

  // 🔴 PERBAIKI: onConnectivityChanged sekarang mengembalikan List<ConnectivityResult>
  Stream<List<ConnectivityResult>> get connectivityStream {
    return _connectivity.onConnectivityChanged;
  }
}