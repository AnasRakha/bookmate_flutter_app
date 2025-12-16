String? normalizeImgbbUrl(String? url) {
  if (url == null || url.isEmpty) return null;

  // Jika sudah benar
  if (url.startsWith('https://i.ibb.co.com/')) {
    return url;
  }

  // Normalisasi i.ibb.co -> i.ibb.co.com
  if (url.startsWith('https://i.ibb.co/')) {
    return url.replaceFirst('https://i.ibb.co/', 'https://i.ibb.co.com/');
  }

  // URL lain (non imgbb) biarkan
  return url;
}
