# TaskFlow Mobil — Ekip, Proje ve Görev Yönetimi Uygulaması

BLM4587 IOS İle Mobil Uygulama Geliştirme I (Flutter) dersi (2026–2027 Güz) dönem projesi.

TaskFlow Mobil, BLM4581 Ağ Tabanlı Teknolojiler dersinde geliştirdiğimiz TaskFlow proje yönetim platformunun mobil uygulamasıdır. Küçük ekiplerin bir ekip kurup projelerini ve görevlerini telefondan, Kanban mantığıyla (Yapılacak / Devam Ediyor / Tamamlandı) takip edebilmesini sağlar. Proje iki parçadan oluşur: JWT ile korunan bir ASP.NET Core Web API (`/api`) ve bu API'yi kullanan Flutter mobil uygulaması (`/mobile`). Mobil uygulama veritabanına doğrudan bağlanmaz; tüm verilere kendi API'miz üzerinden erişir.

## Grup

| Ad Soyad | Öğrenci No | GitHub | Liderlik |
|---|---|---|---|
| Zeynep AKÇAY | 23291339 | [@zeynepakcayy](https://github.com/zeynepakcayy) | 1–4. haftalar |
| Onur Bahattin ALKAN | 22290551 | [@onurbahattinalkan](https://github.com/onurbahattinalkan) | 5–9. haftalar |


Drive : [Drive Linki](https://drive.google.com/drive/folders/1J-nBVuNJjbbXoWNjXyxTSjJVFgmwA_sS)

## Özellikler

Roller: **Yönetici (Admin)** ve **Kullanıcı (User)** (ASP.NET Identity + JWT). Ekip içinde: **Lider** ve **Üye**.

- [ ] Kayıt olma, e-posta + şifre ile giriş (JWT), oturumun cihazda güvenli saklanması, çıkış
- [ ] Ekip oluşturma, ekibe üye ekleme, liderliği devretme
- [ ] Proje ekleme, listeleme, düzenleme, silme (tam CRUD)
- [ ] Görev oluşturma, kişiye atama, son tarih belirleme, silme (tam CRUD)
- [ ] Kanban panosu ve görev durumunu değiştirme
- [ ] Görevlere yorum ekleme ve yorumları görüntüleme
- [ ] Profil ekranı (bana atanan görevler)
- [ ] Görevlerde arama ve filtreleme
- [ ] Yönetim paneli – yalnızca Admin (kullanıcılar, rol atama, hesap kilitleme, ekip ve proje yönetimi)
- [ ] Mobilde ve API'de form doğrulama
- [ ] Telefon ve tablet ekranlarına uyumlu arayüz

> Tamamlanan özellikler geliştikçe işaretlenecektir.

## Teknolojiler

**Web API (`/api`)**
- ASP.NET Core **Web API** (.NET 10)
- Entity Framework Core + Npgsql, code-first migration
- **PostgreSQL**
- ASP.NET Core Identity + **JWT Bearer**
- Swagger (OpenAPI)
- DTO + DataAnnotations ile veri doğrulama

**Mobil (`/mobile`)**
- **Flutter** (Dart), hedef platform: Android
- `dio` (HTTP + JWT interceptor), `provider` (durum yönetimi), `go_router` (gezinme)
- `flutter_secure_storage` (token saklama), `jwt_decoder` (rol okuma), `intl` (tarih biçimleri)

## Veritabanı Tabloları

| Tablo | İçerik | İlişkiler |
|---|---|---|
| Users | Identity kullanıcıları (roller Identity rol tablolarında) | TeamMembers, Tasks, Comments |
| Teams | Ekip adı, açıklama, oluşturulma tarihi | TeamMembers (1-N), Projects (1-N) |
| TeamMembers | Kullanıcı–ekip bağlantısı, ekip içi rol (Lider/Üye) | Users, Teams |
| Projects | Proje adı, açıklama, tarihler; bir ekibe aittir | Teams, Tasks (1-N) |
| Tasks | Başlık, açıklama, durum, atanan kişi, son tarih | Projects, Users, Comments (1-N) |
| Comments | Görev yorumları: metin, yazan kullanıcı, tarih | Tasks, Users |

## Kurulum ve Çalıştırma

### Gereksinimler

- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- [PostgreSQL](https://www.postgresql.org/download/)
- `dotnet-ef` aracı:

```bash
dotnet tool install --global dotnet-ef
```

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (TaskFlow Mobil: sürüm eklenecek)
- Android Studio ve Android emülatör

### 1. Depoyu klonlayın

```bash
git clone https://github.com/onurbahattinalkan/TaskFlowFlutter.git
cd TaskFlowFlutter
```

### 2. Veritabanını hazırlayın

PostgreSQL'de boş bir veritabanı oluşturun:

```sql
CREATE DATABASE taskflow_mobile;
```

### 3. Bağlantı dizesini user-secrets ile tanımlayın

Gizli bilgiler (veritabanı şifresi, bağlantı dizesi, JWT anahtarı) depoya konmaz; `user-secrets` kullanılır.

```bash
cd api
dotnet user-secrets init
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Host=localhost;Port=5432;Database=taskflow_mobile;Username=KULLANICI;Password=SIFRE"
```

> `KULLANICI` ve `SIFRE` değerlerini kendi PostgreSQL bilgilerinizle değiştirin. JWT ve yönetici hesabı için gereken diğer anahtarlar eklenecektir.

### 4. Migration'ları uygulayın

```bash
dotnet ef database update
```

Bu komut tüm tabloları oluşturur. (Yeni migration eklemek için: `dotnet ef migrations add MigrationAdi`)

### 5. API'yi çalıştırın

```bash
dotnet run
```

API varsayılan olarak `http://localhost:PORT` adresinde açılır. Swagger arayüzü: `http://localhost:PORT/swagger`

### 6. Mobil uygulamayı çalıştırın

Yeni bir terminalde:

```bash
cd mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:PORT
```

> Android emülatörde bilgisayarın `localhost` adresi `10.0.2.2` olarak görünür. `PORT` yerine API'nin çalıştığı portu yazın.

### Varsayılan hesaplar

TODO: Yönetici hesabı ve örnek veri (seed) eklendikten sonra giriş bilgileri burada yazılacak.

## Web API ve Swagger

Proje (Project) ve Görev (TaskItem) varlıkları için tam CRUD uç noktaları bulunur. Tüm uç noktalar Swagger arayüzünden test edilebilir.

| Metot | Uç nokta | Açıklama |
|---|---|---|
| POST | `/api/auth/register` | Kayıt olur |
| POST | `/api/auth/login` | Giriş yapar, JWT döner |
| GET | `/api/projects` | Projeleri listeler |
| GET | `/api/projects/{id}` | Tek projeyi getirir |
| POST | `/api/projects` | Yeni proje ekler |
| PUT | `/api/projects/{id}` | Projeyi günceller |
| DELETE | `/api/projects/{id}` | Projeyi siler |
| GET | `/api/projects/{projectId}/tasks` | Projenin görevlerini listeler |
| POST | `/api/projects/{projectId}/tasks` | Projeye görev ekler |
| GET | `/api/tasks/{id}` | Tek görevi getirir |
| PUT | `/api/tasks/{id}` | Görevi günceller |
| DELETE | `/api/tasks/{id}` | Görevi siler |

Ekip, yorum ve yönetici uç noktaları geliştikçe eklenecektir.

## Klasör Yapısı

```
TaskFlowFlutter/
├── api/            # ASP.NET Core Web API
│   ├── Controllers/    # API controller'ları
│   ├── Models/         # Entity sınıfları
│   ├── Dtos/           # İstek / yanıt modelleri
│   ├── Data/           # DbContext ve migration'lar
│   └── Services/       # Yetki ve token servisleri
└── mobile/         # Flutter uygulaması
    └── lib/
        ├── models/     # Veri modelleri
        ├── services/   # API servisleri
        ├── screens/    # Ekranlar
        └── widgets/    # Ortak bileşenler
```

> Proje oluşturuldukça güncellenecek.

## Geliştirme Planı

9 haftalık plan (21 Ekim – 23 Aralık 2026):

| Hafta | Lider | Konu |
|---|---|---|
| 1 | Zeynep | Depo yapısı, API iskeleti (modeller, DbContext, migration, Swagger), Flutter iskeleti, emülatör |
| 2 | Zeynep | Identity + JWT, roller ve admin seed, proje CRUD API, mobil modeller ve API servisi |
| 3 | Zeynep | Mobil giriş/kayıt, token saklama, oturum yönlendirmesi; görev CRUD ve yorum API'leri |
| 4 | Zeynep | Ekip API'si ve ekranları, mobil proje listesi ve formları; 1. gösterim (18 Kasım) |
| 5 | Onur | Proje detayı ve Kanban panosu, görev formları, API'de ekip yetki kontrolleri |
| 6 | Onur | Görev detayı ve yorumlar, profil ekranı, Admin API |
| 7 | Onur | Mobil yönetim ekranları, rol bazlı menü, arama ve filtreleme |
| 8 | Onur | Duyarlı arayüz, hata yanıtlarının standartlaştırılması, örnek veri, hata düzeltmeleri |
| 9 | Onur | README son hali, gizli bilgi kontrolü, son testler; 2. gösterim (23 Aralık) |

## Lisans

Bu proje, ders kapsamında geliştirilmiş bir dönem projesidir.