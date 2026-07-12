import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<Map<String, dynamic>> _diaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  Future<void> _loadDiaries() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Lấy couple_id trước
      final coupleResponse = await Supabase.instance.client
          .from('couples')
          .select('id')
          .or('user1_id.eq.${user.id},user2_id.eq.${user.id}')
          .eq('status', 'active')
          .maybeSingle();

      if (coupleResponse == null) return;

      final coupleId = coupleResponse['id'];

      // Lấy danh sách nhật ký
      final response = await Supabase.instance.client
          .from('diaries')
          .select('*, users(full_name)')
          .eq('couple_id', coupleId)
          .order('created_at', ascending: false);

      setState(() {
        _diaries = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Lỗi load diaries: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật ký'),
        backgroundColor: Colors.pink[100],
        actions: [
          IconButton(
            onPressed: _showAddDiaryDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _diaries.isEmpty
              ? const Center(child: Text('Chưa có nhật ký nào, hãy viết ngay!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _diaries.length,
                  itemBuilder: (context, index) {
                    final diary = _diaries[index];
                    final date = DateTime.parse(diary['created_at']);
                    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
                    final userName = diary['users']?['full_name'] ?? '...';

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
                                  radius: 16,
                                  backgroundColor: Colors.pink[100],
                                  child: Text(
                                    userName.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(fontSize: 14, color: Colors.pink),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  userName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                Text(
                                  formattedDate,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (diary['image'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  diary['image'],
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 150,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  ),
                                ),
                              ),
                            if (diary['image'] != null) const SizedBox(height: 8),
                            Text(
                              diary['content'] ?? '',
                              style: const TextStyle(fontSize: 15),
                            ),
                            if (diary['emotion'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.sentiment_satisfied, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    diary['emotion'],
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.favorite_border, size: 18),
                                ),
                                Text('${diary['likes'] ?? 0}'),
                                const SizedBox(width: 16),
                                IconButton(
                                  onPressed: () {},
                                  icon: const Icon(Icons.comment_outlined, size: 18),
                                ),
                                Text('${diary['comments'] ?? 0}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDiaryDialog,
        backgroundColor: Colors.pink[300],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDiaryDialog() {
    final contentController = TextEditingController();
    String selectedEmotion = '❤️ Yêu';

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
              'Viết nhật ký mới',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Hôm nay thế nào?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Cảm xúc:'),
            Wrap(
              spacing: 8,
              children: ['❤️ Yêu', '😊 Vui', '😢 Nhớ', '😤 Hờn', '🥰 Thương'].map((e) {
                return ChoiceChip(
                  label: Text(e),
                  selected: selectedEmotion == e,
                  onSelected: (v) => setState(() => selectedEmotion = e),
                  selectedColor: Colors.pink[100],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final content = contentController.text.trim();
                  if (content.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng nhập nội dung')),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  // Lưu lên Supabase (sẽ viết sau)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã thêm nhật ký!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[300],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Đăng', style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}