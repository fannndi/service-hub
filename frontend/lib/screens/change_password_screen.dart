import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Password')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          Text('Ubah Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          SizedBox(height: 12),
          Text('Acuan auth: setelah berhasil, sesi lama harus invalid.'),
          SizedBox(height: 20),
          TextField(obscureText: true, decoration: InputDecoration(labelText: 'Password lama / awal', border: OutlineInputBorder())),
          SizedBox(height: 12),
          TextField(obscureText: true, decoration: InputDecoration(labelText: 'Password baru', border: OutlineInputBorder())),
          SizedBox(height: 12),
          TextField(obscureText: true, decoration: InputDecoration(labelText: 'Konfirmasi password baru', border: OutlineInputBorder())),
          SizedBox(height: 20),
          FilledButton(onPressed: null, child: Text('Simpan dummy belum aktif')),
        ],
      ),
    );
  }
}
