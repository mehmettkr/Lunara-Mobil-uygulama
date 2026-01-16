import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'friend_dreams_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final _fs = FirestoreService();
  final _auth = AuthService();

  void _showAddFriendDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2E1A47),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Arkadaş Ekle', style: TextStyle(color: Colors.white)),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              border: InputBorder.none,
              labelText: 'Kullanıcı Adı',
              labelStyle: TextStyle(color: Colors.white60),
              hintText: 'örn: ahmet123',
              hintStyle: TextStyle(color: Colors.white24),
              icon: Icon(Icons.person_search, color: Colors.white54),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              final username = controller.text.trim().toLowerCase();
              if (username.isEmpty) return;
              Navigator.pop(context);
              try {
                final currentUser = _auth.currentUser!;
                await _fs.addFriend(currentUser.uid, username);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Arkadaş eklendi! ✨')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Hata: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFECA57),
              foregroundColor: Colors.black,
            ),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Arkadaşlarım', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddFriendDialog,
        backgroundColor: const Color(0xFFFECA57),
        child: const Icon(Icons.person_add, color: Colors.black87),
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
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _fs.streamFriends(user.uid),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('Hata: ${snap.error}', style: const TextStyle(color: Colors.red)));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final friends = snap.data!;

              if (friends.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz arkadaşın yok.',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                      ),
                      TextButton(
                        onPressed: _showAddFriendDialog,
                        child: const Text('Arkadaş Ekle', style: TextStyle(color: Color(0xFFFECA57))),
                      )
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: friends.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final f = friends[i];
                  return _buildFriendCard(f);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCard(Map<String, dynamic> f) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.primaries[f['username'].hashCode % Colors.primaries.length].withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 2),
            boxShadow: [
               BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: Center(
            child: Text(
              f['username'][0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ),
        title: Text(
          f['username'],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Rüyalarını görmek için tıkla',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FriendDreamsScreen(
                friendId: f['id'],
                friendName: f['username'],
              ),
            ),
          );
        },
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.8)),
          onPressed: () async {
             // Silme onayı eklenebilir ama şimdilik direkt sil
             final currentUser = _auth.currentUser!;
             await _fs.removeFriend(currentUser.uid, f['id']);
          },
        ),
      ),
    );
  }
}
