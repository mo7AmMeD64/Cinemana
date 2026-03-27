import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../models/category.dart';

class CinemanaService {
  static const String _base = 'https://cinemana.shabakaty.com';

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36',
    'Accept': 'application/json, text/plain, */*',
    'Origin': 'https://cinemana.shabakaty.com',
    'Referer': 'https://cinemana.shabakaty.com/',
  };

  Future<dynamic> _get(String path) async {
    try {
      final res = await http
          .get(Uri.parse('$_base$path'), headers: _headers)
          .timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return null;
      return jsonDecode(res.body);
    } catch (_) {
      return null;
    }
  }

  // ─── أحدث الإضافات ──────────────────────────────────────────────────────────
  Future<List<CinemanaVideo>> getNewlyAdded() async {
    final d = await _get('/api/android/newlyVideosItems/level/0/offset/12/page/1/');
    if (d is! List) return [];
    return d.map<CinemanaVideo>((e) => CinemanaVideo.fromJson(e)).toList();
  }

  // ─── الرئيسية ────────────────────────────────────────────────────────────────
  Future<Map<String, List<CinemanaVideo>>> getHomeGroups() async {
    final Map<String, List<CinemanaVideo>> result = {};

    final newly = await getNewlyAdded();
    if (newly.isNotEmpty) result['🔥 أحدث الإضافات'] = newly;

    final groups = await _get('/api/android/videoGroups/lang/ar/level/0');
    if (groups is List) {
      for (final g in groups) {
        final gid = g['id']?.toString();
        final gtitle = g['title']?.toString() ?? '';
        if (gid == null || gtitle.isEmpty) continue;
        final gc = await _get(
            '/api/android/videoListPagination/groupID/$gid/level/0/itemsPerPage/24/page/1');
        if (gc is List && gc.isNotEmpty) {
          result[gtitle] =
              gc.map<CinemanaVideo>((e) => CinemanaVideo.fromJson(e)).toList();
        }
      }
    }

    final sorts = [
      ['🎬 أفلام - الأحدث', '1', 'desc'],
      ['📺 مسلسلات - الأحدث', '2', 'desc'],
      ['⭐ أفلام - أعلى تقييماً', '1', 'stars_desc'],
      ['⭐ مسلسلات - أعلى تقييماً', '2', 'stars_desc'],
      ['👁️ الأكثر مشاهدة', '1', 'views_desc'],
      ['📅 حسب سنة الإصدار', '2', 'r_desc'],
    ];

    for (final s in sorts) {
      final d = await _get(
          '/api/android/video/V/2/itemsPerPage/24/level/0/videoKind/${s[1]}/sortParam/${s[2]}/pageNumber/1');
      if (d is List && d.isNotEmpty) {
        result[s[0]] =
            d.map<CinemanaVideo>((e) => CinemanaVideo.fromJson(e)).toList();
      }
    }

    return result;
  }

  // ─── بحث ─────────────────────────────────────────────────────────────────────
  Future<List<CinemanaVideo>> search(String q) async {
    final encoded = Uri.encodeComponent(q);
    final base =
        'level=0&videoTitle=$encoded&staffTitle=$encoded&year=1900,2030&page=0&itemsPerPage=30';

    final results = <CinemanaVideo>[];
    final raw = await Future.wait([
      _get('/api/android/AdvancedSearch?$base&type=movies'),
      _get('/api/android/AdvancedSearch?$base&type=series'),
    ]);

    for (final d in raw) {
      if (d is List) {
        results.addAll(d.map<CinemanaVideo>((e) => CinemanaVideo.fromJson(e)));
      }
    }
    return results;
  }

  // ─── تفاصيل ──────────────────────────────────────────────────────────────────
  Future<CinemanaVideo?> getVideoDetails(String id) async {
    final d = await _get('/api/android/allVideoInfo/id/$id');
    if (d is Map<String, dynamic>) return CinemanaVideo.fromJson(d);
    return null;
  }

  // ─── روابط التشغيل ───────────────────────────────────────────────────────────
  Future<List<VideoQuality>> getQualities(String id) async {
    final d = await _get('/api/android/transcoddedFiles/id/$id');
    if (d is! List) return [];
    return d.map<VideoQuality>((e) => VideoQuality.fromJson(e)).toList();
  }

  // ─── الترجمات ────────────────────────────────────────────────────────────────
  Future<List<CinemanaSubtitle>> getSubtitles(String id) async {
    final d = await _get('/api/android/allVideoInfo/id/$id');
    if (d is! Map) return [];
    final translations = d['translations'];
    if (translations is! List) return [];
    return translations
        .map<CinemanaSubtitle>((e) => CinemanaSubtitle.fromJson(e))
        .toList();
  }

  // ─── حلقات المسلسل ───────────────────────────────────────────────────────────
  Future<List<CinemanaVideo>> getSeasonEpisodes(String seriesId,
      [int? season]) async {
    String path = '/api/android/videoSeason/id/$seriesId';
    if (season != null) path += '/season/$season';
    final d = await _get(path);
    if (d is! List) return [];
    return d.map<CinemanaVideo>((e) => CinemanaVideo.fromJson(e)).toList();
  }

  // ─── الأقسام ─────────────────────────────────────────────────────────────────
  Future<List<CinemanaCategory>> getCategories({bool isSeries = false}) async {
    final cats = await _get('/api/android/videoCategories/lang/ar/level/0');
    if (cats is List) {
      return cats
          .map<CinemanaCategory>((e) => CinemanaCategory.fromJson(e))
          .toList();
    }
    return [];
  }

  // ─── محتوى قسم ───────────────────────────────────────────────────────────────
  Future<List<CinemanaVideo>> getCategoryContent(
      String catId, int page, {bool isSeries = false}) async {
    final kind = isSeries ? '2' : '1';
    final d = await _get(
        '/api/android/video/V/2/itemsPerPage/24/level/0/videoKind/$kind/categoryId/$catId/sortParam/desc/pageNumber/$page');
    if (d is! List) return [];
    return d.map<CinemanaVideo>((e) => CinemanaVideo.fromJson(e)).toList();
  }
}
