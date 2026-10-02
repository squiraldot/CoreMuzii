class HomeMood {
  const HomeMood({
    required this.title,
    required this.browseId,
    required this.params,
    this.thumbnailUrl,
  });

  final String title;
  final String browseId;
  final String? params;
  final String? thumbnailUrl;

  static HomeMood? fromRenderer(Map<String, dynamic> renderer) {
    final title = _text(renderer['buttonText'] ?? renderer['title'])?.trim();
    final endpoint = renderer['clickCommand'] is Map
        ? renderer['clickCommand']
        : renderer['navigationEndpoint'];
    final browse = endpoint is Map ? endpoint['browseEndpoint'] : null;
    final browseId = browse is Map ? browse['browseId']?.toString() : null;
    final params = browse is Map ? browse['params']?.toString() : null;
    final thumbnails = renderer['icon'] is Map
        ? renderer['icon']['musicThumbnailRenderer']?['thumbnail']?['thumbnails']
        : renderer['thumbnail'] is Map
            ? renderer['thumbnail']['thumbnails']
            : null;
    final thumbnailUrl = thumbnails is List && thumbnails.isNotEmpty
        ? (thumbnails.last is Map ? thumbnails.last['url']?.toString() : null)
        : null;

    if (title == null || title.isEmpty || browseId == null || browseId.isEmpty) {
      return null;
    }

    return HomeMood(
      title: title,
      browseId: browseId,
      params: params,
      thumbnailUrl: thumbnailUrl,
    );
  }

  static String? _text(dynamic value) {
    if (value is String) return value;
    if (value is Map) {
      final simple = value['simpleText'];
      if (simple is String) return simple;
      final runs = value['runs'];
      if (runs is List) {
        return runs
            .whereType<Map>()
            .map((run) => run['text']?.toString() ?? '')
            .join();
      }
    }
    return null;
  }
}
