import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/video.dart';
import '../utils/app_theme.dart';
import '../screens/details_screen.dart';

class VideoCard extends StatelessWidget {
  final CinemanaVideo video;
  final double width;
  final double height;

  const VideoCard({super.key, required this.video, this.width = 130, this.height = 195});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailsScreen(video: video))),
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppTheme.card,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(fit: StackFit.expand, children: [
            video.poster.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: video.poster, fit: BoxFit.cover,
                    placeholder: (_, __) => Shimmer.fromColors(
                      baseColor: AppTheme.card,
                      highlightColor: AppTheme.surface,
                      child: Container(color: AppTheme.card),
                    ),
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),

            // gradient
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                height: height * 0.5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
            ),

            // type badge
            Positioned(
              top: 6, right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: video.isSeries ? AppTheme.accent : AppTheme.accentGold.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  video.isSeries ? 'مسلسل' : 'فيلم',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),

            // title + rating
            Positioned(
              bottom: 6, left: 6, right: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(video.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
                  ),
                  if (video.rating > 0) ...[
                    const SizedBox(height: 3),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(video.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10, color: AppTheme.accentGold, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 2),
                      const Icon(Icons.star_rounded, size: 11, color: AppTheme.accentGold),
                    ]),
                  ],
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: AppTheme.card,
    child: const Icon(Icons.movie_outlined, color: AppTheme.textSecondary, size: 36),
  );
}
