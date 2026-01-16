import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/dream.dart';
import '../services/auth_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final auth = AuthService();
    final userId = auth.currentUser?.uid;

    if (userId == null) return const Scaffold(body: Center(child: Text('Giriş yapmalısınız')));

    return Scaffold(
      appBar: AppBar(title: const Text('Rüya İstatistikleri')),
      body: StreamBuilder<List<Dream>>(
        stream: fs.streamDreamsForUser(userId),
        builder: (context, snap) {
           if (snap.hasError) {
             return Center(child: Text('Hata: ${snap.error}'));
           }
           if (!snap.hasData) {
             return const Center(child: CircularProgressIndicator());
           }
           
           final dreams = snap.data!;
           if (dreams.isEmpty) {
             return const Center(child: Text('Henüz hiç rüya kaydetmediniz.'));
           }

           final totalDreams = dreams.length;
           
           final now = DateTime.now();
           final thisMonthDreams = dreams.where((d) => 
             d.createdAt.year == now.year && d.createdAt.month == now.month
           ).toList();
           final thisMonthCount = thisMonthDreams.length;

           // En son rüya tarihi
           final lastDreamDate = dreams.isNotEmpty 
             ? DateFormat('dd MMM yyyy', 'tr_TR').format(dreams.first.createdAt)
             : '-';

           // --- YENİ EKLENEN İSTATİSTİKLER ---

           // 1. Bu Ayın Baskın Duygusu
           String dominantMood = '-';
           if (thisMonthDreams.isNotEmpty) {
             final moodCounts = <String, int>{};
             for (var d in thisMonthDreams) {
               if (d.mood != null && d.mood!.isNotEmpty) {
                 moodCounts[d.mood!] = (moodCounts[d.mood!] ?? 0) + 1;
               }
             }
             if (moodCounts.isNotEmpty) {
               final sortedMoods = moodCounts.entries.toList()
                 ..sort((a, b) => b.value.compareTo(a.value));
               dominantMood = sortedMoods.first.key;
             }
           }

           // 2. En Çok Kullanılan Anahtar Kelime
           String topKeyword = '-';
           if (dreams.isNotEmpty) {
             final allText = dreams.map((d) => '${d.title} ${d.text}').join(' ').toLowerCase();
             // Basit tokenizer ve noktalama işareti temizleme
             final words = allText.replaceAll(RegExp(r'[^\w\sğüşıöçĞÜŞİÖÇ]'), '').split(RegExp(r'\s+'));
             
             final stopWords = {
               've', 'bir', 'bu', 'ile', 'da', 'de', 'ama', 'fakat', 'için', 'ben', 'o', 'şu',
               'daha', 'çok', 'en', 'gibi', 'kadar', 'sonra', 'önce', 'var', 'yok', 'ne', 'mi',
               'mu', 'mı', 'mü', 'her', 'hiç', 'diye', 'zaman', 'şey', 'bunu', 'bana', 'onun'
             };

             final wordCounts = <String, int>{};
             for (var w in words) {
               if (w.length > 2 && !stopWords.contains(w)) {
                 wordCounts[w] = (wordCounts[w] ?? 0) + 1;
               }
             }

             if (wordCounts.isNotEmpty) {
               final sortedWords = wordCounts.entries.toList()
                 ..sort((a, b) => b.value.compareTo(a.value));
               topKeyword = sortedWords.first.key;
             }
           }

           return SingleChildScrollView(
             padding: const EdgeInsets.all(16),
             child: Column(
               children: [
                 Row(
                   children: [
                     Expanded(
                       child: _buildStatCard(
                         title: 'Toplam Rüya',
                         value: '$totalDreams',
                         icon: Icons.auto_stories,
                         color: Colors.purpleAccent,
                         isSmall: true,
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: _buildStatCard(
                         title: 'Bu Ay',
                         value: '$thisMonthCount',
                         icon: Icons.calendar_month,
                         color: Colors.orangeAccent,
                         isSmall: true,
                       ),
                     ),
                   ],
                 ),
                 const SizedBox(height: 16),
                 _buildStatCard(
                   title: 'Son Rüya',
                   value: lastDreamDate,
                   icon: Icons.history,
                   color: Colors.blueAccent,
                 ),
                 const SizedBox(height: 16),
                 _buildStatCard(
                   title: 'Bu Ayın Hali',
                   value: dominantMood,
                   icon: Icons.mood,
                   color: Colors.pinkAccent,
                 ),
                 const SizedBox(height: 16),
                 _buildStatCard(
                   title: 'Anahtar Kelime',
                   value: topKeyword,
                   icon: Icons.key,
                   color: Colors.greenAccent,
                 ),
               ],
             ),
           );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isSmall = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2E1A47).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
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
