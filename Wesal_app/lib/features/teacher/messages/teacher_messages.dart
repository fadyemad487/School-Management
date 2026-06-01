import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import 'dart:async';

class TeacherMessages extends StatefulWidget {
  final VoidCallback? onConversationOpened;

  const TeacherMessages({super.key, this.onConversationOpened});

  @override
  State<TeacherMessages> createState() => _TeacherMessagesState();
}

class _TeacherMessagesState extends State<TeacherMessages> {
  final ApiClient _apiClient = ApiClient();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isLoading = true;
  StreamSubscription? _socketSubscription;

  List<dynamic> _conversations = [];
  List<dynamic> _availableContacts = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _setupSocketListener();
    _fetchData();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupSocketListener() {
    _socketSubscription = SocketService().onEvent.listen((eventData) {
      final event = eventData['event'] ?? '';

      if (event == 'message:new') {
        // Refresh conversations when new message arrives
        _fetchData();
      } else if (event == 'conversation:updated') {
        // Refresh conversations when conversation is updated
        _fetchData();
      }
    });
  }

  Future<void> _initializeNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(settings);
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      print('🔍 [TeacherMessages] Fetching conversations...');
      final convRes = await _apiClient.client.get('/conversations');
      print('🔍 [TeacherMessages] Conversations response: ${convRes.statusCode} - ${convRes.data}');
      
      if (convRes.data['success'] == true) {
        _conversations = convRes.data['data'] as List;
        print('✅ [TeacherMessages] Conversations loaded: ${_conversations.length}');
      } else {
        print('❌ [TeacherMessages] Conversations failed: ${convRes.data}');
      }

      print('🔍 [TeacherMessages] Fetching contacts...');
      final contactsRes = await _apiClient.client.get('/conversations/contacts');
      print('🔍 [TeacherMessages] Contacts response: ${contactsRes.statusCode} - ${contactsRes.data}');

