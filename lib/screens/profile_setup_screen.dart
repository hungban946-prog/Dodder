import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_routes.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String _selectedAvatar = '👩';
  final _nameController = TextEditingController();
  String _birthYear = '2000';
  bool _isLoading = false;

  final List<String> _avatars = [
    '👩', '👨', '🧑', '👩‍🦰', '👨‍🦱',
    '🐱', '🐶', '🐰', '🦊', '🐼'
  ];

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên hiển thị')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Cập nhật metadata cho user
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': name,
              'avatar': _selectedAvatar,
              'birth_year': int.parse(_birthYear),
            },
          ),
        );
        // Chuyển sang màn ghép cặp
        Navigator.pushReplacementNamed(context, AppRoutes.pairing);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Tạo hồ sơ của bạn',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thêm ảnh, tên và năm sinh để Dodder biết bạn là ai',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                // Avatar hiện tại
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.pink[50],
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.pink[300]!, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      _selectedAvatar,
                      style: const TextStyle(fontSize: 50),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Nút chụp ảnh / thư viện
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Mở camera
                      },
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Chụp ảnh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[100],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Mở thư viện
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Thư viện'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[100],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'hoặc chọn nhanh một avatar',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                // Grid avatar
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _avatars.map((e) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = e),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedAvatar == e ? Colors.pink[100] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: _selectedAvatar == e ? Colors.pink : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 32)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Tên hiển thị
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên hiển thị',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Năm sinh
                DropdownButtonFormField<String>(
                  value: _birthYear,
                  decoration: const InputDecoration(
                    labelText: 'Năm sinh',
                    border: OutlineInputBorder(),
                  ),
                  items: List.generate(51, (i) => (2005 - i).toString())
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _birthYear = v!),
                ),
                const SizedBox(height: 24),
                // Nút tiếp tục
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Tiếp tục',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Bỏ qua, chuyển sang ghép cặp luôn
                    Navigator.pushReplacementNamed(context, AppRoutes.pairing);
                  },
                  child: const Text('Bỏ qua bước này'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}