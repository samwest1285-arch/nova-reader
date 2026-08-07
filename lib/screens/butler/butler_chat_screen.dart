import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_theme.dart';
import '../../services/ai_service.dart';

/// The Butler chat screen — a cozy chat with the AI butler.
/// Has a proper AppBar with a back button (automatic via Navigator).
class ButlerChatScreen extends ConsumerStatefulWidget {
  const ButlerChatScreen({super.key});

  @override
  ConsumerState<ButlerChatScreen> createState() => _ButlerChatScreenState();
}

class _ButlerChatScreenState extends ConsumerState<ButlerChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  final AiButlerService _ai = AiButlerService();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages.add(const _ChatMessage(
      text: 'Guten Tag! Ich bin Ihr Butler. Wie kann ich Ihnen helfen? '
          'Fragen Sie mich nach Buch-Empfehlungen, oder wie Sie die App nutzen können.',
      isUser: false,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Get AI response
    final response = await _ai.askTechSupport(text);

    if (mounted) {
      setState(() {
        _messages.add(_ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E1B12),
      appBar: AppBar(
        title: const Text('Butler Chat'),
        backgroundColor: const Color(0xFF3E2723),
        foregroundColor: NovaColors.paleGold,
        // Back button is automatic because this screen is pushed
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return _MessageBubble(message: msg);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: NovaColors.warmGold,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Butler denkt nach...',
                    style: TextStyle(color: NovaColors.tan),
                  ),
                ],
              ),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Color(0xFF3E2723),
          border: Border(top: BorderSide(color: Color(0xFF5D4037))),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: NovaColors.paleGold),
                decoration: InputDecoration(
                  hintText: 'Nachricht an den Butler...',
                  hintStyle: const TextStyle(color: NovaColors.tan),
                  filled: true,
                  fillColor: const Color(0xFF2E1B12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isLoading ? null : _sendMessage,
              icon: const Icon(Icons.send, color: NovaColors.warmGold),
              tooltip: 'Senden',
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF6D4C41) : const Color(0xFF3E2723),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: NovaColors.paleGold, fontSize: 15),
        ),
      ),
    );
  }
}
