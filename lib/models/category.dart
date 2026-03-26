class CinemanaCategory {
  final String id;
  final String title;
  final String image;

  CinemanaCategory({
    required this.id,
    required this.title,
    this.image = '',
  });

  factory CinemanaCategory.fromJson(Map<String, dynamic> json) {
    String img = json['image'] ?? json['poster'] ?? json['icon'] ?? '';
    if (img.isNotEmpty && !img.startsWith('http')) {
      img = 'https://cinemana.shabakaty.com$img';
    }
    return CinemanaCategory(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? json['ar_title'] ?? '',
      image: img,
    );
  }
}
