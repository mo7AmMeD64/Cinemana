import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/favorites_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/video_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favs = context.watch<FavoritesProvider>().favorites;
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            const Text('المفضلة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(12)),
              child: Text('${favs.length}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ]),
        ),
        Expanded(
          child: favs.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.favorite_border_rounded, size: 72, color: AppTheme.divider),
                  SizedBox(height: 16),
                  Text('لا توجد عناصر في المفضلة',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text('أضف أفلامك المفضلة لتجدها هنا',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ]))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, childAspectRatio: 130 / 195,
                    crossAxisSpacing: 10, mainAxisSpacing: 12),
                  itemCount: favs.length,
                  itemBuilder: (_, i) => VideoCard(
                    video: favs[i], width: double.infinity, height: double.infinity),
                ),
        ),
      ])),
    );
  }
}
