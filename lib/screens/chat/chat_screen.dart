import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const _kReactions = ['❤️', '😂', '😮', '😢', '👍', '👎'];

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  final Map<String, Uint8List> _imageCache = {};

  String get _currentUserId => FirebaseAuth.instance.currentUser!.uid;

  String? _lastSeenMessageId;

  // ── Edit mode state ───────────────────────────────────────────────────────
  String? _editingMessageId;

  @override
  void initState() {
    super.initState();
    _markAsSeen();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _markAsSeen() async {
    await FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .update({"lastSeen.$_currentUserId": FieldValue.serverTimestamp()});
  }

  void _maybeMarkLatestAsSeen(List<QueryDocumentSnapshot> messages) {
    if (messages.isEmpty) return;
    final latest = messages.first;
    final data = latest.data() as Map<String, dynamic>;
    if (data["senderID"] == _currentUserId) return;
    if (latest.id == _lastSeenMessageId) return;
    _lastSeenMessageId = latest.id;
    FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .update({"lastSeen.$_currentUserId": FieldValue.serverTimestamp()});
  }

  // ── Send / Edit ───────────────────────────────────────────────────────────
  Future<void> _sendOrEditText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    // Edit mode
    if (_editingMessageId != null) {
      await FirebaseFirestore.instance
          .collection("chats")
          .doc(widget.chatId)
          .collection("messages")
          .doc(_editingMessageId)
          .update({"content": text, "edited": true});
      setState(() => _editingMessageId = null);
      return;
    }

    // New message
    final chatRef =
        FirebaseFirestore.instance.collection("chats").doc(widget.chatId);
    final batch = FirebaseFirestore.instance.batch();

    batch.set(chatRef.collection("messages").doc(), {
      "type": "text",
      "content": text,
      "sentAt": FieldValue.serverTimestamp(),
      "senderID": _currentUserId,
    });

    batch.update(chatRef, {
      "lastMessage": text,
      "lastMessageAt": FieldValue.serverTimestamp(),
      "lastMessageSenderID": _currentUserId,
      "lastSeen.$_currentUserId": FieldValue.serverTimestamp(),
    });

    await batch.commit();
    _scrollToBottom();
  }

  void _startEditing(String messageId, String currentText) {
    setState(() => _editingMessageId = messageId);
    _messageController.text = currentText;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: currentText.length),
    );
  }

  void _cancelEditing() {
    setState(() => _editingMessageId = null);
    _messageController.clear();
  }

  // ── Delete ────────────────────────────────────────────────────────────────
  Future<void> _deleteMessage(String messageId) async {
    await FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .collection("messages")
        .doc(messageId)
        .update({
      "deleted": true,
      "content": "",
    });
  }

  // ── React ─────────────────────────────────────────────────────────────────
  Future<void> _toggleReaction(String messageId, String emoji) async {
    final ref = FirebaseFirestore.instance
        .collection("chats")
        .doc(widget.chatId)
        .collection("messages")
        .doc(messageId);

    final snap = await ref.get();
    final data = snap.data() as Map<String, dynamic>;
    final reactions =
        Map<String, dynamic>.from(data["reactions"] ?? {});

    // reactions map: { emoji: [userId, ...] }
    final List<dynamic> users =
        List<dynamic>.from(reactions[emoji] ?? []);

    if (users.contains(_currentUserId)) {
      users.remove(_currentUserId);
    } else {
      users.add(_currentUserId);
    }

    if (users.isEmpty) {
      reactions.remove(emoji);
    } else {
      reactions[emoji] = users;
    }

    await ref.update({"reactions": reactions});
  }

  // ── Long-press action sheet ───────────────────────────────────────────────
  void _showMessageActions(
    BuildContext context, {
    required String messageId,
    required Map<String, dynamic> msg,
    required bool isMe,
  }) {
    final type = msg["type"] as String? ?? "text";
    final isDeleted = msg["deleted"] == true;
    if (isDeleted) return;

    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Reaction picker row ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _kReactions.map((emoji) {
                    final reactions = Map<String, dynamic>.from(
                        msg["reactions"] ?? {});
                    final users =
                        List<dynamic>.from(reactions[emoji] ?? []);
                    final reacted = users.contains(_currentUserId);

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _toggleReaction(messageId, emoji);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: reacted
                              ? Colors.green.withOpacity(0.15)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 24)),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const Divider(height: 1),

              // ── Edit (only for own text messages) ─────────────────────
              if (isMe && type == "text")
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text("Edit"),
                  onTap: () {
                    Navigator.pop(context);
                    _startEditing(
                        messageId, msg["content"] as String? ?? "");
                  },
                ),

              // ── Delete (only for own messages) ─────────────────────────
              if (isMe)
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text("Delete",
                      style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteMessage(messageId);
                  },
                ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 600,
    );
    if (image == null) return;

    final bytes = await File(image.path).readAsBytes();
    final base64Image = base64Encode(bytes);
    _imageCache[base64Image] = bytes;

    final chatRef =
        FirebaseFirestore.instance.collection("chats").doc(widget.chatId);
    final batch = FirebaseFirestore.instance.batch();

    batch.set(chatRef.collection("messages").doc(), {
      "type": "image",
      "content": base64Image,
      "sentAt": FieldValue.serverTimestamp(),
      "senderID": _currentUserId,
    });

    batch.update(chatRef, {
      "lastMessage": "Image",
      "lastMessageAt": FieldValue.serverTimestamp(),
      "lastMessageSenderID": _currentUserId,
      "lastSeen.$_currentUserId": FieldValue.serverTimestamp(),
    });

    await batch.commit();
    _scrollToBottom();
  }

  Uint8List _decodeImage(String base64String) {
    return _imageCache.putIfAbsent(
        base64String, () => base64Decode(base64String));
  }

  @override
  Widget build(BuildContext context) {
    final bubbleMaxWidth = MediaQuery.of(context).size.width * 0.72;

    return Scaffold(
      appBar: AppBar(title: const Text("Chat")),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: _MessageList(
              chatId: widget.chatId,
              currentUserId: _currentUserId,
              bubbleMaxWidth: bubbleMaxWidth,
              imageCache: _imageCache,
              scrollController: _scrollController,
              decodeImage: _decodeImage,
              onNewMessages: _maybeMarkLatestAsSeen,
              onLongPress: (ctx, messageId, msg, isMe) =>
                  _showMessageActions(ctx,
                      messageId: messageId, msg: msg, isMe: isMe),
            ),
          ),

          // ── Edit mode banner ───────────────────────────────────────────
          if (_editingMessageId != null)
            Container(
              color: Colors.green.shade50,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text("Editing message",
                        style: TextStyle(
                            color: Colors.green, fontSize: 12)),
                  ),
                  GestureDetector(
                    onTap: _cancelEditing,
                    child: const Icon(Icons.close,
                        size: 18, color: Colors.green),
                  ),
                ],
              ),
            ),

          _InputBar(
            controller: _messageController,
            onSendText: _sendOrEditText,
            onSendImage: _sendImage,
            onTap: _scrollToBottom,
            isEditing: _editingMessageId != null,
          ),
        ],
      ),
    );
  }
}

