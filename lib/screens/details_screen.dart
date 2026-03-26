import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video.dart';
import '../services/cinemana_service.dart';
import '../services/favorites_provider.dart';
import '../utils/app_theme.dart';

class DetailsScreen extends StatefulWidget {
  final Video video;
  const DetailsScreen({super.key, required this.video});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final _service = CinemanaService();
  Video? _fullVideo;
  List<VideoQuality> _qualities = [];
  Map<int, List<Video>> _seasonEpisodes = {};
  int _selectedSeason = 1;
  bool _loadingDetails = true;
  bool _loadingQualities = false;
  bool _loadingEpisodes = false;
  bool _showQualities = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await _service.getVideoDetails(widget.video.id);
    if (mounted) {
      setState(() {
        _fullVideo = details ?? widget.video;
        _loadingDetails = false;
      });
      if (_fullVideo!.isSeries && _fullVideo!.seasons.isNotEmpty) {
        _selectedSeason = _fullVideo!.seasons.first;
        _loadEpisodes(_selectedSeason);
      }
    }
  }

  Future<void> _loadEpisodes(int season) async {
    if (_seasonEpisodes.containsKey(season)) return;
    setState(() => _loadingEpisodes = true);
    final eps = await _service.getSeasonEpisodes(widget.video.id, season);
    if (mounted) {
      setState(() {
        _seasonEpisodes[season] = eps;
        _loadingEpisodes = false;
      });
    }
  }

  Future<void> _loadQualities({String? episodeId}) async {
    final id = episodeId ?? widget.video.id;
    setState(() {
      _loadingQualities = true;
      _showQualities = true;
      _qualities = [];
    });
    final qualities = await _service.getVideoQualities(id);
    if (mounted) {
      setState(() {
        _qualities = qualities;
        _loadingQualities = false;
      });
    }
  }

  Video get _video => _fullVideo ?? widget.video;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: _loadingDetails
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : CustomScrollView(
              slivers: [
                _buildHero(),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildMeta(),
                        const SizedBox(height: 12),
                        if (_video.categories.isNotEmpty) _buildCategories(),
                        const SizedBox(height: 12),
                        if (_video.description.isNotEmpty) _buildDescription(),
                        const SizedBox(height: 20),
                        _buildActions(),
                        if (_showQualities) ...[
                          const SizedBox(height: 20),
                          _buildQualitySection(),
                        ],
                        if (_video.isSeries) ...[
                          const SizedBox(height: 24),
                          _buildSeasonsSection(),
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ─── Hero ────────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppTheme.bg,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // صورة الغلاف
            _video.cover.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: _video.cover,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _video.poster.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _video.poster, fit: BoxFit.cover)
                        : Container(color: AppTheme.card),
                  )
                : _video.poster.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _video.poster, fit: BoxFit.cover)
                    : Container(color: AppTheme.card),

            // gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5, 1.0],
                  colors: [
                    Colors.black38,
                    Colors.transparent,
                    AppTheme.bg,
                  ],
                ),
              ),
            ),

            // بوستر صغير في الأسفل يسار
            Positioned(
              bottom: 12,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _video.poster.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _video.poster,
                        width: 80,
                        height: 115,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 115,
                        color: AppTheme.card,
                        child: const Icon(Icons.movie_outlined,
                            color: AppTheme.textSecondary),
                      ),
              ),
            ),

            // العنوان فوق البوستر
            Positioned(
              bottom: 16,
              left: 16,
              right: 112,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _video.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  if (_video.titleEn.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _video.titleEn,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Meta ─────────────────────────────────────────────────────────────────────
  Widget _buildMeta() {
    final badges = <Widget>[];

    if (_video.year.isNotEmpty) {
      badges.add(_badge(Icons.calendar_today_rounded, _video.year));
    }
    if (_video.duration.isNotEmpty) {
      badges.add(_badge(Icons.timer_rounded, '${_video.duration} د'));
    }
    if (_video.rating > 0) {
      badges.add(_ratingBadge(_video.rating));
    }
    if (_video.isSeries && _video.seasonsCount > 0) {
      badges.add(_badge(
          Icons.video_library_rounded, '${_video.seasonsCount} موسم'));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: badges,
    );
  }

  Widget _badge(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(icon, size: 13, color: AppTheme.textSecondary),
          ],
        ),
      );

  Widget _ratingBadge(double r) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.accentGold.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(r.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.star_rounded, size: 13, color: AppTheme.accentGold),
          ],
        ),
      );

  // ─── Categories ───────────────────────────────────────────────────────────────
  Widget _buildCategories() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: _video.categories
          .map((cat) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: AppTheme.accent.withOpacity(0.4), width: 1),
                ),
                child: Text(cat,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.accent,
                        fontWeight: FontWeight.w600)),
              ))
          .toList(),
    );
  }

  // ─── Description ─────────────────────────────────────────────────────────────
  Widget _buildDescription() {
    return Text(
      _video.description,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: const TextStyle(
        fontSize: 13,
        color: AppTheme.textSecondary,
        height: 1.7,
      ),
    );
  }

  // ─── Actions ─────────────────────────────────────────────────────────────────
  Widget _buildActions() {
    final favProv = context.watch<FavoritesProvider>();
    final isFav = favProv.isFav(_video.id);

    return Row(
      children: [
        // زر المفضلة
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => favProv.toggle(_video),
            icon: Icon(
              isFav ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFav ? AppTheme.accentGold : AppTheme.textSecondary,
            ),
            label: Text(
              isFav ? 'في المفضلة' : 'إضافة للمفضلة',
              style: TextStyle(
                color: isFav ? AppTheme.accentGold : AppTheme.textSecondary,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: isFav ? AppTheme.accentGold : AppTheme.divider,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // زر جلب روابط التشغيل (فقط للأفلام)
        if (!_video.isSeries)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _loadingQualities ? null : () => _loadQualities(),
              icon: _loadingQualities
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.download_rounded),
              label: const Text('جلب الروابط'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
      ],
    );
  }

  // ─── Quality Section ─────────────────────────────────────────────────────────
  Widget _buildQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('اختيار الجودة',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            SizedBox(width: 8),
            Icon(Icons.high_quality_rounded, color: AppTheme.accent),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingQualities)
          const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
        else if (_qualities.isEmpty)
          const Text('لا توجد روابط متاحة',
              style: TextStyle(color: AppTheme.textSecondary))
        else
          ..._qualities.map((q) => _QualityTile(quality: q)),
      ],
    );
  }

  // ─── Seasons Section ─────────────────────────────────────────────────────────
  Widget _buildSeasonsSection() {
    final seasons = _video.seasons;
    if (seasons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('المواسم والحلقات',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
            SizedBox(width: 8),
            Icon(Icons.video_library_rounded, color: AppTheme.accent),
          ],
        ),
        const SizedBox(height: 12),

        // تبويبات المواسم
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: seasons.length,
            itemBuilder: (_, i) {
              final s = seasons[i];
              final active = s == _selectedSeason;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedSeason = s);
                  _loadEpisodes(s);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(left: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.accent : AppTheme.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'موسم $s',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : AppTheme.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // حلقات الموسم المختار
        if (_loadingEpisodes)
          const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: AppTheme.accent),
          ))
        else
          ...(_seasonEpisodes[_selectedSeason] ?? []).map((ep) => _EpisodeTile(
                episode: ep,
                onFetchLinks: () => _loadQualities(episodeId: ep.id),
              )),
      ],
    );
  }
}

