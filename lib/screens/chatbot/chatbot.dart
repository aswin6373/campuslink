import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/profile.dart';
import 'google_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class Chatbot extends StatefulWidget {
  const Chatbot({super.key});
  
  @override
  _ChatbotState createState() => _ChatbotState();
}

class _ChatbotState extends State<Chatbot>  with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiService _geminiService = GeminiService();
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  String _institution = '';
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final List<Map<String, dynamic>> _chatHistory = [];
  int _currentChatIndex = -1;

  Widget _buildMessageList(ThemeData theme) {
  return ListView.builder(
    controller: _scrollController,
    padding: const EdgeInsets.all(16.0),
    itemCount: _messages.length,
    itemBuilder: (context, index) {
      final message = _messages[index];
      return MessageBubble(
        message: message['content'] ?? '',
        sender: message['sender'] ?? '',
        theme: theme,
      );
    },
  );
}

  @override
  void initState() {
    super.initState();
    _loadInstitution();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    _slideController.forward();
  }

  Future<void> _loadInstitution() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _institution = prefs.getString('institution') ?? '';
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
  
    if (_institution.isEmpty) {
      _addMessage('system', 'Institution information not available. Please set up your profile first.');
      return;
    }
    setState(() {
      _isLoading = true;
      _addMessage('user', message);
      _messageController.clear();
    });

    try {
      final response = await _geminiService.sendMessage(message, _institution);
      _addMessage('bot', response);
    } catch (e) {
      _addMessage('system', 'Failed to process your request. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addMessage(String sender, String content) {
    setState(() {
      _messages.add({'sender': sender, 'content': content});
      
      if (_currentChatIndex == -1) {
        _chatHistory.add({
          'title': 'Chat ${_chatHistory.length + 1}',
          'messages': List.from(_messages)
        });
        _currentChatIndex = _chatHistory.length - 1;
      } else {
        _chatHistory[_currentChatIndex]['messages'] = List.from(_messages);
      }
    });
    
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startNewChat() {
    setState(() {
      _messages.clear();
      _currentChatIndex = -1;
    });
    Navigator.pop(context);
  }

  void _loadChat(int index) {
    setState(() {
      _messages = List<Map<String, String>>.from(
        _chatHistory[index]['messages']
      );
      _currentChatIndex = index;
    });
    Navigator.pop(context);
  }

  void _deleteChat(int index) {
    setState(() {
      _chatHistory.removeAt(index);
      if (index == _currentChatIndex) {
        _currentChatIndex = -1;
        _messages.clear();
      }
    });
    Navigator.pop(context);
  }
  Widget _buildDrawer(ThemeData theme) {
  return Drawer(
    child: Column(
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
          ),
          child: Center(
            child: Text(
              "Chat History",
              style: GoogleFonts.poppins(
                color: theme.colorScheme.onPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(
            'New Chat',
            style: GoogleFonts.poppins(),
          ),
          onTap: _startNewChat,
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: _chatHistory.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(
                  _chatHistory[index]['title'].toString(),
                  style: GoogleFonts.poppins(),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteChat(index),
                ),
                selected: index == _currentChatIndex,
                onTap: () => _loadChat(index),
              );
            },
          ),
        ),
      ],
    ),
  );
}

@override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: _buildDrawer(theme),  // Add this line
      body: Stack(
        children: [
          // Background Design
          Positioned(
            top: -size.height * 0.1,
            right: -size.width * 0.2,
            child: Container(
              height: size.height * 0.3,
              width: size.height * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.primary.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            left: -size.width * 0.2,
            child: Container(
              height: size.height * 0.3,
              width: size.height * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.secondary.withOpacity(0.2),
                    theme.colorScheme.secondary.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
          
          // Main Content
          Column(
            children: [
              _buildGlassAppBar(theme),
              Expanded(
                child: _buildMessageList(theme),
              ),
              if (_isLoading)
                _buildLoadingIndicator(theme),
              _buildGlassInputBar(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassAppBar(ThemeData theme) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 8,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              Expanded(
                child: Text(
                  'Campus Assistant',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.account_circle, 
                  color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Thinking...',
                  style: GoogleFonts.poppins(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInputBar(ThemeData theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              8 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.8),
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: GoogleFonts.poppins(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: GoogleFonts.poppins(),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: theme.colorScheme.onPrimary,
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// In the same file, update the MessageBubble class
class MessageBubble extends StatelessWidget {
  final String message;
  final String sender;
  final ThemeData theme;

  const MessageBubble({
    required this.message,
    required this.sender,
    required this.theme,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isSystem = sender == 'system';
    final bool alignRight = sender == 'user';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!alignRight) ...[
            _buildAvatar(isSystem, theme),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: alignRight
                    ? theme.colorScheme.primary
                    : isSystem
                        ? theme.colorScheme.error.withOpacity(0.1)
                        : theme.colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(alignRight ? 20 : 4),
                  topRight: Radius.circular(alignRight ? 4 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  color: alignRight
                      ? theme.colorScheme.onPrimary
                      : isSystem
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          if (alignRight) ...[
            const SizedBox(width: 8),
            _buildAvatar(isSystem, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isSystem, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: isSystem
            ? theme.colorScheme.error.withOpacity(0.1)
            : theme.colorScheme.primary.withOpacity(0.1),
        child: Icon(
          isSystem ? Icons.info : Icons.smart_toy,
          color: isSystem
              ? theme.colorScheme.error
              : theme.colorScheme.primary,
          size: 20,
        ),
      ),
    );
  }
}