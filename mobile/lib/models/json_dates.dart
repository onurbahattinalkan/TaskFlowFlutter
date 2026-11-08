// API ile tarih alışverişi için yardımcılar.
// Sadece-tarih alanları (DateOnly) "2026-11-10" biçiminde gelir ve gider.

// JSON'daki tarih metnini DateTime'a çevirir; boşsa null döner
DateTime? parseDate(dynamic value) {
  if (value == null || value is! String || value.isEmpty) return null;
  return DateTime.parse(value);
}

// DateTime'ı API'nin beklediği "yyyy-MM-dd" biçimine çevirir; null ise null
String? formatDateOnly(DateTime? date) {
  if (date == null) return null;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}