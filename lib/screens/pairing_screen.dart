import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_routes.dart';
import '../services/database_service.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _myCode = '';
  String _partnerCode = '';
  bool _isWaiting = false;

  final TextEditingController _inputCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateMyCode();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputCodeController.dispose();
    super.dispose();
  }

  // Tạo mã ngẫu nhiên 6 ký tự
  void _generateMyCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String code = '';
    for (int i = 0; i < 6; i++) {
      code += chars[random % chars.length];
    }
    setState(() => _myCode = code);
  }

  // Tạo cặp đôi mới (người tạo)
  Future<void> _createCouple() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      await DatabaseService.createCouple(
        user1Id: user.id,
        code: _myCode,
      );
      setState(() => _isWaiting = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo mã, đang chờ người yêu kết nối...')),
      );
      // Bắt đầu lắng nghe realtime để biết khi ghép đôi thành công
      _listenForPairing();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Lắng nghe khi partner nhập mã thành công
  void _listenForPairing() {
    // TODO: dùng Supabase Realtime để lắng nghe bảng couples
    // Tạm thời dùng timer giả lập (sẽ thay bằng realtime sau)
    Future.delayed(const Duration(seconds: 5), () {
      if (_isWaiting) {
        // Nếu đã ghép đôi thành công, chuyển sang màn home
        // Kiểm tra thực tế sẽ dùng realtime
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    });
  }

  // Nhập mã của partner để ghép
  Future<void> _joinCouple() async {
    final code = _inputCodeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã ghép cặp')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      await DatabaseService.joinCouple(
        user2Id: user.id,
        code: code,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ghép cặp thành công! 🎉')),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.home);
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
      appBar: AppBar(
        title: const Text('Kết sợi tơ hồng'),
        backgroundColor: Colors.pink[100],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tạo ID'),
            Tab(text: 'Nhập ID người yêu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Tạo ID
          _buildCreateTab(),
          // Tab 2: Nhập ID
          _buildJoinTab(),
        ],
      ),
    );
  }

  Widget _buildCreateTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.link, size: 80, color: Colors.pink),
          const SizedBox(height: 16),
          const Text(
            'Tạo mã mời người yêu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mã có hiệu lực 24 giờ, chỉ dùng một lần',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.pink[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.pink[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _myCode,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    // Sao chép mã
                    // TODO: dùng Clipboard
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Đã sao chép mã')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (_isWaiting) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Đang chờ người ấy kết nối...'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _isWaiting = false;
                  _generateMyCode();
                });
              },
              child: const Text('Hủy ghép'),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createCouple,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Tạo mã mời',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJoinTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.input, size: 80, color: Colors.pink),
          const SizedBox(height: 16),
          const Text(
            'Nhập mã của người yêu',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhập mã mà người ấy chia sẻ để kết nối',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _inputCodeController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
            decoration: InputDecoration(
              hintText: 'VD: TH-8823',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              // Tự động chuyển sang chữ hoa
              if (value.isNotEmpty) {
                _inputCodeController.text = value.toUpperCase();
                _inputCodeController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _inputCodeController.text.length),
                );
              }
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _joinCouple,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[300],
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Kết nối',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}