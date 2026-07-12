import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  String? _partnerId;
  String? _partnerName;
  bool _isLoading = true;
  late final RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _channel.unsubscribe();
    Supabase.instance.client.removeChannel(_channel);
    super.dispose();
  }

  Future<void> _initializeChat() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Lấy thông tin cặp đôi và partner
      final coupleResponse = await Supabase.instance.client
          .from('couples')
          .select('user1_id, user2_id')
          .or('user1_id.eq.${user.id},user2_id.eq.${user.id}')
          .eq('status', 'active')
          .maybeSingle();

      if (coupleResponse == null) {
        setState(() => _isLoading = false);
        return;
      }

      final partnerId = coupleResponse['user1_id'] == user.id
          ? coupleResponse['user2_id']
          : coupleResponse['user1_id'];

      if (partnerId == null) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() => _partnerId = partnerId);

      // Lấy tên partner
      final userResponse = await Supabase.instance.client
          .from('users')
          .select('full_name')
          .eq('id', partnerId)
          .maybeSingle();

      setState(() {
        _partnerName = userResponse?['full_name'] ?? 'Người yêu';
      });

      // Lấy lịch sử tin nhắn
      await _loadMessages();

      // Lắng nghe tin nhắn mới (Realtime)
      _channel = Supabase.instance.client.channel('messages');
      _channel
          .on(
            RealtimeListenTypes.postgresChanges,
            ChannelFilter(
              event: 'INSERT',
              schema: 'public',
              table: 'messages',
            ),
            (payload) {
              final newMessage = payload['new'] as Map<String, dynamic>;
              // Kiểm tra tin nhắn có liên quan đến cặp đôi này không
              if (newMessage['sender_id'] == _partnerId ||
                  newMessage['receiver_id'] == _partnerId) {
                setState(() {
                  _messages.insert(0, newMessage);
                });
              }
            },
          )
          .subscribe();

      setState(() => _isLoading = false);
    } catch (e) {
      print('Lỗi khởi tạo chat: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMessages() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null || _partnerId == null) return;

      final response = await Supabase.instance.client
          .from('messages')
          .select('*, users(full_name)')
          .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        _messages = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print('Lỗi load messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _partnerId == null) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      _messages.insert(0, {
        'sender_id': user.id,
        'receiver_id': _partnerId,
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
        'users': {'full_name': user.userMetadata?['full_name'] ?? 'Tôi'},
      });
      _messageController.clear();
    });

    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_id': user.id,
        'receiver_id': _partnerId,
        'content': text,
      });
    } catch (e) {
      print('Lỗi gửi tin nhắn: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể gửi tin nhắn')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_partnerName ?? 'Chat'),
            const Text(
              'Đang hoạt động',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ],
        ),
        backgroundColor: Colors.pink[100],
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có tin nhắn nào\nHãy gửi lời yêu thương đầu tiên!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            final isMe = msg['sender_id'] ==
                                Supabase.instance.client.auth.currentUser?.id;
                            final date = DateTime.parse(msg['created_at']);
                            final time = DateFormat('HH:mm').format(date);

                            return Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.pink[300] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Text(
                                        msg['users']?['full_name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    const SizedBox(height: 2),
                                    Text(
                                      msg['content'] ?? '',
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black,
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        time,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isMe ? Colors.white70 : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(top: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.emoji_emotions),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Nhấn gì đó...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send, color: Colors.pink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
