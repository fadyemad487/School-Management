import 'package:flutter/material.dart';
import '../chat/parent_chat_screen.dart';

class ParentMessages extends StatelessWidget {
  final VoidCallback? onConversationOpened;

  const ParentMessages({super.key, this.onConversationOpened});

  @override
  Widget build(BuildContext context) {
    return ParentChatScreen(onConversationOpened: onConversationOpened);
  }
}
