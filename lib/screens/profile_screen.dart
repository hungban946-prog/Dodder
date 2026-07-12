import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _coupleData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Lấy thông tin user từ bảng users (hoặc từ metadata)
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('*')
          .eq('id', user.id)
          .maybeSingle();

      setState(() {
        _userData = userResponse ?? {
          'full_name': user.userMetadata?['full_name'] ?? 'Người dùng',
          'avatar': user.userMetadata?['avatar'] ?? '👤',
          'birth_year': user.userMetadata?['birth_year'] ?? '2000',
        };
      });

      // Lấy thông tin cặp đôi
      final coupleResponse = await Supabase.instance.client
          .from('couples')
          .select('*, user1_id, user2_id')
          .or('user1_id.eq.${user.id},user2_id.eq.${user.id}')
          .eq('status', 'active')
          .maybeSingle();

      setState(() {
        _coupleData = coupleResponse;
      });
    } catch (e) {
      print('Lỗi load profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Supabase.instance.client.auth.signOut();
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá nhân'),
        backgroundColor: Colors.pink[100],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar + tên
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.pink[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.pink[100],
                          child: Text(
                            _userData?['avatar'] ?? '👤',
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _userData?['full_name'] ?? 'Người dùng',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_coupleData != null)
                                Text(
                                  'Đã kết sợi với ${_coupleData?['user1_id'] == Supabase.instance.client.auth.currentUser?.id ? 'người yêu' : 'người yêu'}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.edit),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Các mục cài đặt
                  _buildMenuItem(
                    icon: Icons.person,
                    title: 'Hồ sơ',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.palette,
                    title: 'Đổi giao diện',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.notifications,
                    title: 'Thông báo',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.lock,
                    title: 'Bảo mật',
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    icon: Icons.code,
                    title: 'Mã ghép cặp',
                    onTap: () {
                      // Hiển thị mã hiện tại
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Mã ghép cặp'),
                          content: Text(
                            _coupleData?['pair_code'] ?? 'Chưa có mã',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Đóng'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(height: 32),
                  // Nút đăng xuất
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Đăng xuất',
                    onTap: _logout,
                    color: Colors.red,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.black,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}