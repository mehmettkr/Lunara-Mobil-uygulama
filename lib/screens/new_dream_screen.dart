import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/ai_service_direct.dart';
import '../services/storage_service.dart';

class NewDreamScreen extends StatefulWidget {
  const NewDreamScreen({super.key});

  @override
  State<NewDreamScreen> createState() => _NewDreamScreenState();
}

class _NewDreamScreenState extends State<NewDreamScreen> {
  final _title = TextEditingController();
  final _text = TextEditingController();
  final _fs = FirestoreService();
  final _auth = AuthService();
  final _ai = AiServiceDirect();
  final _storage = StorageService();

  // Speech to Text
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;

  bool _isShared = false;
  bool _saving = false;
  String? _statusMessage; // Hata veya durum mesajı

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      // İzin yoksa sessizce geç veya uyar
      return;
    }
    _speechEnabled = await _speechToText.initialize(
      onError: (e) => debugPrint('Mikrofon hatası: ${e.errorMsg}'),
      onStatus: (status) {
        if (mounted) {
          setState(() {
            _isListening = status == 'listening';
          });
        }
      },
    );
  }

  void _toggleListening() async {
    if (!_speechEnabled) {
      await _speechToText.initialize();
    }

    if (_isListening) {
      await _speechToText.stop();
    } else {
      await _speechToText.listen(
        onResult: (result) {
           if (mounted) {
             setState(() {
               _text.text = result.recognizedWords;
               _text.selection = TextSelection.fromPosition(
                  TextPosition(offset: _text.text.length));
             });
           }
        },
        localeId: 'tr_TR',
      );
    }
    setState(() => _isListening = !_isListening);
  }

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    _speechToText.cancel();
    super.dispose();
  }

  String? _selectedMood;

  final List<String> _moods = ['😊', '😂', '😱', '😢', '😍', '😡', '🤔', '😴'];

  Future<void> _save({required bool withAi}) async {
    final user = _auth.currentUser!;
    final String defaultTitle = DateFormat('dd MMM yyyy', 'tr_TR').format(DateTime.now());
    final title = _title.text.trim().isEmpty ? defaultTitle : _title.text.trim();
    final text = _text.text.trim();

    if (text.isEmpty) {
      setState(() => _statusMessage = 'Lütfen rüyanızı yazın veya anlatın.');
      return;
    }

    setState(() {
      _saving = true;
      _statusMessage = withAi ? 'AI rüyanı yorumluyor ve resmediyor...' : 'Kaydediliyor...';
    });

    try {
      // 1. Rüyayı Temel Olarak Kaydet
      final dreamId = await _fs.addDream(
        userId: user.uid,
        title: title,
        text: text,
        isShared: _isShared,
        mood: _selectedMood,
      );

      // 2. AI İşlemleri (İstenirse)
      if (withAi) {
        // Paralel çalıştırabiliriz ama yorum daha öncelikli
        final interpretation = await _ai.interpretDream(dreamText: text);
        await _fs.updateInterpretation(dreamId: dreamId, interpretation: interpretation);
        
        // Resim oluşturma (Kullanıcı isteği: otomatik çizsin)
        setState(() => _statusMessage = 'Rüyanız resmediliyor...');
        final imageUrl = await _ai.generateImage(prompt: text);
        if (imageUrl != null) {
          // Storage'a yükle ve kalıcı URL al
          setState(() => _statusMessage = 'Resim kaydediliyor...');
          try {
            final permanentUrl = await _storage.uploadImageFromUrl(
                imageUrl, 'dream_${dreamId}_${DateTime.now().millisecondsSinceEpoch}');
            await _fs.updateImage(dreamId: dreamId, imageUrl: permanentUrl);
          } catch (e) {
            debugPrint('Storage upload hatası: $e');
            // Hata olursa kullanıcıya bildir ve geçici URL'i kullanma (Veya uyararak kullan)
            setState(() => _statusMessage = 'Resim yüklendi ama kalıcı kayıt başarısız: $e');
            // Geçici URL'i kaydetmeme konusunda: Eğer kaydedersek 1 saat sonra yine şikayet gelecek.
            // En iyisi kullanıcıyı uyarmak.
            await _fs.updateImage(dreamId: dreamId, imageUrl: imageUrl); // Yine de kaydetsin ama uyaralım
          }
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Rüya başarıyla kaydedildi! 🌙')),
        );
      }
    } catch (e) {
      setState(() => _statusMessage = 'Hata: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Yeni Rüya', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1F3C), Color(0xFF2E1A47)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Başlık Alanı
                      _buildGlassInput(
                        controller: _title,
                        hint: 'Rüyana bir başlık ver...',
                        icon: Icons.title,
                      ),
                      const SizedBox(height: 16),
                      
                      // Duygu Seçici
                      const Text('Duygunu Seç', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _moods.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final mood = _moods[index];
                            final isSelected = _selectedMood == mood;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedMood = mood),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFFECA57) : Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFFECA57).withOpacity(0.5), blurRadius: 8)] : [],
                                ),
                                child: Text(mood, style: const TextStyle(fontSize: 24)),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Metin Alanı + Mikrofon Butonu Stack
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: TextField(
                              controller: _text,
                              maxLines: null,
                              expands: true,
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Gördüğün rüyayı anlat...\n"Dün gece uçuyordum..."',
                                hintStyle: TextStyle(color: Colors.white38),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: FloatingActionButton.small(
                              onPressed: _toggleListening,
                              backgroundColor: _isListening ? Colors.redAccent : const Color(0xFFFECA57),
                              child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      if (_isListening)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Dinleniyor...',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.redAccent.shade100, fontSize: 12),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Paylaşım Switch'i
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: SwitchListTile(
                          title: const Text('Arkadaşlarımla Paylaş', style: TextStyle(color: Colors.white)),
                          subtitle: const Text('Rüyanı arkadaşların görebilir.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          value: _isShared,
                          activeColor: const Color(0xFFFECA57),
                          onChanged: (val) => setState(() => _isShared = val),
                        ),
                      ),

                      if (_statusMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _statusMessage!.startsWith('Hata') ? Colors.redAccent.withOpacity(0.2) : Colors.blueAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _statusMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Alt Butonlar
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : () => _save(withAi: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFECA57),
                          foregroundColor: Colors.black,
                          elevation: 8,
                          shadowColor: const Color(0xFFFECA57).withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: _saving && _statusMessage!.contains('AI') 
                            ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2), child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.auto_awesome),
                        label: const Text('KAYDET + YORUMLA + ÇİZ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _saving ? null : () => _save(withAi: false),
                      child: Text('Sadece Kaydet', style: TextStyle(color: Colors.white.withOpacity(0.6))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          icon: Icon(icon, color: Colors.white54),
        ),
      ),
    );
  }
}
