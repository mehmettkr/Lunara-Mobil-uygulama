import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/dream.dart';
import '../routes.dart';

class FriendDreamsScreen extends StatelessWidget {
  final String friendId;
  final String friendName;

  const FriendDreamsScreen({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: Text('$friendName adlı kişinin Rüyaları')),
      body: StreamBuilder<List<Dream>>(
        stream: fs.streamSharedDreamsOfFriend(friendId),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Hata: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final dreams = snap.data!;

          if (dreams.isEmpty) {
            return Center(
                child: Text('$friendName henüz paylaşılmış bir rüya yok.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: dreams.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final d = dreams[i];
              final date = DateFormat('dd.MM.yyyy HH:mm').format(d.createdAt);
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    // Detay sayfasına gitmek istersek:
                     Navigator.pushNamed(context, AppRoutes.dreamDetail, arguments: d);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.title.isEmpty ? 'Başlıksız Rüya' : d.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          d.text,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (d.imageUrl != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              d.imageUrl!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
