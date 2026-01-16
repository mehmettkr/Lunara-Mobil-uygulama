import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dream.dart';

class DreamCard extends StatelessWidget {
  final Dream dream;
  const DreamCard({super.key, required this.dream});

  @override
  Widget build(BuildContext context) {
    // Tarih formatı: '20 Eki 2023' gibi
    final date = DateFormat('dd MMM yyyy', 'tr_TR').format(dream.createdAt);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/dream_detail',
          arguments: dream,
        );
      },
      child: Container(
        height: 140, // Sabit yükseklik
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2E1A47).withOpacity(0.8), // Kart rengi
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // --- 1. Arka Plan Görseli veya Dekoratif İkon ---
              if (dream.imageUrl != null)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.3,
                    child: Image.network(
                      dream.imageUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.nightlight_round,
                    size: 100,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),

              // --- 2. İçerik ---
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Üst Kısım: Başlık ve Küçük Resim/İkon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                            image: dream.imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(dream.imageUrl!),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: dream.imageUrl == null
                              ? const Icon(Icons.wb_cloudy_outlined,
                                  color: Colors.white70, size: 20)
                              : null,
                        ),
                        const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            if (dream.mood != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(dream.mood!, style: const TextStyle(fontSize: 20)),
                              ),
                            Expanded(
                              child: Text(
                                dream.title.isNotEmpty ? dream.title : 'Başlıksız Rüya',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                    // Alt Kısım: Metin özeti ve Tarih
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dream.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              date,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // İhtiyaç duyarsanız buraya ekstra bir ikon/etiket eklenebilir
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Colors.white.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ],
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
}