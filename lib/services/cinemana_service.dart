import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video.dart';
import '../models/category.dart';

class CinemanaService {
  static const String _baseUrl = 'https://cinemana.shabakaty.com';

  // Headers تقليد التطبيق الأصلي
  static const Map<String, String> _headers = {
    'User-Agent': 'okhttp/4.9.1',
    'Accept': 'application/json',
    'Accept-Language': 'ar',
  };

  // ─── الرئيسية ───────────────────────────────────────────────────────────────

  /// جلب الفيديوهات المقسّمة في الصفحة الرئيسية (مسلسلات، أفلام، حلقات جديدة...)
  Future<Map<String, List<Video>>> getHomeGroups() async {
    try {
      final url = Uri.parse('$_baseUrl/api/android/v2/AllVideoByGroups/0/ar/0');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) return {};

      final data = jsonDecode(response.body);
      final Map<String, List<Video>> groups = {};

      if (data is List) {
        for (final group in data) {
          final title = group['title']?.toString() ?? 'بدون عنوان';
          final items = group['data'] as List? ?? [];
          groups[title] = items.map((e) => Video.fromJson(e)).toList();
        }
      } else if (data is Map) {
        // بعض الـ endpoints ترجع map
        data.forEach((key, value) {
          if (value is List) {
            groups[key] = value.map((e) => Video.fromJson(e)).toList();
          }
        });
      }

      return groups;
    } catch (e) {
      return {};
    }
  }

  // ─── بحث ────────────────────────────────────────────────────────────────────

  /// البحث عن فيلم أو مسلسل بالاسم
  Future<List<Video>> search(String query) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/api/android/v2/search/0/ar/$query');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Video.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── تفاصيل ─────────────────────────────────────────────────────────────────

  /// تفاصيل فيديو بالـ ID
  Future<Video?> getVideoDetails(String id) async {
    try {
      final url = Uri.parse('$_baseUrl/api/android/v2/videoInfo/$id/ar');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return Video.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── المواسم والحلقات ────────────────────────────────────────────────────────

  /// جلب حلقات موسم معين
  Future<List<Video>> getSeasonEpisodes(String seriesId, int season) async {
    try {
      final url = Uri.parse(
          '$_baseUrl/api/android/v2/videoSeason/$seriesId/$season/ar');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Video.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── روابط التشغيل ───────────────────────────────────────────────────────────

  /// جلب روابط الفيديو (transcodes) بالجودات المختلفة
  Future<List<VideoQuality>> getVideoQualities(String id) async {
    try {
      final url =
          Uri.parse('$_baseUrl/api/android/v2/videoTranscode/$id/ar');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => VideoQuality.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── الأقسام ─────────────────────────────────────────────────────────────────

  /// جلب قائمة الأقسام (Categories)
  Future<List<CinemanaCategory>> getCategories({bool isSeries = false}) async {
    try {
      final type = isSeries ? '2' : '1'; // 1=أفلام، 2=مسلسلات
      final url = Uri.parse(
          '$_baseUrl/api/android/v2/Categories/$type/ar');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => CinemanaCategory.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// محتوى قسم معين
  Future<List<Video>> getCategoryContent(
      String categoryId, int page, {bool isSeries = false}) async {
    try {
      final type = isSeries ? '2' : '1';
      final url = Uri.parse(
          '$_baseUrl/api/android/v2/videoByCategories/$type/$categoryId/$page/ar');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Video.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ─── الصفحات الإضافية ────────────────────────────────────────────────────────

  /// أحدث الإضافات
  Future<List<Video>> getLatest({int page = 0, bool isSeries = false}) async {
    try {
      final type = isSeries ? '2' : '1';
      final url = Uri.parse(
          '$_baseUrl/api/android/v2/latestVideos/$type/$page/ar');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Video.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// الأعلى تقييمًا
  Future<List<Video>> getTopRated({int page = 0, bool isSeries = false}) async {
    try {
      final type = isSeries ? '2' : '1';
      final url = Uri.parse(
          '$_baseUrl/api/android/v2/topRatedVideos/$type/$page/ar');
      final response = await http.get(url, headers: _headers);
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body);
      if (data is List) {
        return data.map((e) => Video.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
