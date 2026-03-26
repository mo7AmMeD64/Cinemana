class Video {
  final String id;
  final String title;
  final String titleEn;
  final String poster;
  final String cover;
  final String description;
  final String year;
  final String duration;
  final double rating;
  final List<String> categories;
  final bool isSeries;
  final int seasonsCount;
  final List<int> seasons;

  Video({
    required this.id,
    required this.title,
    this.titleEn = '',
    required this.poster,
    this.cover = '',
    this.description = '',
    this.year = '',
    this.duration = '',
    this.rating = 0.0,
    this.categories = const [],
    this.isSeries = false,
    this.seasonsCount = 0,
    this.seasons = const [],
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    // معالجة التقييم
    double rating = 0.0;
    final ratingRaw = json['star'] ?? json['rating'] ?? json['rate'] ?? 0;
    if (ratingRaw is String) {
      rating = double.tryParse(ratingRaw) ?? 0.0;
    } else if (ratingRaw is num) {
      rating = ratingRaw.toDouble();
    }

    // معالجة الأقسام
    List<String> cats = [];
    final catRaw = json['categories'] ?? json['category'] ?? [];
    if (catRaw is List) {
      cats = catRaw.map((c) {
        if (c is Map) return c['title']?.toString() ?? '';
        return c.toString();
      }).where((s) => s.isNotEmpty).toList();
    } else if (catRaw is String && catRaw.isNotEmpty) {
      cats = [catRaw];
    }

    // مواسم
    List<int> seasonsList = [];
    final rawSeasons = json['seasons'] ?? json['numberOfSeasons'];
    if (rawSeasons is List) {
      seasonsList = rawSeasons.map<int>((s) {
        if (s is int) return s;
        if (s is String) return int.tryParse(s) ?? 0;
        if (s is Map) return int.tryParse(s['id']?.toString() ?? '0') ?? 0;
        return 0;
      }).toList();
    }

    final typeRaw =
        json['type'] ?? json['content_type'] ?? json['is_series'] ?? '';
    final bool series = typeRaw == '2' ||
        typeRaw == 'series' ||
        typeRaw == true ||
        (json['numberOfSeasons'] != null);

    return Video(
      id: json['id']?.toString() ?? json['video_id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? json['ar_title'] ?? '',
      titleEn: json['en_title'] ?? json['title_en'] ?? '',
      poster: _buildImageUrl(json['poster'] ?? json['image'] ?? ''),
      cover: _buildImageUrl(json['cover'] ?? json['background'] ?? ''),
      description: json['description'] ?? json['story'] ?? '',
      year: json['year']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      rating: rating,
      categories: cats,
      isSeries: series,
      seasonsCount: int.tryParse(json['numberOfSeasons']?.toString() ?? '0') ?? 0,
      seasons: seasonsList,
    );
  }

  static String _buildImageUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return 'https://cinemana.shabakaty.com$path';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'titleEn': titleEn,
        'poster': poster,
        'cover': cover,
        'description': description,
        'year': year,
        'duration': duration,
        'rating': rating,
        'categories': categories,
        'isSeries': isSeries,
        'seasonsCount': seasonsCount,
        'seasons': seasons,
      };

  factory Video.fromLocalJson(Map<String, dynamic> json) => Video(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        titleEn: json['titleEn'] ?? '',
        poster: json['poster'] ?? '',
        cover: json['cover'] ?? '',
        description: json['description'] ?? '',
        year: json['year'] ?? '',
        duration: json['duration'] ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
        categories: List<String>.from(json['categories'] ?? []),
        isSeries: json['isSeries'] ?? false,
        seasonsCount: json['seasonsCount'] ?? 0,
        seasons: List<int>.from(json['seasons'] ?? []),
      );
}

class VideoQuality {
  final String quality;
  final String url;
  final String label;

  VideoQuality({
    required this.quality,
    required this.url,
    this.label = '',
  });

  factory VideoQuality.fromJson(Map<String, dynamic> json) {
    return VideoQuality(
      quality: json['quality'] ?? json['resolution'] ?? json['name'] ?? '',
      url: json['url'] ?? json['link'] ?? json['src'] ?? '',
      label: json['label'] ?? json['title'] ?? '',
    );
  }
}
