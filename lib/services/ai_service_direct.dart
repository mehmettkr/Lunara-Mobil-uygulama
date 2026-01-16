import 'dart:convert';
import 'package:http/http.dart' as http;

class AiServiceDirect {
  // ❗ KENDİ OPENAI KEY'İNİ BURAYA YAZ
  static const String _apiKey = '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';

  Future<String> interpretDream({required String dreamText}) async {
    final text = dreamText.trim();
    if (text.isEmpty) return 'Rüya metni boş.';

    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');

    final body = {
      "model": "gpt-4.1-mini",
      "messages": [
        {
          "role": "system",
          "content":
              "Sen nazik bir rüya yorumcususun. Kesin yargılar verme, olasılıklar sun."
        },
        {
          "role": "user",
          "content": """
Rüya: \"\"\"${text.length > 4000 ? text.substring(0, 4000) : text}\"\"\"

1) Kısa özet
2) Olası semboller
3) Duygu analizi
4) Günlük hayata öneri
"""
        }
      ],
      "temperature": 0.7
    };

    final res = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      return 'AI hata (${res.statusCode}): ${res.body}';
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>;
    return choices.first['message']['content']?.trim() ??
        'Yorum alınamadı.';
  }

  Future<String?> generateImage({required String prompt}) async {
    final uri = Uri.parse('https://api.openai.com/v1/images/generations');

    final body = {
      "model": "dall-e-3",
      "prompt": "Abstract dream art style: $prompt",
      "n": 1,
      "size": "1024x1024",
    };

    try {
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) {
        print('Image Gen Error: ${res.body}');
        return null;
      }

      final data = jsonDecode(res.body);
      return data['data'][0]['url'];
    } catch (e) {
      print('Image Gen Exception: $e');
      return null;
    }
  }
}
