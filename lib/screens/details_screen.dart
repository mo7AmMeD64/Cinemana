import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/video.dart';
import '../services/cinemana_service.dart';
import '../services/favorites_provider.dart';
import '../utils/app_theme.dart';
import 'player_screen.dart';

class DetailsScreen extends StatefulWidget {
  final CinemanaVideo video;
  const DetailsScreen({super.key, required this.video});
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final _service = CinemanaService();
  CinemanaVideo? _full;
  bool _loadingDetails = true;

  // حلقات — مثل الموقع: نجيب الكل ثم نقسمهم حسب season
  List<CinemanaVideo> _allEpisodes = [];
  int _selectedSeason = 1;
  List<int> _seasons = [];
  bool _loadingEpisodes = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final d = await _service.getVideoDetails(widget.video.id);
    if (!mounted) return;
    setState(() {
      _full = d ?? widget.video;
      _loadingDetails = false;
    });
    // إذا مسلسل: جيب الحلقات مباشرة بدون رقم موسم
    if (_full!.isSeries) _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    setState(() => _loadingEpisodes = true);
    // مثل الموقع: /api/android/videoSeason/id/{id} بدون رقم موسم
    final eps = await _service.getSeasonEpisodes(widget.video.id);
    if (!mounted) return;
    // استخرج أرقام المواسم من الحلقات
    final seasonSet = <int>{};
    for (final ep in eps) {
      final s = int.tryParse(ep.season) ?? 1;
      seasonSet.add(s);
    }
    final seasons = seasonSet.toList()..sort();
    setState(() {
      _allEpisodes = eps;
      _seasons = seasons.isEmpty ? [1] : seasons;
      _selectedSeason = _seasons.first;
      _loadingEpisodes = false;
    });
  }

  List<CinemanaVideo> get _curEps => _allEpisodes
      .where((ep) => (int.tryParse(ep.season) ?? 1) == _selectedSeason)
      .toList()
    ..sort((a, b) => (int.tryParse(a.episodeNum) ?? 0)
        .compareTo(int.tryParse(b.episodeNum) ?? 0));

  // تشغيل: جيب روابط + ترجمات ثم افتح PlayerScreen مباشرة
  Future<void> _play(String videoId, String title) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: AppTheme.accent)),
    );

    final qualities = await _service.getQualities(videoId);
    final subtitles = await _service.getSubtitles(videoId);

    if (!mounted) return;
    Navigator.pop(context); // أغلق loading

    if (qualities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('لا توجد روابط متاحة'),
        backgroundColor: AppTheme.accent,
      ));
      return;
    }

    // إذا جودة واحدة: شغّل مباشرة
    if (qualities.length == 1) {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PlayerScreen(
          url: qualities.first.url,
          title: title,
          subtitles: subtitles,
        ),
      ));
      return;
    }

    // أكثر من جودة: اختيار
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('اختيار الجودة',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textPrimary)),
          ),
          ...qualities.map((q) {
            final label = q.quality.isNotEmpty ? q.quality : 'تشغيل';
            final isHD = label.contains('1080') || label.contains('720');
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isHD
                      ? AppTheme.accentGold.withOpacity(0.15)
                      : AppTheme.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: isHD
                          ? AppTheme.accentGold.withOpacity(0.5)
                          : AppTheme.accent.withOpacity(0.4)),
                ),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isHD ? AppTheme.accentGold : AppTheme.accent)),
              ),
              title: Text(q.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    url: q.url,
                    title: title,
                    subtitles: subtitles,
                  ),
                ));
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  CinemanaVideo get _v => _full ?? widget.video;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: _loadingDetails
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent))
          : CustomScrollView(slivers: [
              _buildHero(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildMeta(),
                      const SizedBox(height: 10),
                      if (_v.categories.isNotEmpty) _buildCats(),
                      const SizedBox(height: 12),
                      if (_v.description.isNotEmpty) _buildDesc(),
                      const SizedBox(height: 20),
                      _buildActions(),
                      if (_v.isSeries) ...[
                        const SizedBox(height: 24),
                        _buildEpisodes(),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ]),
    );
  }

  Widget _buildHero() => SliverAppBar(
        expandedHeight: 280,
        pinned: true,
        backgroundColor: AppTheme.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: FlexibleSpaceBar(
          background: Stack(fit: StackFit.expand, children: [
            _v.cover.isNotEmpty
                ? CachedNetworkImage(imageUrl: _v.cover, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => _v.poster.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _v.poster, fit: BoxFit.cover)
                        : Container(color: AppTheme.card))
                : _v.poster.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _v.poster, fit: BoxFit.cover)
                    : Container(color: AppTheme.card),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.5, 1.0],
                  colors: [Colors.black38, Colors.transparent, AppTheme.bg],
                ),
              ),
            ),
            Positioned(
              bottom: 12, right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _v.poster.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _v.poster,
                        width: 80, height: 115, fit: BoxFit.cover)
                    : Container(
                        width: 80, height: 115, color: AppTheme.card),
              ),
            ),
            Positioned(
              bottom: 16, left: 16, right: 112,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_v.title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.3),
                      textAlign: TextAlign.right),
                  if (_v.titleAr.isNotEmpty && _v.titleAr != _v.title)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(_v.titleAr,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ),
                ],
              ),
            ),
          ]),
        ),
      );

  Widget _buildMeta() => Wrap(
        spacing: 8, runSpacing: 8, alignment: WrapAlignment.end,
        children: [
          if (_v.year.isNotEmpty) _badge(Icons.calendar_today_rounded, _v.year),
          if (_v.duration.isNotEmpty)
            _badge(Icons.timer_rounded, '${_v.duration} د'),
          if (_v.rating > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.accentGold.withOpacity(0.5)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_v.rating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.accentGold,
                        fontWeight: FontWeight.w700)),
                const SizedBox(width: 4),
                const Icon(Icons.star_rounded,
                    size: 13, color: AppTheme.accentGold),
              ]),
            ),
          if (_v.isSeries && _seasons.isNotEmpty)
            _badge(Icons.video_library_rounded, '${_seasons.length} موسم'),
        ],
      );

  Widget _badge(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(text,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 4),
          Icon(icon, size: 13, color: AppTheme.textSecondary),
        ]),
      );

  Widget _buildCats() => Wrap(
        spacing: 6, runSpacing: 6, alignment: WrapAlignment.end,
        children: _v.categories
            .map((c) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: AppTheme.accent.withOpacity(0.4)),
                  ),
                  child: Text(c,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600)),
                ))
            .toList(),
      );

  Widget _buildDesc() => Text(
        _v.description,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
            fontSize: 13, color: AppTheme.textSecondary, height: 1.7),
      );

  Widget _buildActions() {
    final fav = context.watch<FavoritesProvider>();
    final isFav = fav.isFav(_v.id);
    return Row(children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => fav.toggle(_v),
          icon: Icon(
              isFav ? Icons.star_rounded : Icons.star_border_rounded,
              color: isFav ? AppTheme.accentGold : AppTheme.textSecondary),
          label: Text(isFav ? 'في المفضلة' : 'إضافة للمفضلة',
              style: TextStyle(
                  color: isFav
                      ? AppTheme.accentGold
                      : AppTheme.textSecondary)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
                color: isFav ? AppTheme.accentGold : AppTheme.divider),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
      if (!_v.isSeries) ...[
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _play(_v.id, _v.title),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('تشغيل'),
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
    ]);
  }

  Widget _buildEpisodes() {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      const Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Text('المواسم والحلقات',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary)),
        SizedBox(width: 8),
        Icon(Icons.video_library_rounded, color: AppTheme.accent),
      ]),
      const SizedBox(height: 12),

      // تبويبات المواسم
      if (_seasons.length > 1)
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            reverse: true,
            itemCount: _seasons.length,
            itemBuilder: (_, i) {
              final s = _seasons[i];
              final active = s == _selectedSeason;
              return GestureDetector(
                onTap: () => setState(() => _selectedSeason = s),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.accent : AppTheme.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('موسم $s',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? Colors.white
                              : AppTheme.textSecondary)),
                ),
              );
            },
          ),
        ),

      const SizedBox(height: 14),

      if (_loadingEpisodes)
        const Center(
            child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppTheme.accent)))
      else if (_curEps.isEmpty)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
              child: Text('لا توجد حلقات',
                  style: TextStyle(color: AppTheme.textSecondary))),
        )
      else
        ..._curEps.map((ep) => _EpisodeTile(
              episode: ep,
              onPlay: () => _play(ep.id, ep.title),
            )),
    ]);
  }
}

// ─── Episode Tile ─────────────────────────────────────────────────────────────
class _EpisodeTile extends StatelessWidget {
  final CinemanaVideo episode;
  final VoidCallback onPlay;
  const _EpisodeTile({required this.episode, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: onPlay,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(episode.title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
                if (episode.episodeNum.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                        'موسم ${episode.season} · حلقة ${episode.episodeNum}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary)),
                  ),
              ]),
        ),
        if (episode.poster.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                  imageUrl: episode.poster,
                  width: 70, height: 50, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
      ]),
    );
  }
}
