class CinemanaVideo {
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

  CinemanaVideo({
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

  factory CinemanaVideo.fromJson(Map<String, dynamic> json) {
    double rating = 0.0;
    final r = json['star'] ?? json['rating'] ?? json['rate'] ?? 0;
    if (r is String) rating = double.tryParse(r) ?? 0.0;
    else if (r is num) rating = r.toDouble();

    List<String> cats = [];
    final catRaw = json['categories'] ?? json['category'] ?? [];
    if (catRaw is List) {
      cats = catRaw.map((c) {
        if (c is Map) return c['title']?.toString() ?? '';
        return c.toString();
      }).where((s) => s.isNotEmpty).toList();
    }

    List<int> seasonsList = [];
    final rawSeasons = json['seasons'];
    if (rawSeasons is List) {
      seasonsList = rawSeasons.map<int>((s) {
        if (s is int) return s;
        if (s is String) return int.tryParse(s) ?? 0;
        if (s is Map) return int.tryParse(s['id']?.toString() ?? '0') ?? 0;
        return 0;
      }).toList();
    }

    final typeRaw = json['type'] ?? json['content_type'] ?? '';
    final bool series = typeRaw == '2' || typeRaw == 'series' ||
        json['numberOfSeasons'] != null;

    return CinemanaVideo(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? '',
      titleEn: json['en_title'] ?? json['title_en'] ?? '',
      poster: _img(json['poster'] ?? json['image'] ?? ''),
      cover: _img(json['cover'] ?? json['background'] ?? ''),
      description: json['description'] ?? json['story'] ?? '',
      year: json['year']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      rating: rating,
      categories: cats,
      isSeries: series,
      seasonsCount:
          int.tryParse(json['numberOfSeasons']?.toString() ?? '0') ?? 0,
      seasons: seasonsList,
    );
  }

  static String _img(String p) {
    if (p.isEmpty) return '';
    if (p.startsWith('http')) return p;
    return 'https://cinemana.shabakaty.com$p';
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'titleEn': titleEn,
        'poster': poster, 'cover': cover, 'description': description,
        'year': year, 'duration': duration, 'rating': rating,
        'categories': categories, 'isSeries': isSeries,
        'seasonsCount': seasonsCount, 'seasons': seasons,
      };

  factory CinemanaVideo.fromLocalJson(Map<String, dynamic> j) => Video(
        id: j['id'] ?? '', title: j['title'] ?? '', titleEn: j['titleEn'] ?? '',
        poster: j['poster'] ?? '', cover: j['cover'] ?? '',
        description: j['description'] ?? '', year: j['year'] ?? '',
        duration: j['duration'] ?? '',
        rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
        categories: List<String>.from(j['categories'] ?? []),
        isSeries: j['isSeries'] ?? false,
        seasonsCount: j['seasonsCount'] ?? 0,
        seasons: List<int>.from(j['seasons'] ?? []),
      );
}

class VideoQuality {
  final String quality;
  final String url;

  VideoQuality({required this.quality, required this.url});

  factory VideoQuality.fromJson(Map<String, dynamic> j) => VideoQuality(
        quality: j['quality'] ?? j['resolution'] ?? j['name'] ?? '',
        url: j['url'] ?? j['link'] ?? j['src'] ?? '',
      );
}

class CinemanaSubtitle {
  final String lang;
  final String label;
  final String url;

  CinemanaSubtitle({required this.lang, required this.label, required this.url});

  factory CinemanaSubtitle.fromJson(Map<String, dynamic> j) => CinemanaSubtitle(
        lang: j['srclang'] ?? j['lang'] ?? '',
        label: j['label'] ?? j['title'] ?? j['srclang'] ?? '',
        url: j['src'] ?? j['url'] ?? '',
      );
}