// ─── Episode Tile ─────────────────────────────────────────────────────────────
class _EpisodeTile extends StatelessWidget {
  final Video episode;
  final VoidCallback onFetchLinks;

  const _EpisodeTile({
    required this.episode,
    required this.onFetchLinks,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider, width: 1),
      ),
      child: Row(
        children: [
          // زر جلب روابط
          GestureDetector(
            onTap: onFetchLinks,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.download_rounded,
                  color: AppTheme.accent, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // معلومات
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  episode.title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (episode.duration.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${episode.duration} دقيقة',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          // صورة مصغرة
          if (episode.poster.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: episode.poster,
                width: 64,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Quality Tile ─────────────────────────────────────────────────────────────
class _QualityTile extends StatelessWidget {
  final VideoQuality quality;

  const _QualityTile({required this.quality});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.accent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            quality.quality.isNotEmpty ? quality.quality : quality.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          quality.url,
          textAlign: TextAlign.right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            direction: TextDirection.ltr,
          ),
        ),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // زر نسخ
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              color: AppTheme.textSecondary,
              onPressed: () {
                // Copy to clipboard
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ الرابط'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppTheme.surface,
                  ),
                );
              },
            ),
            // زر فتح
            IconButton(
              icon: const Icon(Icons.open_in_browser_rounded, size: 18),
              color: AppTheme.accent,
              onPressed: () async {
                final uri = Uri.tryParse(quality.url);
                if (uri != null) await launchUrl(uri);
              },
            ),
          ],
        ),
      ),
    );
  }
}
