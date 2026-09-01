import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/socket_service.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

class ParentChatScreen extends StatefulWidget {
  final VoidCallback? onConversationOpened;

  const ParentChatScreen({super.key, this.onConversationOpened});

  @override
  State<ParentChatScreen> createState() => _ParentChatScreenState();
}

class _ParentChatScreenState extends State<ParentChatScreen> {
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
      print('🔍 [ParentChat] Fetching conversations...');
      final convRes = await _apiClient.client.get('/conversations');
      print('🔍 [ParentChat] Conversations response: ${convRes.statusCode} - ${convRes.data}');
      
      if (convRes.data['success'] == true) {
        _conversations = convRes.data['data'] as List;
        print('✅ [ParentChat] Conversations loaded: ${_conversations.length}');
      } else {
        print('❌ [ParentChat] Conversations failed: ${convRes.data}');
      }

      print('🔍 [ParentChat] Fetching contacts...');
      final contactsRes = await _apiClient.client.get('/conversations/contacts');
      print('🔍 [ParentChat] Contacts response: ${contactsRes.statusCode} - ${contactsRes.data}');

      if (contactsRes.data['success'] == true) {
        _availableContacts = contactsRes.data['data'] as List;
        print('✅ [ParentChat] Contacts loaded: ${_availableContacts.length}');
      } else {
        print('❌ [ParentChat] Contacts failed: ${contactsRes.data}');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      print('❌ [ParentChat] Error fetching data: $e');
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
      backgroundColor: isDark ? const Color(0xFF12121E) : AppColors.background,
      appBar: AppBar(
        title: Text(
          'المحادثات',
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF12121E) : Colors.white,
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
                        'لا توجد محادثات',
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
    final type = contact['type'] ?? 'UNKNOWN';
    final photo = contact['user']?['photo'] ?? contact['photo'];
    final isFirstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF2D2D3F) : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _startConversation(contact['id'], name),
        borderRadius: BorderRadius.circular(16.r),
        child: Row(
          children: [
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                color: type == 'SCHOOL_ADMIN' 
                    ? AppColors.amber.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
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
                                    isFirstLetter,
                                    style: GoogleFonts.cairo(
                                      fontSize: 18.sp,
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
                                isFirstLetter,
                                style: GoogleFonts.cairo(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w900,
                                  color: type == 'SCHOOL_ADMIN' ? AppColors.amber : AppColors.primary,
                                ),
                              ),
                      ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.cairo(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    type == 'SCHOOL_ADMIN' ? 'إدارة المدرسة' : 'مدرس',
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      color: type == 'SCHOOL_ADMIN' 
                          ? AppColors.amber 
                          : (isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chat_rounded, color: AppColors.primary, size: 24.r),
          ],
        ),
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
    final isFirstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2C) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: unreadCount > 0 ? AppColors.primary : (isDark ? const Color(0xFF2D2D3F) : AppColors.border),
          width: unreadCount > 0 ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _openConversation(conv['id'], name),
        borderRadius: BorderRadius.circular(16.r),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: unreadCount > 0
                        ? AppColors.primary
                        : (type == 'SCHOOL_ADMIN' 
                            ? AppColors.amber.withOpacity(0.2)
                            : AppColors.primary.withOpacity(0.1)),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: photo != null && photo.isNotEmpty
                        ? Image.network(
                            photo,
                            width: 48.r,
                            height: 48.r,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: unreadCount > 0
                                    ? Text(
                                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                                        style: GoogleFonts.cairo(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      )
                                    : (type == 'SCHOOL_ADMIN'
                                        ? Icon(Icons.school_rounded, color: AppColors.amber, size: 24.r)
                                        : Text(
                                            isFirstLetter,
                                            style: GoogleFonts.cairo(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w900,
                                              color: type == 'SCHOOL_ADMIN' ? AppColors.amber : AppColors.primary,
                                            ),
                                          )),
                              );
                            },
                          )
                        : Center(
                            child: unreadCount > 0
                                ? Text(
                                    unreadCount > 9 ? '9+' : unreadCount.toString(),
                                    style: GoogleFonts.cairo(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  )
                                : (type == 'SCHOOL_ADMIN'
                                    ? Icon(Icons.school_rounded, color: AppColors.amber, size: 24.r)
                                    : Text(
                                        isFirstLetter,
                                        style: GoogleFonts.cairo(
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.w900,
                                          color: type == 'SCHOOL_ADMIN' ? AppColors.amber : AppColors.primary,
                                        ),
                                      )),
                          ),
                  ),
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF1E1E2C) : Colors.white, width: 2),
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
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.cairo(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    lastMessage.length > 35 ? '${lastMessage.substring(0, 35)}...' : lastMessage,
                    style: GoogleFonts.cairo(
                      fontSize: 12.sp,
                      color: unreadCount > 0 
                          ? AppColors.primary 
                          : (isDark ? const Color(0xFFA0A0C0) : AppColors.textMedium),
                      fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded, size: 12.r, color: AppColors.textLight),
                      SizedBox(width: 4.w),
                      Text(
                        _formatTime(lastMessageTime),
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          color: isDark ? const Color(0xFFA0A0C0) : AppColors.textLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
        'recipientType': 'TEACHER',
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
        builder: (context) => ChatDetailScreen(
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

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String contactName;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.contactName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  StreamSubscription? _socketSubscription;

  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _setupSocketListener();
    _fetchMessages();
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupSocketListener() {
    _socketSubscription = SocketService().onEvent.listen((eventData) {
      final event = eventData['event'] ?? '';
      final data = eventData['data'];

      if (event == 'message:new') {
        // Check if message belongs to this conversation
        if (data != null && data['conversationId'] == widget.conversationId) {
          _fetchMessages(); // Auto-refresh when new message arrives
        }
      }
    });
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _removeSelectedImage() {
    setState(() {
      _selectedImagePath = null;
    });
    return Future.value();
  }

  Future<String> _convertImageToBase64(String path) async {
    final bytes = await File(path).readAsBytes();
    final base64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    return base64;
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    final hasImage = _selectedImagePath != null;
    
    if (content.isEmpty && !hasImage) return;

    setState(() => _isSending = true);
    _messageController.clear();
    
    String? base64Image;
    if (hasImage && _selectedImagePath != null) {
      base64Image = await _convertImageToBase64(_selectedImagePath!);
      setState(() {
        _selectedImagePath = null;
      });
    }

    try {
      // If there's an image, send it as base64 with a special prefix
      final messageContent = base64Image != null 
          ? 'IMAGE:$base64Image${content.isNotEmpty ? '\n$content' : ''}' 
          : content;
      
      final res = await _apiClient.client.post(
        '/conversations/${widget.conversationId}/messages',
        data: {'content': messageContent},
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
      backgroundColor: isDark ? const Color(0xFF12121E) : AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.contactName,
          style: GoogleFonts.cairo(
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF12121E) : Colors.white,
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
            child: Column(
              children: [
                if (_selectedImagePath != null)
                  Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF12121E) : AppColors.background,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.file(
                            File(_selectedImagePath!),
                            width: 60.r,
                            height: 60.r,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'صورة مختارة',
                            style: GoogleFonts.cairo(
                              fontSize: 12.sp,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: 20.r),
                          onPressed: _removeSelectedImage,
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.attach_file_rounded, size: 24.r),
                      onPressed: _pickImage,
                      color: AppColors.primary,
                    ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(dynamic message, bool isMe, bool isDark) {
    final content = message['content'] ?? '';
    final isImage = content.startsWith('IMAGE:');
    
    if (isImage) {
      final imageContent = content.substring(6); // Remove 'IMAGE:' prefix
      final textContent = imageContent.contains('\n') 
          ? imageContent.substring(imageContent.indexOf('\n') + 1) 
          : '';
      final imageUrl = textContent.isNotEmpty 
          ? imageContent.substring(0, imageContent.indexOf('\n')) 
          : imageContent;
      
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: EdgeInsets.all(16.r),
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    );
                  },
                ),
              ),
              if (textContent.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Text(
                    textContent,
                    style: GoogleFonts.cairo(
                      fontSize: 14.sp,
                      color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }
    
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
          content,
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
    // This will be used to determine if message is from current user
    return 'current_user_id'; // TODO: Implement proper user ID retrieval
  }
}
