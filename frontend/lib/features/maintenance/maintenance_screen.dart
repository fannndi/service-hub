import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/config/config_service.dart';

class MaintenanceScreen extends StatefulWidget {
  final String message;
  final bool isOffline;

  const MaintenanceScreen({
    super.key,
    required this.message,
    this.isOffline = false,
  });

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  Timer? _retryTimer;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _startAutoRetry();
  }

  void _startAutoRetry() {
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _retryConnection();
    });
  }

  Future<void> _retryConnection() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);

    try {
      final config = await ConfigService.fetch();
      if (!config.maintenanceMode && mounted) {
        Navigator.of(context).pushReplacementNamed('/splash');
      }
    } catch (_) {
      // Still offline or maintenance, keep showing
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[50],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isOffline ? Icons.wifi_off : Icons.build,
                  size: 100,
                  color: Colors.orange,
                ),
                const SizedBox(height: 24),
                Text(
                  widget.isOffline
                      ? 'Koneksi Tidak Ditemukan'
                      : 'Sedang Maintenance',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _retryConnection,
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(_isRetrying ? 'Mencoba...' : 'Coba Lagi'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Auto-retry tiap 30 detik',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
