// Form doğrulama kuralları; mesajlar API'deki DTO'larla aynı
class Validators {
  Validators._();

  // Basit biçim kontrolü: bir @, öncesinde ve sonrasında metin, sonda .uzantı
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  // Boş veya sadece boşluksa verilen mesajı döner
  static String? required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'E-posta zorunludur.';
    if (!_emailRegex.hasMatch(text)) return 'Geçerli bir e-posta adresi girin.';
    return null;
  }

  // Girişte sadece boş olmaması yeterli; şifre kurallarını kayıtta kontrol ederiz
  static String? loginPassword(String? value) {
    return required(value, 'Şifre zorunludur.');
  }


    // ---------- Kayıt (API'deki RegisterDto + Identity şifre ayarları) ----------

  static final _userNameRegex = RegExp(r'^[a-zA-Z0-9._-]+$');

  static String? fullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Ad soyad zorunludur.';
    if (text.length > 100) return 'Ad soyad en fazla 100 karakter olabilir.';
    return null;
  }

  static String? userName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Kullanıcı adı zorunludur.';
    if (text.length < 3 || text.length > 50) {
      return 'Kullanıcı adı 3 ile 50 karakter arasında olmalıdır.';
    }
    if (!_userNameRegex.hasMatch(text)) {
      return 'Kullanıcı adı yalnızca İngilizce harf, rakam, nokta, alt çizgi ve tire içerebilir.';
    }
    return null;
  }

  // Kayıtta e-posta: biçim + uzunluk
  static String? registerEmail(String? value) {
    final formatError = email(value);
    if (formatError != null) return formatError;
    if (value!.trim().length > 256) {
      return 'E-posta en fazla 256 karakter olabilir.';
    }
    return null;
  }

  // Identity ayarları: en az 6 karakter, 1 rakam, 1 küçük harf.
  // Identity sadece a-z'yi küçük harf sayar (ş, ğ, ı sayılmaz), biz de öyle.
  static String? registerPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Şifre zorunludur.';
    if (text.length < 6) return 'Şifre en az 6 karakter olmalıdır.';
    if (!RegExp(r'[0-9]').hasMatch(text)) {
      return 'Şifre en az bir rakam (0-9) içermelidir.';
    }
    if (!RegExp(r'[a-z]').hasMatch(text)) {
      return 'Şifre en az bir küçük harf (a-z) içermelidir.';
    }
    return null;
  }

  // Şifre tekrarı: girilen şifreyle karşılaştırılır
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Şifre tekrarı zorunludur.';
    if (value != password) return 'Şifreler eşleşmiyor.';
    return null;
  }

}