class CinemanaCategory {
  final String id;
  final String title;
  final String image;

  CinemanaCategory({required this.id, required this.title, this.image = ''});

  factory CinemanaCategory.fromJson(Map<String, dynamic> j) {
    String img = j['image'] ?? j['poster'] ?? '';
    if (img.isNotEmpty && !img.startsWith('http')) {
      img = 'https://cinemana.shabakaty.com$img';
    }
    return CinemanaCategory(
      id: j['id']?.toString() ?? '',
      title: j['title'] ?? j['name'] ?? '',
      image: img,
    );
  }
}
