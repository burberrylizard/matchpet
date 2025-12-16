// ignore_for_file: deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 

const Color brandPurple = Color(0xFF6A1B9A);

// ==========================================
// 1. CHAT LIST PAGE
// ==========================================
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text("Please log in"));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Messages", style: TextStyle(color: brandPurple, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error State (Helps debug)
          if (snapshot.hasError) {
            print("Chat Error: ${snapshot.error}"); // Check console if this prints
            return const Center(child: Text("Something went wrong loading chats."));
          }

          // 3. Empty State
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("No messages yet"),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              var chat = chats[index].data() as Map<String, dynamic>;
              String chatId = chats[index].id;
              
            
              String otherName = "Chat";
              List<dynamic> names = chat['participantNames'] ?? [];
              String? myEmail = FirebaseAuth.instance.currentUser?.email;

              if (names.length >= 2) {
                 var name1 = names[0].toString();
                 var name2 = names[1].toString();
                 otherName = (name1 == myEmail) ? name2 : name1;
              }

              String displayTitle = otherName;
              if (chat['petName'] != null) {
                displayTitle = "${chat['petName']} Inquiry";
              }
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: brandPurple.withOpacity(0.1),
                  child: const Icon(Icons.person, color: brandPurple),
                ),
                title: Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  (chat['lastMessage'] ?? '').toString(), // Force to String
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  _formatTime(chat['timestamp']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                onTap: () {
                  // Navigate with Safety Checks
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomPage(
                        chatId: chatId,
                        otherUserName: otherName, 
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return "";
    DateTime date = timestamp.toDate();
    // Safety check if DateFormat fails
    try {
      return DateFormat.jm().format(date);
    } catch (e) {
      return "${date.hour}:${date.minute}";
    }
  }
}

// ==========================================
// 2. CHAT ROOM PAGE
// ==========================================
class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final String otherUserName;

  const ChatRoomPage({super.key, required this.chatId, required this.otherUserName});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String msg = _messageController.text.trim();
    _messageController.clear();

    final uid = FirebaseAuth.instance.currentUser?.uid;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': msg,
      'senderId': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'lastMessage': msg,
      'timestamp': FieldValue.serverTimestamp(),
    });
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        // Force otherUserName to String to be safe
        title: Text(widget.otherUserName.toString(), style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) return const Center(child: Text("No messages"));

                final msgs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(10),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    var msg = msgs[index].data() as Map<String, dynamic>;
                    bool isMe = msg['senderId'] == uid;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? brandPurple : Colors.grey[200],
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          (msg['text'] ?? "").toString(),
                          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: brandPurple,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}