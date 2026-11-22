// Proje formu doğrulama kuralları.
// Mesajlar API'deki ProjectInputDto / ProjectCreateDto ile birebir aynı.
class ProjectValidators {
  // Bu sınıftan nesne oluşturulmasın; sadece statik metotlar
  ProjectValidators._();

  // Ad: zorunlu, en fazla 150 karakter
  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Proje adı zorunludur.';
    if (text.length > 150) return 'Proje adı en fazla 150 karakter olabilir.';
    return null;
  }

  // Açıklama isteğe bağlı; sadece uzunluk kontrolü
  static String? description(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 1000) return 'Açıklama en fazla 1000 karakter olabilir.';
    return null;
  }

  // Yeni projede ekip seçimi zorunlu
  static String? team(int? teamId) {
    if (teamId == null) return 'Geçerli bir ekip seçin.';
    return null;
  }

  // İki tarih de seçildiyse bitiş başlangıçtan önce olamaz (aynı gün olabilir)
  static String? dateRange(DateTime? start, DateTime? end) {
    if (start != null && end != null && end.isBefore(start)) {
      return 'Bitiş tarihi başlangıç tarihinden önce olamaz.';
    }
    return null;
  }
}
