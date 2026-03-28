import 'package:flutter/material.dart';
import '../models/video.dart';
import '../services/cinemana_service.dart';
import '../utils/app_theme.dart';
import '../widgets/video_card.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  final _service = CinemanaService();
  late TabController _tab;
  bool _loading = true;

  // بدل الأقسام: نستخدم قوائم مرتبة مثل الموقع
  final List<_CatItem> _movieCats = [
    _CatItem('الأحدث', '1', 'desc'),
    _CatItem('أعلى تقييماً', '1', 'stars_desc'),
    _CatItem('الأكثر مشاهدة', '1', 'views_desc'),
    _CatItem('حسب سنة الإصدار', '1', 'r_desc'),
    _CatItem('أبجدياً', '1', 'title_asc'),
  ];

  final List<_CatItem> _seriesCats = [
    _CatItem('الأحدث', '2', 'desc'),
    _CatItem('أعلى تقييماً', '2', 'stars_desc'),
    _CatItem('الأكثر مشاهدة', '2', 'views_desc'),
    _CatItem('حسب سنة الإصدار', '2', 'r_desc'),
    _CatItem('أبجدياً', '2', 'title_asc'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    setState(() => _loading = false);
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: const [
            Text('الأقسام',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary)),
          ]),
        ),
        TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [Tab(text: 'أفلام'), Tab(text: 'مسلسلات')],
        ),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent))
              : TabBarView(controller: _tab, children: [
                  _buildGrid(_movieCats),
                  _buildGrid(_seriesCats),
                ]),
        ),
      ])),
    );
  }

  Widget _buildGrid(List<_CatItem> cats) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 2.2,
          crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: cats.length,
      itemBuilder: (_, i) => _CatTile(
        item: cats[i],
        service: _service,
      ),
    );
  }
}

class _CatItem {
  final String title;
  final String kind;
  final String sort;
  const _CatItem(this.title, this.kind, this.sort);
}

class _CatTile extends StatelessWidget {
  final _CatItem item;
  final CinemanaService service;
  const _CatTile({required this.item, required this.service});

  static const _colors = [
    Color(0xFF1a1a2e), Color(0xFF16213e),
    Color(0xFF0f3460), Color(0xFF1a0a2e), Color(0xFF2e1a0a),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = item.title.length % _colors.length;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => _ContentListScreen(item: item, service: service))),
      child: Container(
        decoration: BoxDecoration(
          color: _colors[idx],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.kind == '1' ? Icons.movie_rounded : Icons.live_tv_rounded,
                color: AppTheme.accent, size: 22,
              ),
              const SizedBox(height: 6),
              Text(item.title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700,
                      color: Colors.white),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── شاشة قائمة المحتوى ───────────────────────────────────────────────────────
class _ContentListScreen extends StatefulWidget {
  final _CatItem item;
  final CinemanaService service;
  const _ContentListScreen({super.key, required this.item, required this.service});
  @override
  State<_ContentListScreen> createState() => _ContentListScreenState();
}

class _ContentListScreenState extends State<_ContentListScreen> {
  final List<CinemanaVideo> _videos = [];
  int _page = 1;
  bool _loading = false, _hasMore = true;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) _load();
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  Future<void> _load() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    final items = await widget.service.getSortedVideos(
      kind: widget.item.kind,
      sort: widget.item.sort,
      page: _page,
    );
    if (mounted) setState(() {
      _videos.addAll(items);
      _page++;
      _loading = false;
      if (items.length < 24) _hasMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: Text(widget.item.title),
        backgroundColor: AppTheme.bg,
      ),
      body: _videos.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : GridView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, childAspectRatio: 130 / 195,
                  crossAxisSpacing: 10, mainAxisSpacing: 12),
              itemCount: _videos.length + (_loading ? 3 : 0),
              itemBuilder: (_, i) {
                if (i < _videos.length) {
                  return VideoCard(video: _videos[i],
                      width: double.infinity, height: double.infinity);
                }
                return Container(decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(10)));
              },
            ),
    );
  }
}
