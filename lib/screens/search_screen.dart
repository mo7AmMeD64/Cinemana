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
  final _controller = TextEditingController();
  List<Video> _results = [];
  bool _loading = false;
  bool _searched = false;
  Timer? _debounce;

  void _onSearch(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 600), () => _search(query));
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    final results = await _service.search(query.trim());
    if (mounted) {
      setState(() {
        _results = results;
        _loading = false;
        _searched = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(
          children: [
            // شريط البحث
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _controller,
                onChanged: _onSearch,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'ابحث عن فيلم أو مسلسل...',
                  prefixIcon: _loading
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.accent,
                            ),
                          ),
                        )
                      : const Icon(Icons.search_rounded,
                          color: AppTheme.textSecondary),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AppTheme.textSecondary),
                          onPressed: () {
                            _controller.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // النتائج
            Expanded(
              child: _results.isEmpty && !_loading
                  ? _buildEmptyState()
                  : _buildGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 130 / 195,
        crossAxisSpacing: 10,
        mainAxisSpacing: 12,
      ),
      itemCount: _results.length,
      itemBuilder: (_, i) => VideoCard(
        video: _results[i],
        width: double.infinity,
        height: double.infinity,
      ),
    );
  }

  Widget _buildEmptyState() {
    if (!_searched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_rounded, size: 72, color: AppTheme.divider),
            SizedBox(height: 16),
            Text(
              'ابحث عن أفلامك المفضلة',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_filter_outlined, size: 64, color: AppTheme.divider),
          SizedBox(height: 12),
          Text(
            'لا توجد نتائج',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
