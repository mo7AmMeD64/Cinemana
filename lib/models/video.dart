class CinemanaVideo {
  final String id;
  final String title;
  final String titleAr;
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
  // للحلقات
  final String season;
  final String episodeNum;

  CinemanaVideo({
    required this.id,
    required this.title,
    this.titleAr = '',
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
    this.season = '',
    this.episodeNum = '',
  });

  factory CinemanaVideo.fromJson(Map<String, dynamic> j) {
    final id = j['nb']?.toString() ?? j['id']?.toString() ?? '';
    final title = j['en_title']?.toString() ??
        j['enTitle']?.toString() ??
        j['title']?.toString() ?? '';
    final titleAr = j['ar_title']?.toString() ??
        j['arTitle']?.toString() ??
        j['title']?.toString() ?? '';
    final poster = _img(j['imgObjUrl']?.toString() ??
        j['img']?.toString() ??
        j['poster']?.toString() ?? '');
    final cover = _img(j['cover']?.toString() ??
        j['imgBackgroundUrl']?.toString() ?? '');
    final desc = j['en_content']?.toString() ??
        j['enContent']?.toString() ??
        j['description']?.toString() ?? '';

    double rating = 0.0;
    final r = j['stars'] ?? j['rating'] ?? j['star'] ?? 0;
    if (r is String) rating = double.tryParse(r) ?? 0.0;
    else if (r is num) rating = r.toDouble();

    final kindRaw = j['kind'] ?? j['type'] ?? '';
    final bool series = kindRaw == 2 || kindRaw == '2' ||
        kindRaw == 'series' || (j['numberOfSeasons'] != null);

    List<String> cats = [];
    final catRaw = j['categories'] ?? j['category'] ?? [];
    if (catRaw is List) {
      cats = catRaw.map((c) {
        if (c is Map) return c['title']?.toString() ?? '';
        return c.toString();
      }).where((s) => s.isNotEmpty).toList();
    }

    List<int> seasonsList = [];
    final rawS = j['seasons'];
    if (rawS is List) {
      seasonsList = rawS.map<int>((s) {
        if (s is int) return s;
        if (s is String) return int.tryParse(s) ?? 0;
        if (s is Map) return int.tryParse(s['id']?.toString() ?? '0') ?? 0;
        return 0;
      }).toList();
    }

    return CinemanaVideo(
      id: id,
      title: title.isNotEmpty ? title : titleAr,
      titleAr: titleAr,
      poster: poster,
      cover: cover,
      description: desc,
      year: j['year']?.toString() ?? '',
      duration: j['duration']?.toString() ?? '',
      rating: rating,
      categories: cats,
      isSeries: series,
      seasonsCount: int.tryParse(j['numberOfSeasons']?.toString() ?? '0') ?? 0,
      seasons: seasonsList,
      // حقول الحلقة
      season: j['season']?.toString() ?? '',
      episodeNum: j['episodeNummer']?.toString() ??
          j['episodeNumber']?.toString() ?? '',
    );
  }

  static String _img(String p) {
    if (p.isEmpty) return '';
    if (p.startsWith('http')) return p;
    return 'https://cinemana.shabakaty.com$p';
  }

  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'titleAr': titleAr,
        'poster': poster, 'cover': cover, 'description': description,
        'year': year, 'duration': duration, 'rating': rating,
        'categories': categories, 'isSeries': isSeries,
        'seasonsCount': seasonsCount, 'seasons': seasons,
        'season': season, 'episodeNum': episodeNum,
      };

  factory CinemanaVideo.fromLocalJson(Map<String, dynamic> j) => CinemanaVideo(
        id: j['id'] ?? '', title: j['title'] ?? '', titleAr: j['titleAr'] ?? '',
        poster: j['poster'] ?? '', cover: j['cover'] ?? '',
        description: j['description'] ?? '', year: j['year'] ?? '',
        duration: j['duration'] ?? '',
        rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
        categories: List<String>.from(j['categories'] ?? []),
        isSeries: j['isSeries'] ?? false,
        seasonsCount: j['seasonsCount'] ?? 0,
        seasons: List<int>.from(j['seasons'] ?? []),
        season: j['season'] ?? '', episodeNum: j['episodeNum'] ?? '',
      );
}

class VideoQuality {
  final String quality;
  final String url;
  VideoQuality({required this.quality, required this.url});
  factory VideoQuality.fromJson(Map<String, dynamic> j) => VideoQuality(
        quality: j['resolution']?.toString() ?? j['quality']?.toString() ?? '',
        url: j['videoUrl']?.toString() ?? j['url']?.toString() ?? '',
      );
}

class CinemanaSubtitle {
  final String lang;
  final String label;
  final String url;
  CinemanaSubtitle({required this.lang, required this.label, required this.url});
  factory CinemanaSubtitle.fromJson(Map<String, dynamic> j) => CinemanaSubtitle(
        lang: j['lang']?.toString() ?? j['srclang']?.toString() ?? '',
        label: j['name']?.toString() ?? j['label']?.toString() ?? '',
        // الـ API يرجع field اسمه "file"
        url: j['file']?.toString() ?? j['src']?.toString() ?? j['url']?.toString() ?? '',
      );
}
