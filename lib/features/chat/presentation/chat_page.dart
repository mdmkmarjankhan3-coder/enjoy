import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/chat_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/media_picker.dart';
import '../../../services/supabase_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.conversationId,
    required this.title,
    this.otherUserId,
    this.isGroup = false,
  });
  final String conversationId;
  final String title;
  final String? otherUserId;
  final bool isGroup;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _uid = SupabaseService.client.auth.currentUser!.id;

  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _pinned = [];
  Map<String, dynamic>? _replyTo;
  DateTime? _otherRead;
  bool _typing = false;
  Set<String> _online = {};
  Timer? _typingTimer;

  RealtimeChannel? _msgCh, _typingCh, _presenceCh;
  bool _sendingMedia = false;

  @override
  void initState() {
    super.initState();
    _load();
    _msgCh = ChatService.subscribeMessages(widget.conversationId, (row) async {
      _messages.insert(0, await _withSender(row));
      ChatService.markRead(widget.conversationId);
      _refreshRead();
      if (mounted) setState(() {});
    });
    _typingCh = ChatService.onTyping(widget.conversationId, (userId) {
      if (userId == _uid) return;
      setState(() => _typing = true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3),
          () => setState(() => _typing = false));
    });
    if (!widget.isGroup && widget.otherUserId != null) {
      _presenceCh = ChatService.presenceChannel((online) {
        _online = online;
        if (mounted) setState(() {});
      });
    }
  }

  Future<Map<String, dynamic>> _withSender(Map<String, dynamic> row) async {
    if (row['sender'] != null) return row;
    final p = await SupabaseService.client
        .from('profiles')
        .select('name, username, avatar_url')
        .eq('id', row['sender_id'])
        .maybeSingle();
    return {...row, 'sender': p ?? <String, dynamic>{}};
  }

  Future<void> _load() async {
    final msgs = await ChatService.messages(widget.conversationId);
    _messages = msgs;
    _pinned = msgs.where((m) => m['is_pinned'] == true).toList();
    ChatService.markRead(widget.conversationId);
    await _refreshRead();
    if (mounted) setState(() {});
  }

  Future<void> _refreshRead() async {
    if (widget.isGroup || widget.otherUserId == null) return;
    _otherRead = await ChatService.otherLastRead(
        widget.conversationId, widget.otherUserId!);
  }

  @override
  void dispose() {
    _msgCh?.unsubscribe();
    _typingCh?.unsubscribe();
    _presenceCh?.unsubscribe();
    _typingTimer?.cancel();
    _input.dispose();
    super.dispose();
  }

  /// content খালি হলে '[media]' দেখাবে — nested quote ছাড়া
  String _textOf(dynamic content) {
    if (content == null || content.toString().isEmpty) return '[media]';
    return content.toString();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    await ChatService.sendMessage(widget.conversationId,
        content: text, replyTo: _replyTo?['id']);
    _input.clear();
    setState(() => _replyTo = null);
  }

  Future<void> _attach() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Image'),
              onTap: () => Navigator.pop(context, 'image')),
          ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text('Video'),
              onTap: () => Navigator.pop(context, 'video')),
          ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('File'),
              onTap: () => Navigator.pop(context, 'file')),
        ]),
      ),
    );
    if (choice == null) return;

    setState(() => _sendingMedia = true);
    try {
      String type;
      String url;
      if (choice == 'image') {
        final f = await MediaPicker.pickImage();
        if (f == null) return;
        type = 'image';
        url = (await CloudinaryService.uploadImage(f.bytes, f.name))['url']!;
      } else if (choice == 'video') {
        final f = await MediaPicker.pickVideo();
        if (f == null) return;
        type = 'video';
        url = (await CloudinaryService.uploadVideo(f.bytes, f.name))['url']!;
      } else {
        final r = await FilePicker.platform.pickFiles(withData: true);
        final f = r?.files.single;
        if (f == null || f.bytes == null) return;
        type = 'file';
        url = (await CloudinaryService.uploadFile(
            f.bytes!.toList(), f.name))['url']!;
      }
      await ChatService.sendMessage(widget.conversationId,
          type: type, mediaUrl: url);
    } finally {
      if (mounted) setState(() => _sendingMedia = false);
    }
  }

  Future<void> _messageOptions(Map<String, dynamic> m) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () => Navigator.pop(context, 'reply')),
          ListTile(
              leading: Icon(m['is_pinned'] == true
                  ? Icons.push_pin_outlined
                  : Icons.push_pin),
              title: Text(m['is_pinned'] == true ? 'Unpin' : 'Pin'),
              onTap: () => Navigator.pop(context, 'pin')),
          ListTile(
              leading: const Icon(Icons.forward),
              title: const Text('Forward'),
              onTap: () => Navigator.pop(context, 'forward')),
          ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete')),
        ]),
      ),
    );
    if (action == null) return;
    if (action == 'reply') {
      setState(() => _replyTo = m);
    } else if (action == 'pin') {
      await ChatService.togglePin(m['id'], m['is_pinned'] != true);
      _load();
    } else if (action == 'delete') {
      await ChatService.deleteMessage(m['id']);
      _load();
    } else if (action == 'forward') {
      final convs = await ChatService.myConversations();
      if (!mounted) return;
      final target = await showDialog<String>(
        context: context,
        builder: (_) => SimpleDialog(
          title: const Text('Forward করুন'),
          children: [
            for (final c in convs)
              SimpleDialogOption(
                onPressed: () =>
                    Navigator.pop(context, c['id'] as String),
                child: Text(c['type'] == 'group'
                    ? (c['name'] ?? 'Group')
                    : 'Direct chat'),
              ),
          ],
        ),
      );
      if (target != null) {
        await ChatService.sendMessage(target,
            type: m['type'] ?? 'text',
            content: m['content'] ?? '',
            mediaUrl: m['media_url']);
      }
    }
  }

  bool _isSeen(Map<String, dynamic> m) =>
      _otherRead != null &&
      _otherRead!.isAfter(DateTime.parse(m['created_at']));

  @override
  Widget build(BuildContext context) {
    final otherOnline =
        !widget.isGroup && _online.contains(widget.otherUserId);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Text(
              _typing
                  ? 'typing…'
                  : widget.isGroup
                      ? 'Group'
                      : (otherOnline ? 'online' : 'offline'),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      body: Column(children: [
        if (_pinned.isNotEmpty)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final p in _pinned.take(3))
                  Text(
                    '📌 ${_textOf(p['content'])}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        if (_sendingMedia) const LinearProgressIndicator(),
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(8),
            itemCount: _messages.length,
            itemBuilder: (_, i) => _bubble(_messages[i]),
          ),
        ),
        if (_replyTo != null)
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(children: [
              Expanded(
                child: Text(
                  'Reply: ${_textOf(_replyTo!['content'])}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _replyTo = null),
              ),
            ]),
          ),
        SafeArea(
          child: Row(children: [
            IconButton(icon: const Icon(Icons.attach_file), onPressed: _attach),
            Expanded(
              child: TextField(
                controller: _input,
                decoration: const InputDecoration(hintText: 'Message লিখুন…'),
                onChanged: (_) =>
                    ChatService.sendTyping(widget.conversationId),
                onSubmitted: (_) => _send(),
              ),
            ),
            IconButton(icon: const Icon(Icons.send), onPressed: _send),
          ]),
        ),
      ]),
    );
  }

  Widget _bubble(Map<String, dynamic> m) {
    final mine = m['sender_id'] == _uid;
    final sender = m['sender'] as Map<String, dynamic>?;
    final replyId = m['reply_to_id'];
    Map<String, dynamic>? replied;
    if (replyId != null) {
      for (final x in _messages) {
        if (x['id'] == replyId) replied = x;
      }
    }
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _messageOptions(m),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.all(10),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: mine
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isGroup && !mine)
                Text(
                  sender?['name'] ?? '',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                ),
              if (replied != null)
                Container(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _textOf(replied['content']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              _content(m),
              const SizedBox(height: 2),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  _time(m['created_at']),
                  style: const TextStyle(fontSize: 9),
                ),
                if (mine && !widget.isGroup) ...[
                  const SizedBox(width: 4),
                  Icon(
                    _isSeen(m) ? Icons.done_all : Icons.done,
                    size: 12,
                    color: _isSeen(m) ? Colors.blue : null,
                  ),
                ],
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(Map<String, dynamic> m) {
    switch (m['type']) {
      case 'image':
        return Image.network(m['media_url'], width: 200);
      case 'video':
        return InkWell(
          onTap: () => launchUrl(Uri.parse(m['media_url']),
              mode: LaunchMode.externalApplication),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.play_circle, size: 40),
            SizedBox(width: 8),
            Text('Video'),
          ]),
        );
      case 'file':
      case 'audio':
        return InkWell(
          onTap: () => launchUrl(Uri.parse(m['media_url']),
              mode: LaunchMode.externalApplication),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(m['type'] == 'audio'
                ? Icons.audiotrack
                : Icons.insert_drive_file),
            const SizedBox(width: 8),
            const Text('File'),
          ]),
        );
      default:
        return Text(m['content'] ?? '');
    }
  }

  String _time(String iso) {
    final t = DateTime.parse(iso).toLocal();
    final h = t.hour.toString().padLeft(2, '0');
    final min = t.minute.toString().padLeft(2, '0');
    return '$h:$min';
  }
}