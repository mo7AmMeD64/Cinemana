import 'package:flutter/material.dart';
import '../models/video.dart';
import '../services/cinemana_service.dart';
import '../utils/app_theme.dart';
import '../widgets/video_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _service = CinemanaService();
  Map<String, List<Video>> _groups = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final g = await _service.getHomeGroups();
    if (mounted) setState(() { _groups = g; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: _loading
            ? _skeleton()
            : _groups.isEmpty
                ? _empty()
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppTheme.accent,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 16),
                      children: [
                        _header(),
                        ..._groups.entries.map((e) => _group(e.key, e.value)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          const Spacer(),
          const Text('سينـمانا',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.accent)),
          const SizedBox(width: 8),
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.movie_filter_rounded, color: Colors.white, size: 18),
          ),
        ]),
      );

  Widget _group(String title, List<Video> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Container(width: 4, height: 18, margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(2))),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ]),
      ),
      SizedBox(
        height: 195,
        child: ListView.builder(
          scrollDirection: Axis.horizontal, reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.only(left: 10),
            child: VideoCard(video: items[i]),
          ),
        ),
      ),
    ]);
  }

  Widget _skeleton() => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 60),
          ...List.generate(3, (_) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const SizedBox(height: 20),
            Container(height: 18, width: 100, decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 12),
            SizedBox(height: 195, child: ListView.builder(
              scrollDirection: Axis.horizontal, reverse: true, itemCount: 5,
              itemBuilder: (_, __) => Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Container(width: 130, decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(10))),
              ),
            )),
          ])),
        ],
      );

  Widget _empty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.signal_wifi_off_rounded, size: 64, color: AppTheme.textSecondary),
        const SizedBox(height: 16),
        const Text('تعذّر تحميل المحتوى', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        const SizedBox(height: 16),
        TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة المحاولة'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.accent)),
      ]));
}
