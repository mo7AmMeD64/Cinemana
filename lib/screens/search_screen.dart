import 'dart:async';
import 'package:flutter/material.dart';
import '../models/video.dart';
import '../services/cinemana_service.dart';
import '../utils/app_theme.dart';
import '../widgets/video_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _service = CinemanaService();
  final _ctrl = TextEditingController();
  List<CinemanaVideo> _results = [];
  bool _loading = false, _searched = false;
  Timer? _debounce;

  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) { setState(() { _results = []; _searched = false; }); return; }
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _loading = true);
    final r = await _service.search(q.trim());
    if (mounted) setState(() { _results = r; _loading = false; _searched = true; });
  }

  @override
  void dispose() { _ctrl.dispose(); _debounce?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: _ctrl, onChanged: _onChanged,
            textAlign: TextAlign.right, textDirection: TextDirection.rtl,
            autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'ابحث عن فيلم أو مسلسل...',
              prefixIcon: _loading
                  ? const Padding(padding: EdgeInsets.all(12),
                      child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent)))
                  : const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, color: AppTheme.textSecondary),
                      onPressed: () { _ctrl.clear(); _onChanged(''); })
                  : null,
            ),
          ),
        ),
        Expanded(
          child: _results.isEmpty && !_loading
              ? _emptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, childAspectRatio: 130 / 195,
                    crossAxisSpacing: 10, mainAxisSpacing: 12),
                  itemCount: _results.length,
                  itemBuilder: (_, i) => VideoCard(
                    video: _results[i], width: double.infinity, height: double.infinity),
                ),
        ),
      ])),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(_searched ? Icons.movie_filter_outlined : Icons.search_rounded,
          size: 72, color: AppTheme.divider),
        const SizedBox(height: 16),
        Text(_searched ? 'لا توجد نتائج' : 'ابحث عن أفلامك المفضلة',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
      ]));
}
