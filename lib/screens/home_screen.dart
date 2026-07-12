import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/emotion_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _coupleData;
  String? _partnerName;
  int _daysTogether = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Lấy thông tin cặp đôi
      final response = await Supabase.instance.client
          .from('couples')
          .select('*, user1_id, user2_id')
          .or('user1_id.eq.${user.id},user2_id.eq.${user.id}')
          .eq('status', 'active')
          .maybeSingle();

      if (response != null) {
        setState(() {
          _coupleData = response;
          // Tính số ngày yêu (nếu có start_date)
          if (response['start_date'] != null) {
            final start = DateTime.parse(response['start_date']);
            _daysTogether = DateTime.now().difference(start).inDays;
          }
          // Lấy tên partner
          final partnerId = response['user1_id'] == user.id
              ? response['user2_id']
              : response['user1_id'];
          if (partnerId != null) {
            _getPartnerName(partnerId);
          }
        });
      }
    } catch (e) {
      print('Lỗi load data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getPartnerName(String partnerId) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('full_name')
          .eq('id', partnerId)
          .maybeSingle();
      if (response != null) {
        setState(() => _partnerName = response['full_name'] ?? 'Người yêu');
      }
    } catch (e) {
      setState(() => _partnerName = 'Người yêu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Tên + khoảng cách
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_partnerName ?? 'Người yêu'} & ${_coupleData?['user1_id'] == Supabase.instance.client.auth.currentUser?.id ? 'Tôi' : 'Tôi'}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cách nhau 12km', // Tạm thời
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.pink[100],
                          child: const Icon(Icons.favorite, color: Colors.pink),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Số ngày yêu
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pink[300]!, Colors.pink[100]!],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bên nhau từ ${_coupleData?['start_date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(_coupleData!['start_date'])) : '...'}',
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_daysTogether > 0 ? _daysTogether : 0} ngày yêu nhau',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const Icon(Icons.favorite, color: Colors.white, size: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cảm xúc hôm nay
                    const Text(
                      'Hôm nay bạn thế nào?',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    const EmotionSelector(),
                    const SizedBox(height: 16),
                    // Lịch sự kiện (tạm)
                    const Text(
                      'Lịch sự kiện & ngày lễ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(children: [Text('14/02'), Text('Valentine')]),
                          Column(children: [Text('14/03'), Text('Kỷ niệm')]),
                          Column(children: [Text('20/10'), Text('PN VN')]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nhật ký gần đây
                    const Text(
                      'Nhật ký riêng tư',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.pink[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.menu_book, color: Colors.pink),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '"Hai đứa trú mưa ở quán quen, ăn tô phở nóng..."',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Ảnh gần đây
                    const Text(
                      'Ảnh gần đây',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 5,
                        itemBuilder: (context, index) => Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Chuyển màn tương ứng (sẽ code sau)
        },
      ),
    );
  }
}