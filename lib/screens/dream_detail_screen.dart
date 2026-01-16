import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../services/ai_service_direct.dart';
import '../models/dream.dart';

class DreamDetailScreen extends StatefulWidget {
  const DreamDetailScreen({super.key});

  @override
  State<DreamDetailScreen> createState() => _DreamDetailScreenState();
}

class _DreamDetailScreenState extends State<DreamDetailScreen> {
  final fs = FirestoreService();
  final ai = AiServiceDirect();
  bool _generatingImage = false;
  final TextEditingController _commentController = TextEditingController();

  Future<void> _generateImage(Dream dream) async {
    setState(() => _generatingImage = true);
    try {
      final url = await ai.generateImage(prompt: "${dream.title} ${dream.text}"); 
      if (url != null) {
        await fs.updateImage(dreamId: dream.id, imageUrl: url);
        setState(() {}); 
      } else {
        if (mounted) const SnackBar(content: Text('Resim oluşturulamadı.'));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _generatingImage = false);
    }
  }

  Future<void> _deleteDream(String dreamId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rüyayı Sil'),
        content: const Text('Bu rüyayı silmek istediğinize emin misiniz?'),
        backgroundColor: const Color(0xFF2E1A47),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await fs.deleteDream(dreamId);
      if (mounted) Navigator.pop(context);
    }
  }

  
  Future<void> _sendComment(String dreamId) async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    FocusScope.of(context).unfocus();
    
    try {
      await fs.addComment(dreamId, text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Yorum hatası: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dreamArg = ModalRoute.of(context)!.settings.arguments as Dream;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rüya Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _deleteDream(dreamArg.id),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Rüya İçeriği ---
                  if (dreamArg.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(dreamArg.imageUrl!, width: double.infinity, height: 200, fit: BoxFit.cover),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generatingImage ? null : () => _generateImage(dreamArg),
                        icon: _generatingImage 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                            : const Icon(Icons.palette),
                        label: Text(_generatingImage ? 'Çiziliyor...' : 'Yapay Zeka ile Çiz'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                 
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(dreamArg.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                      if (dreamArg.mood != null) Text(dreamArg.mood!, style: const TextStyle(fontSize: 28)),
                    ],
                  ),
                  Text(DateFormat('dd MMMM yyyy, HH:mm', 'tr_TR').format(dreamArg.createdAt), style: TextStyle(color: Colors.grey.shade400)),
                  
                  const SizedBox(height: 20),
                  Text(dreamArg.text, style: const TextStyle(fontSize: 16, height: 1.5)),
                  
                  const SizedBox(height: 24),
                  if (dreamArg.aiInterpretation != null && dreamArg.aiInterpretation!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(children: [Icon(Icons.auto_awesome, size: 16, color: Colors.amber), SizedBox(width: 8), Text('AI Yorumu', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber))]),
                          const SizedBox(height: 8),
                          Text(dreamArg.aiInterpretation!, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Divider(),
                  const Text('Yorumlar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // --- Yorum Listesi ---
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: fs.streamComments(dreamArg.id),
                    builder: (context, snap) {
                      if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                      final comments = snap.data!;
                      if (comments.isEmpty) return const Text('Henüz yorum yapılmamış. İlk yorumu sen yap!', style: TextStyle(color: Colors.grey));
                      
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final c = comments[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(c['username'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                                    // Tarih eklenebilir
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(c['text']),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 80), // Alttaki input için boşluk
                ],
              ),
            ),
          ),
          
          // --- Sabit Yorum Yazma Alanı ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Yorum yap...',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFFFECA57),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black),
                      onPressed: () => _sendComment(dreamArg.id),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
