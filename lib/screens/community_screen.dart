import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() => _isLoading = true);
    try {
      // Lấy danh sách bài viết từ bảng community_posts (cần tạo sau)
      final response = await Supabase.instance.client
          .from('community_posts')
          .select('*, users(full_name, avatar)')
          .order('created_at', ascending: false)
          .limit(20);

      setState(() {
        _posts = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Lỗi load community: $e');
      // Nếu chưa có bảng, hiển thị dữ liệu mẫu
      setState(() {
        _posts = [
          {
            'id': '1',
            'content': 'Kỷ niệm 1 năm ngày cưới, cảm ơn vì đã chọn nhau ❤️',
            'users': {'full_name': 'Hà & Nam', 'avatar': '👫'},
            'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
            'likes': 24,
            'comments': 5,
          },
          {
            'id': '2',
            'content': 'Hôm nay trời đẹp, đi dạo phố cùng nhau ☀️',
            'users': {'full_name': 'Chi & Đức', 'avatar': '💑'},
            'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            'likes': 18,
            'comments': 3,
          },
        ];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cộng đồng'),
        backgroundColor: Colors.pink[100],
        actions: [
          IconButton(
            onPressed: _showAddPostDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(child: Text('Chưa có bài viết nào'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    final date = DateTime.parse(post['created_at']);
                    final formattedDate = DateFormat('dd/MM/yyyy - HH:mm').format(date);
                    final userName = post['users']?['full_name'] ?? 'Người dùng';
                    final avatar = post['users']?['avatar'] ?? '👤';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.pink[100],
                                  child: Text(
                                    avatar,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.more_vert, size: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              post['content'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.favorite_border, size: 20),
                                ),
                                Text('${post['likes'] ?? 0}'),
                                const SizedBox(width: 16),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.comment_outlined, size: 20),
                                ),
                                Text('${post['comments'] ?? 0}'),
                                const Spacer(),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.share, size: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showAddPostDialog() {
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chia sẻ với cộng đồng',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy chia sẻ khoảnh khắc đẹp của bạn',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Bạn đang nghĩ gì?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final content = contentController.text.trim();
                  if (content.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập nội dung')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã đăng bài viết!')),
                  );
                  // TODO: Lưu lên Supabase
                  setState(() {
                    _posts.insert(0, {
                      'id': DateTime.now().toString(),
                      'content': content,
                      'users': {
                        'full_name': 'Tôi',
                        'avatar': '👤',
                      },
                      'created_at': DateTime.now().toIso8601String(),
                      'likes': 0,
                      'comments': 0,
                    });
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Đăng',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}