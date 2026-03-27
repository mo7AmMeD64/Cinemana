import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/category.dart';
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
  List<CinemanaCategory> _movieCats = [], _seriesCats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    final m = await _service.getCategories(isSeries: false);
    final s = await _service.getCategories(isSeries: true);
    if (mounted) setState(() { _movieCats = m; _seriesCats = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: const [
            Text('الأقسام', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
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
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
              : TabBarView(controller: _tab, children: [
                  _grid(_movieCats, isSeries: false),
                  _grid(_seriesCats, isSeries: true),
                ]),
        ),
      ])),
    );
  }

  Widget _grid(List<CinemanaCategory> cats, {required bool isSeries}) {
    if (cats.isEmpty) return const Center(
      child: Text('لا توجد أقسام', style: TextStyle(color: AppTheme.textSecondary)));
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 2.2,
        crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: cats.length,
      itemBuilder: (_, i) => _CatTile(cat: cats[i], isSeries: isSeries, service: _service),
    );
  }
}

class _CatTile extends StatelessWidget {
  final CinemanaCategory cat;
  final bool isSeries;
  final CinemanaService service;
  const _CatTile({required this.cat, required this.isSeries, required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => CategoryContentScreen(cat: cat, isSeries: isSeries, service: service))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(fit: StackFit.expand, children: [
          cat.image.isNotEmpty
              ? CachedNetworkImage(imageUrl: cat.image, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: AppTheme.card))
              : Container(color: AppTheme.card),
          Container(decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.black.withOpacity(0.3)]))),
          Center(child: Text(cat.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
            textAlign: TextAlign.center)),
        ]),
      ),
    );
  }
}

// ─── محتوى القسم ─────────────────────────────────────────────────────────────
class CategoryContentScreen extends StatefulWidget {
  final CinemanaCategory cat;
  final bool isSeries;
  final CinemanaService service;
  const CategoryContentScreen({super.key, required this.cat, required this.isSeries, required this.service});
  @override
  State<CategoryContentScreen> createState() => _CategoryContentScreenState();
}

class _CategoryContentScreenState extends State<CategoryContentScreen> {
  final List<CinemanaVideo> _videos = [];
  int _page = 0;
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
    final items = await widget.service.getCategoryContent(widget.cat.id, _page, isSeries: widget.isSeries);
    if (mounted) setState(() {
      _videos.addAll(items);
      _page++;
      _loading = false;
      if (items.length < 20) _hasMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: Text(widget.cat.title), backgroundColor: AppTheme.bg),
      body: GridView.builder(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, childAspectRatio: 130 / 195,
          crossAxisSpacing: 10, mainAxisSpacing: 12),
        itemCount: _videos.length + (_loading ? 3 : 0),
        itemBuilder: (_, i) {
          if (i < _videos.length) {
            return VideoCard(video: _videos[i], width: double.infinity, height: double.infinity);
          }
          return Container(decoration: BoxDecoration(
            color: AppTheme.card, borderRadius: BorderRadius.circular(10)));
        },
      ),
    );
  }
}