// ─── Message list ─────────────────────────────────────────────────────────────
class _MessageList extends StatelessWidget {
  final String chatId;
  final String currentUserId;
  final double bubbleMaxWidth;
  final Map<String, Uint8List> imageCache;
  final ScrollController scrollController;
  final Uint8List Function(String) decodeImage;
  final void Function(List<QueryDocumentSnapshot>) onNewMessages;
  final void Function(
          BuildContext, String messageId, Map<String, dynamic>, bool isMe)
      onLongPress;

  const _MessageList({
    required this.chatId,
    required this.currentUserId,
    required this.bubbleMaxWidth,
    required this.imageCache,
    required this.scrollController,
    required this.decodeImage,
    required this.onNewMessages,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .doc(chatId)
          .snapshots(),
      builder: (context, chatSnap) {
        if (!chatSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final chatData = chatSnap.data!.data() as Map<String, dynamic>;
        final participants =
            List<String>.from(chatData["participants"] ?? []);
        final otherUserId =
            participants.firstWhere((id) => id != currentUserId);
        final lastSeenMap =
            Map<String, dynamic>.from(chatData["lastSeen"] ?? {});
        final Timestamp? otherUserLastSeen = lastSeenMap[otherUserId];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("chats")
              .doc(chatId)
              .collection("messages")
              .orderBy("sentAt", descending: true)
              .snapshots(),
          builder: (context, msgSnap) {
            if (!msgSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final messages = msgSnap.data!.docs;
            onNewMessages(messages);

            return ListView.builder(
              controller: scrollController,
              reverse: true,
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final doc = messages[index];
                final msg = doc.data() as Map<String, dynamic>;
                final isMe = msg["senderID"] == currentUserId;
                final Timestamp? sentAt = msg["sentAt"];

                final bool seen = isMe &&
                    sentAt != null &&
                    otherUserLastSeen != null &&
                    !otherUserLastSeen.toDate().isBefore(sentAt.toDate());

                return _MessageTile(
                  key: ValueKey(doc.id),
                  messageId: doc.id,
                  msg: msg,
                  isMe: isMe,
                  seen: seen,
                  isLatestMyMessage: index == 0 && isMe,
                  bubbleMaxWidth: bubbleMaxWidth,
                  decodeImage: decodeImage,
                  onLongPress: (ctx) =>
                      onLongPress(ctx, doc.id, msg, isMe),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─── Message tile ─────────────────────────────────────────────────────────────
class _MessageTile extends StatelessWidget {
  final String messageId;
  final Map<String, dynamic> msg;
  final bool isMe;
  final bool seen;
  final bool isLatestMyMessage;
  final double bubbleMaxWidth;
  final Uint8List Function(String) decodeImage;
  final void Function(BuildContext) onLongPress;

  const _MessageTile({
    super.key,
    required this.messageId,
    required this.msg,
    required this.isMe,
    required this.seen,
    required this.isLatestMyMessage,
    required this.bubbleMaxWidth,
    required this.decodeImage,
    required this.onLongPress,
  });

  void _openImageViewer(BuildContext context, Uint8List bytes) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => _FullScreenImageViewer(bytes: bytes),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final type = msg["type"] as String? ?? "text";
    final isDeleted = msg["deleted"] == true;
    final isEdited = msg["edited"] == true;

    // ── System message ────────────────────────────────────────────────────
    if (type == "system") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              msg["content"] ?? "",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    final isImage = type == "image";
    final reactions =
        Map<String, dynamic>.from(msg["reactions"] ?? {});
    final hasReactions = reactions.isNotEmpty;

    // ── Bubble ────────────────────────────────────────────────────────────
    Widget bubble = GestureDetector(
      onLongPress: () => onLongPress(context),
      child: Container(
        margin:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
        padding: isImage && !isDeleted
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDeleted
              ? Colors.grey.shade200
              : isMe
                  ? Colors.green
                  : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
          border: isDeleted
              ? Border.all(color: Colors.grey.shade300)
              : null,
        ),
        child: isDeleted
            ? Text(
                "Message deleted",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              )
            : isImage
                ? GestureDetector(
                    onTap: () => _openImageViewer(
                        context, decodeImage(msg["content"])),
                    onLongPress: () => onLongPress(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxHeight: 250),
                        child: Image.memory(
                          decodeImage(msg["content"]),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                          filterQuality: FilterQuality.low,
                        ),
                      ),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        msg["content"] ?? "",
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (isEdited)
                        Text(
                          "edited",
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? Colors.white60
                                : Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
      ),
    );

    // ── Wrap bubble with reaction pill ─────────────────────────────────
    Widget content = Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            RepaintBoundary(child: bubble),

            // Reaction pills — overlapping the bottom of the bubble
            if (hasReactions)
              Positioned(
                bottom: -14,
                left: isMe ? null : 8,
                right: isMe ? 8 : null,
                child: Wrap(
                  spacing: 4,
                  children: reactions.entries.map((entry) {
                    final emoji = entry.key;
                    final users = List<dynamic>.from(entry.value);
                    final count = users.length;
                    final iReacted = users.contains(
                      FirebaseAuth.instance.currentUser!.uid,
                    );

                    return GestureDetector(
                      onTap: () => onLongPress(context), // opens sheet to toggle
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: iReacted
                              ? Colors.green.shade200
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: iReacted
                                ? Colors.green.shade300
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          count > 1 ? "$emoji $count" : emoji,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),

        // Extra space so the pills don't get clipped by the next widget
        if (hasReactions) const SizedBox(height: 18),

        // Seen / Sent
        if (isLatestMyMessage)
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 2),
            child: Text(
              seen ? "Seen" : "Sent",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
      ],
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: content,
    );
  }
}

// ─── Full-screen image viewer ─────────────────────────────────────────────────
class _FullScreenImageViewer extends StatefulWidget {
  final Uint8List bytes;

  const _FullScreenImageViewer({required this.bytes});

  @override
  State<_FullScreenImageViewer> createState() =>
      _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformController;
  late final AnimationController _animController;
  Animation<Matrix4>? _resetAnimation;

  @override
  void initState() {
    super.initState();
    _transformController = TransformationController();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        _transformController.value = _resetAnimation!.value;
      });
  }

  @override
  void dispose() {
    _transformController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    if (_transformController.value != Matrix4.identity()) {
      _resetAnimation = Matrix4Tween(
        begin: _transformController.value,
        end: Matrix4.identity(),
      ).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOut));
      _animController.forward(from: 0);
      return;
    }

    final pos = details.localPosition;
    const scale = 2.5;
    final zoomed = Matrix4.identity()
      ..translate(-pos.dx * (scale - 1), -pos.dy * (scale - 1))
      ..scale(scale);

    _resetAnimation = Matrix4Tween(
      begin: _transformController.value,
      end: zoomed,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: GestureDetector(
          onDoubleTapDown: _onDoubleTapDown,
          onDoubleTap: () {},
          child: InteractiveViewer(
            transformationController: _transformController,
            minScale: 1.0,
            maxScale: 5.0,
            child: Image.memory(
              widget.bytes,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSendText;
  final Future<void> Function(ImageSource) onSendImage;
  final VoidCallback onTap;
  final bool isEditing;

  const _InputBar({
    required this.controller,
    required this.onSendText,
    required this.onSendImage,
    required this.onTap,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            if (!isEditing) ...[
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () => onSendImage(ImageSource.camera),
              ),
              IconButton(
                icon: const Icon(Icons.photo),
                onPressed: () => onSendImage(ImageSource.gallery),
              ),
            ],
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: isEditing
                      ? "Edit message..."
                      : "Type a message...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onTap: onTap,
              ),
            ),
            IconButton(
              icon: Icon(
                isEditing ? Icons.check : Icons.send,
                color: Colors.green,
              ),
              onPressed: onSendText,
            ),
          ],
        ),
      ),
    );
  }
}