      if (contactsRes.data['success'] == true) {
        _availableContacts = contactsRes.data['data'] as List;
        print('✅ [TeacherMessages] Contacts loaded: ${_availableContacts.length}');
      } else {
        print('❌ [TeacherMessages] Contacts failed: ${contactsRes.data}');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ [TeacherMessages] Error fetching data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل البيانات: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: appScreenBackground(context),
      appBar: AppBar(
        title: Text(
          'الرسائل',
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        backgroundColor: appScreenBackground(context),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty && _availableContacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 64.r, color: AppColors.textLight),
                      SizedBox(height: 16.h),
                      Text(
                        'لا توجد رسائل',
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                    children: [
                      if (_availableContacts.isNotEmpty) ...[
                        Text(
                          'ابدأ محادثة جديدة',
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        ..._availableContacts.map((contact) => _buildContactTile(contact, isDark)),
                        SizedBox(height: 24.h),
                        Text(
                          'المحادثات السابقة',
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 12.h),
                      ],
                      ..._conversations.map((conv) => _buildConversationTile(conv, isDark)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildContactTile(dynamic contact, bool isDark) {
    final name = contact['user']?['fullName'] ?? 'غير معروف';
    final photo = contact['user']?['photo'] ?? contact['photo'];
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 24.r,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: ClipOval(
            child: photo != null && photo.isNotEmpty
                ? Image.network(
                    photo,
                    width: 48.r,
                    height: 48.r,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: GoogleFonts.cairo(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  )
                : Text(
                    name.isNotEmpty ? name[0] : '?',
                    style: GoogleFonts.cairo(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        trailing: Icon(Icons.chat_rounded, color: AppColors.primary),
        onTap: () => _startConversation(contact['id'], name),
      ),
    );
  }

  Widget _buildConversationTile(dynamic conv, bool isDark) {
    final name = conv['participantName'] ?? 'غير معروف';
    final type = conv['participantType'] ?? 'UNKNOWN';
    final photo = conv['participantImage'];
    final lastMessage = conv['messages']?.isNotEmpty == true
        ? conv['messages'][0]['content'] ?? ''
        : 'لا توجد رسائل';
    final unreadCount = conv['unreadCount'] ?? 0;
    final lastMessageTime = conv['lastMessageAt'] != null
        ? DateTime.parse(conv['lastMessageAt'])
        : DateTime.now();

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24.r,
              backgroundColor: type == 'SCHOOL_ADMIN' 
                  ? AppColors.amber.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.1),
              child: ClipOval(
                child: photo != null && photo.isNotEmpty
                    ? Image.network(
                        photo,
                        width: 48.r,
                        height: 48.r,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: type == 'SCHOOL_ADMIN'
                                ? Icon(Icons.school_rounded, color: AppColors.amber, size: 24.r)
                                : Text(
                                    name.isNotEmpty ? name[0] : '?',
                                    style: GoogleFonts.cairo(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w900,
                                      color: type == 'SCHOOL_ADMIN' ? AppColors.amber : AppColors.primary,
                                    ),
                                  ),
                          );
                        },
                      )
                    : Center(
                        child: type == 'SCHOOL_ADMIN'
                            ? Icon(Icons.school_rounded, color: AppColors.amber, size: 24.r)
                            : Text(
                                name.isNotEmpty ? name[0] : '?',
                                style: GoogleFonts.cairo(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w900,
                                  color: type == 'SCHOOL_ADMIN' ? AppColors.amber : AppColors.primary,
                                ),
                              ),
                      ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                    style: GoogleFonts.cairo(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          name,
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        subtitle: Text(
          lastMessage.length > 30 ? '${lastMessage.substring(0, 30)}...' : lastMessage,
          style: GoogleFonts.cairo(
            fontSize: 12.sp,
            color: unreadCount > 0 ? AppColors.primary : (isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium),
            fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(lastMessageTime),
              style: GoogleFonts.cairo(
                fontSize: 10.sp,
                color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        onTap: () => _openConversation(conv['id'], name),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} د';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} س';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  Future<void> _startConversation(String contactId, String contactName) async {
    try {
      final res = await _apiClient.client.post('/conversations', data: {
        'recipientId': contactId,
        'recipientType': 'PARENT',
      });

      if (res.data['success'] == true) {
        _openConversation(res.data['data']['id'], contactName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إنشاء المحادثة')),
        );
      }
    } catch (e) {
      print('Error starting conversation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إنشاء المحادثة')),
      );
    }
  }

  Future<void> _openConversation(String conversationId, String contactName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeacherChatDetailScreen(
          conversationId: conversationId,
          contactName: contactName,
        ),
      ),
    );
    // Callback to notify parent screen that conversation was opened
    widget.onConversationOpened?.call();
    // Refresh conversations to update unread counts
    _fetchData();
  }
}

class TeacherChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String contactName;

  const TeacherChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.contactName,
  });

  @override
  State<TeacherChatDetailScreen> createState() => _TeacherChatDetailScreenState();
}

class _TeacherChatDetailScreenState extends State<TeacherChatDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.client.get('/conversations/${widget.conversationId}/messages');
      if (res.data['success'] == true) {
        setState(() {
          _messages = res.data['data'] as List;
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error fetching messages: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في تحميل الرسائل')),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final res = await _apiClient.client.post(
        '/conversations/${widget.conversationId}/messages',
        data: {'content': content},
      );

      if (res.data['success'] == true) {
        setState(() {
          _messages.add(res.data['data']);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إرسال الرسالة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: appScreenBackground(context),
      appBar: AppBar(
        title: Text(
          widget.contactName,
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        backgroundColor: appScreenBackground(context),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'ابدأ المحادثة الآن',
                          style: GoogleFonts.cairo(
                            fontSize: 14.sp,
                            color: isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16.w),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMe = message['senderId'] == _getCurrentUserId();
                          return _buildMessageBubble(message, isMe, isDark);
                        },
                      ),
          ),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      hintStyle: GoogleFonts.cairo(
                        color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF12121E) : AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic message, bool isMe, bool isDark) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : (isDark ? const Color(0xFF2D2D3F) : Colors.grey[200]),
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Text(
          message['content'] ?? '',
          style: GoogleFonts.cairo(
            fontSize: 14.sp,
            color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }

  String _getCurrentUserId() {
    // Get current user ID from shared preferences
    return 'current_user_id'; // TODO: Implement proper user ID retrieval
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
