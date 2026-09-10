import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';

/// 🤖 ENJOY AI Layer (প্ল্যান সেকশন ১৫)
/// Endpoint set থাকলে remote AI, না হলে built-in local assistant।
/// AI ব্যবহার — Optional।
class AiService {
  static final List<Map<String, String>> _memory = []; // AI Memory

  static bool get configured => AppConfig.aiEndpoint.isNotEmpty;

  static Future<String> ask(String prompt) async {
    if (configured) {
      final r = await _remote(prompt);
      if (r != null) return r;
    }
    return _local(prompt);
  }

  static Future<String?> _remote(String prompt) async {
    try {
      final res = await http.post(
        Uri.parse(AppConfig.aiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          if (AppConfig.aiApiKey.isNotEmpty)
            'Authorization': 'Bearer ${AppConfig.aiApiKey}',
        },
        body: jsonEncode({'prompt': prompt, 'history': _memory}),
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final text =
            (body['response'] ?? body['text'] ?? body.toString()).toString();
        _remember(prompt, text);
        return text;
      }
    } catch (_) {}
    return null;
  }

  static void _remember(String q, String a) {
    _memory.addAll([
      {'role': 'user', 'content': q},
      {'role': 'assistant', 'content': a},
    ]);
    if (_memory.length > 40) {
      _memory.removeRange(0, _memory.length - 40);
    }
  }

  static void clearMemory() => _memory.clear();

  // ---------- Local fallback (rule-based) ----------

  static String _local(String prompt) {
    final q = prompt.toLowerCase();
    String answer;
    if (q.contains('title') || q.contains('টাইটেল') || q.contains('টাইটল')) {
      answer = '📝 Title সাজেশন:\n১. শক্তিশালী প্রথম শব্দ দিয়ে শুরু করুন\n'
          '২. ৬০ অক্ষরের মধ্যে রাখুন\n৩. সংখ্যা/প্রশ্ন ব্যবহার করুন (যেমন: "৫টি টিপস...")\n'
          '৪. আপনার ভিডিওর মূল keyword-টা title-এ রাখুন';
    } else if (q.contains('tag') || q.contains('ট্যাগ')) {
      answer = '🏷️ Tag সাজেশন:\nমূল topic + related ৪-৫টা keyword + trending শব্দ।\n'
          'comma দিয়ে আলাদা করুন, ছোট হাতের অক্ষরে লিখুন।';
    } else if (q.contains('description') || q.contains('ডেসক্রিপশন')) {
      answer = '📄 Description টিপস:\nপ্রথম ২ লাইনে ভিডিওর সারমর্ম, তারপর timestamps, '
          'তারপর relevant links ও hashtags (#ENJOY)';
    } else if (q.contains('game') || q.contains('গেম')) {
      final cfg = gameIdea(prompt);
      answer = '🎮 Game idea থেকে config:\nMap: ${cfg['bg']}, Target: ${cfg['target']}, '
          'Speed: ${cfg['speed']}ms, Reward: ${cfg['reward']}pts\n'
          'এই মানগুলো Game Editor-এ বসিয়ে Build & Test চাপুন।';
    } else if (q.contains('বুঝ') || q.contains('explain') ||
        q.contains('শিখ') || q.contains('learn')) {
      answer = '🤖 AI Learning Assistant:\nটপিকটা ছোট ছোট অংশে ভাগ করুন। '
          'প্রতিটা অংশ পড়ে নিজের ভাষায় লিখুন — এতে মনে থাকবে। '
          'প্রশ্ন থাকলে জিজ্ঞেস করুন, আমি সহজ করে বুঝিয়ে দেব।';
    } else {
      answer = '🌟 ENJOY AI Assistant:\nআমি আপনাকে সাহায্য করতে পারি —\n'
          '• ভিডিও title/tag/description সাজেশন\n'
          '• Learning topic বুঝিয়ে দেওয়া\n'
          '• Game idea থেকে config তৈরি\n'
          '• Content plan করতে সাহায্য\n\n'
          'কী জানতে চান লিখুন।';
    }
    _remember(prompt, answer);
    return answer;
  }

  /// Game Creator-এর জন্য: idea → config map
  static Map<String, dynamic> gameIdea(String idea) {
    final q = idea.toLowerCase();
    final fast = q.contains('fast') || q.contains('দ্রুত') ||
        q.contains('speed') || q.contains('hard');
    final space = q.contains('space') || q.contains('মহাকর্ষ');
    final jungle = q.contains('jungle') || q.contains('অরণ্য') ||
        q.contains('green') || q.contains('সবুজ');
    return {
      'map': jungle ? '#2D6A4F' : (space ? '#0F3460' : '#1A1A2E'),
      'character': q.contains('fire') || q.contains('লাল') ? '#9B2226' : '#FF3D5A',
      'bg': jungle ? '#2D6A4F' : (space ? '#0F3460' : '#1A1A2E'),
      'target': '#FF3D5A',
      'speed': fast ? 400 : 800,
      'reward': fast ? 20 : 10,
      'sound': true,
      'controls': 'Tap',
      'missions': ['Score 100', 'Play 3 rounds'],
      'rules': 'Tap target to score',
      'environment': jungle ? 'jungle' : (space ? 'space' : 'default'),
      'health': 3,
    };
  }
}