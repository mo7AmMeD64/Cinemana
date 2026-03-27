import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../models/category.dart';

class CinemanaService {
  static const String _base = 'https://cinemana.shabakaty.com';
  static const Map<String, String> _headers = {
    'User-Agent': 'okhttp/4.9.1',
    'Accept': 'application/json',
    'Accept-Language': 'ar',
  };

  Future<T?> _get<T>(String path, T Function(dynamic) parser) async {
    try {
      final res = await http
          .get(Uri.parse('$_base$path'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      return parser(jsonDecode(res.body));
    } catch (_) {
      return null;
    }
  }

  // ─── الرئيسية ────────────────────────────────────────────────────────────────
  Future<Map<String, List<CinemanaVideo>>> getHomeGroups() async {
    final data = await _get('/api/android/v2/AllVideoByGroups/0/ar/0',
        (d) => d);
    if (data == null) return {};
    final Map<String, List<CinemanaVideo>> groups = {};
    if (data is List) {
      for (final g in data) {
        final title = g['title']?.toString() ?? '';
        final items = (g['data'] as List? ?? []);
        if (title.isNotEmpty && items.isNotEmpty) {
          groups[title] = items.map((e) => CinemanaVideo.fromJson(e)).toList();
        }
      }
    }
    return groups;
  }

  // ─── بحث ─────────────────────────────────────────────────────────────────────
  Future<List<CinemanaVideo>> search(String q) async {
    final data = await _get(
        '/api/android/v2/search/0/ar/$q', (d) => d is List ? d : []);
    return (data ?? []).map<CinemanaVideo>((e) => CinemanaVideo.fromJson(e)).toList();
  }

  // ─── تفاصيل ──────────────────────────────────────────────────────────────────
  Future<CinemanaVideo?> getVideoDetails(String id) async {
    final data = await _get(
        '/api/android/v2/videoInfo/$id/ar', (d) => d);
    if (data is Map<String, dynamic>) return CinemanaVideo.fromJson(data);
    return null;
  }

  // ─── جودات الفيديو ───────────────────────────────────────────────────────────
  Future<List<VideoQuality>> getQualities(String id) async {
    final data = await _get(
        '/api/android/v2/videoTranscode/$id/ar', (d) => d is List ? d : []);
    return (data ?? []).map<VideoQuality>((e) => VideoQuality.fromJson(e)).toList();
  }

  // ─── الترجمات ────────────────────────────────────────────────────────────────
  Future<List<CinemanaSubtitle>> getSubtitles(String id) async {
    final data = await _get(
        '/api/android/v2/videoSubtitle/$id/ar', (d) => d is List ? d : []);
    return (data ?? []).map<CinemanaSubtitle>((e) => CinemanaSubtitle.fromJson(e)).toList();
  }

  // ─── المواسم والحلقات ────────────────────────────────────────────────────────
  Future<List<CinemanaVideo>> getSeasonEpisodes(String seriesId, int season) async {
    final data = await _get(
        '/api/android/v2/videoSeason/$seriesId/$season/ar',
        (d) => d is List ? d : []);
    return (data ?? []).map<CinemanaVideo>((e) => CinemanaVideo.fromJson(e)).toList();
  }

  // ─── الأقسام ─────────────────────────────────────────────────────────────────
  Future<List<CinemanaCategory>> getCategories({bool isSeries = false}) async {
    final t = isSeries ? '2' : '1';
    final data = await _get(
        '/api/android/v2/Categories/$t/ar', (d) => d is List ? d : []);
    return (data ?? [])
        .map<CinemanaCategory>((e) => CinemanaCategory.fromJson(e))
        .toList();
  }

  Future<List<CinemanaVideo>> getCategoryContent(String catId, int page,
      {bool isSeries = false}) async {
    final t = isSeries ? '2' : '1';
    final data = await _get(
        '/api/android/v2/videoByCategories/$t/$catId/$page/ar',
        (d) => d is List ? d : []);
    return (data ?? []).map<CinemanaVideo>((e) => CinemanaVideo.fromJson(e)).toList();
  }

  // ─── أحدث + أعلى تقييماً ─────────────────────────────────────────────────────
  Future<List<CinemanaVideo>> getLatest({int page = 0, bool isSeries = false}) async {
    final t = isSeries ? '2' : '1';
    final data = await _get(
        '/api/android/v2/latestVideos/$t/$page/ar', (d) => d is List ? d : []);
    return (data ?? []).map<CinemanaVideo>((e) => CinemanaVideo.fromJson(e)).toList();
  }

  Future<List<CinemanaVideo>> getTopRated({int page = 0, bool isSeries = false}) async {
    final t = isSeries ? '2' : '1';
    final data = await _get(
        '/api/android/v2/topRatedVideos/$t/$page/ar',
        (d) => d is List ? d : []);
    return (data ?? []).map<CinemanaVideo>((e) => CinemanaVideo.fromJson(e)).toList();
  }
}
