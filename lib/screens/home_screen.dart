import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../routes.dart';
import '../widgets/dream_card.dart';
import 'friends_screen.dart';
import 'calendar_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _selectedCategory = 'Rüya Günlüğüm';
  final _auth = AuthService();
  final _fs = FirestoreService();

  // Arka plan gradient
  final _bgGradient = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1A1F3C), Color(0xFF2E1A47)],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;
    
    // BottomNav sekmelerine karşılık gelen sayfalar
    final pages = [
      _buildDashboard(user),
      const CalendarScreen(), // Yeni Takvim Ekranı
      const FriendsScreen(),
      _buildProfile(user),
    ];

    return Scaffold(
      body: Container(
        decoration: _bgGradient,
        child: SafeArea(
          child: pages[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1F3C),
          border: Border(top: BorderSide(color: Colors.white10)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFFFECA57),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Takvim'),
            BottomNavigationBarItem(
                icon: Icon(Icons.people), label: 'Arkadaşlar'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(user) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. Header ---
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.nightlight_round,
                            color: Color(0xFFFECA57), size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Lunara',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_none,
                            color: Colors.white, size: 20),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Hoş Geldin, ${user.displayName ?? "Kullanıcı"}!',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bugün ne rüya gördün?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.newDream),
                    style: ElevatedButton.styleFrom(
                      elevation: 8,
                      shadowColor: const Color(0xFFFECA57).withOpacity(0.4),
                    ),
                    child: const Text('YENİ RÜYA EKLE'),
                  ),
                ),
              ],
            ),
          ),

          // --- 2. Kategoriler (İkonlu Menü) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategoryItem(Icons.book, 'Rüya\nGünlüğüm', 'Rüya Günlüğüm'),
                _buildCategoryItem(Icons.today, 'Bugün\nGörülen', 'Bugün Görülen'),
                _buildCategoryItem(Icons.people_outline, 'Arkadaş\nRüyaları', 'Arkadaş Rüyaları'),
                _buildCategoryItem(Icons.auto_awesome, 'AI\nYorumları', 'AI Yorumları'),
              ],
            ),
          ),

          // --- 3. İçerik Alanı (Arkadaş Rüyaları - Yatay) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Arkadaşların Rüyaları',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz, color: Colors.white54)),
              ],
            ),
          ),
          
          // Yatay Liste (Gerçek Veri)
          SizedBox(
            height: 160, // DreamCard yüksekliğine uygun
            child: StreamBuilder(
              stream: _fs.streamAllSharedDreams(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Yükleme hatası: ${snap.error}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final dreams = snap.data ?? [];
                if (dreams.isEmpty) {
                  return Center(
                    child: Text(
                      'Henüz paylaşılan rüya yok.',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: dreams.length,
                  itemBuilder: (_, index) {
                    final dream = dreams[index];
                    return Container(
                      width: 280, // Yatay kart genişliği
                      margin: const EdgeInsets.only(right: 16),
                      child: DreamCard(dream: dream),
                    );
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 24),

          // --- 4. İçerik Alanı (Rüya Günlüğüm - Dikey) ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_selectedCategory, // Seçili kategori başlığı
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_horiz, color: Colors.white54)),
              ],
            ),
          ),

          // Dikey Liste (Filtrelemeye göre değişebilir ama şimdilik kendi rüyalarımız)
          StreamBuilder(
            stream: _fs.streamDreamsForUser(user.uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final dreams = snap.data ?? [];
              // Basit bir filtreleme örneği:
              final displayedDreams = _selectedCategory == 'Bugün Görülen'
                  ? dreams.where((d) => 
                      d.createdAt.day == DateTime.now().day &&
                      d.createdAt.month == DateTime.now().month &&
                      d.createdAt.year == DateTime.now().year).toList()
                  : dreams;

              if (displayedDreams.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Bu kategoride rüya yok.',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedDreams.length, // Limit kaldırıldı veya sayfalandırma yapılabilir
                itemBuilder: (_, i) => DreamCard(dream: displayedDreams[i]),
              );
            },
          ),
          const SizedBox(height: 80), // Fab/BottomBar boşluğu
        ],
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label, String categoryId) {
    final isActive = _selectedCategory == categoryId;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedCategory = categoryId;
        });
        // İlgili bir navigasyon veya işlem varsa burada yapılabilir
        // Şimdilik sadece dikey listenin başlığını ve içeriğini değiştiriyor
      },
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.transparent, 
            ),
            child: Icon(icon,
                color: isActive ? const Color(0xFFFECA57) : Colors.white54,
                size: 28),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              color: isActive ? Colors.white : Colors.white54,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 30,
            height: 3,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFECA57) : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfile(user) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF2E1A47),
            child: Icon(Icons.person, size: 50, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            user.email ?? 'Kullanıcı',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.stats);
            },
            icon: const Icon(Icons.bar_chart),
            label: const Text('Rüya İstatistikleri'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFECA57),
              foregroundColor: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await _auth.logout();
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.login);
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Çıkış Yap'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
