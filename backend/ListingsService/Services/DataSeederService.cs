using ListingsService.Models;
using ListingsService.Repositories;
using ListingsService.Elasticsearch;

namespace ListingsService.Services;

/// <summary>
/// Service to seed realistic test data for development and demo purposes
/// </summary>
public class DataSeederService
{
    private readonly IListingRepository _repository;
    private readonly ISearchService _searchService;
    private readonly ILogger<DataSeederService> _logger;
    
    private static readonly Random _random = new();
    
    // Gerçekçi Unsplash emlak fotoğrafları
    private static readonly string[] _konutFotograflari = new[]
    {
        "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800",
        "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800",
        "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800",
        "https://images.unsplash.com/photo-1600566753190-17f0baa2a6c3?w=800",
        "https://images.unsplash.com/photo-1600573472592-401b489a3cdc?w=800",
        "https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800",
        "https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800",
        "https://images.unsplash.com/photo-1564013799919-ab600027ffc6?w=800",
        "https://images.unsplash.com/photo-1605276374104-dee2a0ed3cd6?w=800",
        "https://images.unsplash.com/photo-1583608205776-bfd35f0d9f83?w=800",
        "https://images.unsplash.com/photo-1580587771525-78b9dba3b914?w=800",
        "https://images.unsplash.com/photo-1628012209120-d841db53f4e5?w=800",
        "https://images.unsplash.com/photo-1523217582562-09d0def993a6?w=800",
        "https://images.unsplash.com/photo-1600047509807-ba8f99d2cdde?w=800",
        "https://images.unsplash.com/photo-1560184897-ae75f418493e?w=800"
    };
    
    private static readonly string[] _interiorFotograflari = new[]
    {
        "https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800",
        "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800",
        "https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=800",
        "https://images.unsplash.com/photo-1616137466211-f939a420be84?w=800",
        "https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=800"
    };

    public DataSeederService(
        IListingRepository repository,
        ISearchService searchService,
        ILogger<DataSeederService> logger)
    {
        _repository = repository;
        _searchService = searchService;
        _logger = logger;
    }

    /// <summary>
    /// Seed 15 realistic listings if database is empty
    /// </summary>
    public async Task SeedIfEmptyAsync()
    {
        var existingCount = await _repository.GetCountAsync();
        if (existingCount > 0)
        {
            _logger.LogInformation("Database already has {Count} listings, skipping seed", existingCount);
            return;
        }

        _logger.LogInformation("🌱 Starting data seeding with 15 realistic listings...");
        
        var listings = GenerateSeedListings();
        
        foreach (var listing in listings)
        {
            var created = await _repository.CreateAsync(listing);
            await _searchService.IndexListingAsync(created);
            _logger.LogInformation("Created seed listing: {Title}", listing.Baslik);
        }
        
        _logger.LogInformation("✅ Seed completed! {Count} listings created", listings.Count);
    }

    private List<Listing> GenerateSeedListings()
    {
        var listings = new List<Listing>
        {
            // ===== GÜNÜN FIRSATLARI (Premium, yüksek görüntülenme) =====
            CreateListing(
                baslik: "Boğaz Manzaralı Lüks Rezidans Dairesi",
                aciklama: "Benzersiz Boğaz manzarasına sahip, 5 yıldızlı otel konforunda rezidans. 24 saat güvenlik, kapalı otopark, fitness center ve spa hizmeti. Türkiye'nin en prestijli adresinde yaşam fırsatı.",
                kategori: "Konut", altKategori: "Rezidans", islemTipi: "satilik",
                fiyat: 28500000, brutM2: 280, netM2: 240, odaSayisi: "4+1",
                binaYasi: "0", kat: 35, katSayisi: 45, il: "İstanbul", ilce: "Beşiktaş",
                mahalle: "Ortaköy", lat: 41.0477, lon: 29.0276,
                ozellikler: new[] { "Havuz", "Güvenlik", "Otopark", "Asansör", "Balkon" },
                manzara: new[] { "Boğaz", "Deniz" }, goruntulenme: 2456, acilSatilik: false,
                fiyatiDustu: false, fotoIndex: 0
            ),
            
            CreateListing(
                baslik: "Kadıköy Merkezde Yatırımlık 2+1 Daire",
                aciklama: "Metro ve tramvay durağına yürüme mesafesinde. Yapı kredi uygun, tapu hazır. Kiracılı teslim edilebilir, aylık 25.000 TL kira getirisi mevcut.",
                kategori: "Konut", altKategori: "Daire", islemTipi: "satilik",
                fiyat: 4250000, brutM2: 95, netM2: 85, odaSayisi: "2+1",
                binaYasi: "5-10", kat: 4, katSayisi: 8, il: "İstanbul", ilce: "Kadıköy",
                mahalle: "Caferağa", lat: 40.9869, lon: 29.0241,
                ozellikler: new[] { "Asansör", "Otopark" },
                manzara: new[] { "Şehir" }, goruntulenme: 1834, acilSatilik: false,
                fiyatiDustu: true, fotoIndex: 1
            ),
            
            CreateListing(
                baslik: "Ataşehir'de Tam Merkezde Sıfır 3+1",
                aciklama: "Finansbank kulesinin hemen yanında, metro çıkışında. Akıllı ev sistemleri, yerden ısıtma, VRF klima. A+ enerji sınıfı, cam gibi temiz.",
                kategori: "Konut", altKategori: "Daire", islemTipi: "satilik",
                fiyat: 7800000, brutM2: 145, netM2: 130, odaSayisi: "3+1",
                binaYasi: "0", kat: 12, katSayisi: 25, il: "İstanbul", ilce: "Ataşehir",
                mahalle: "Barbaros", lat: 40.9924, lon: 29.1247,
                ozellikler: new[] { "Asansör", "Güvenlik", "Otopark", "Site İçi" },
                manzara: new[] { "Şehir" }, goruntulenme: 1245, acilSatilik: false,
                fiyatiDustu: false, fotoIndex: 2
            ),
            
            // ===== ACİL SATILIK (Kırmızı etiket) =====
            CreateListing(
                baslik: "ACİL! Bakırköy'de Denize Sıfır Daire",
                aciklama: "Yurtdışına taşınmadan dolayı acil satılık! Sahil yürüyüş yoluna cephe, güneş batımı manzarası. Pazarlık payı mevcuttur.",
                kategori: "Konut", altKategori: "Daire", islemTipi: "satilik",
                fiyat: 5950000, brutM2: 120, netM2: 105, odaSayisi: "3+1",
                binaYasi: "10-15", kat: 6, katSayisi: 8, il: "İstanbul", ilce: "Bakırköy",
                mahalle: "Zeytinlik", lat: 40.9809, lon: 28.8778,
                ozellikler: new[] { "Balkon", "Asansör" },
                manzara: new[] { "Deniz" }, goruntulenme: 892, acilSatilik: true,
                fiyatiDustu: false, fotoIndex: 3
            ),
            
            CreateListing(
                baslik: "ACİL! Maltepe Sahilde 2+1 Kiralık",
                aciklama: "İş değişikliği nedeniyle acil! Eşyalı, anında taşınmaya hazır. Deniz manzaralı, site içi, havuzlu.",
                kategori: "Konut", altKategori: "Daire", islemTipi: "kiralik",
                fiyat: 35000, brutM2: 90, netM2: 80, odaSayisi: "2+1",
                binaYasi: "5-10", kat: 3, katSayisi: 10, il: "İstanbul", ilce: "Maltepe",
                mahalle: "Altıntepe", lat: 40.9333, lon: 29.1445,
                ozellikler: new[] { "Eşyalı", "Havuz", "Güvenlik", "Site İçi" },
                manzara: new[] { "Deniz" }, goruntulenme: 654, acilSatilik: true,
                fiyatiDustu: false, fotoIndex: 4
            ),
            
            CreateListing(
                baslik: "ACİL! Beykoz'da Müstakil Bahçeli Ev",
                aciklama: "3 katlı müstakil, 500 m² bahçe. Garaj, kış bahçesi, barbekü alanı. Sağlık nedeniyle acil satış.",
                kategori: "Konut", altKategori: "Mustakil", islemTipi: "satilik",
                fiyat: 18500000, brutM2: 320, netM2: 280, odaSayisi: "5+2",
                binaYasi: "15-20", kat: 1, katSayisi: 3, il: "İstanbul", ilce: "Beykoz",
                mahalle: "Çubuklu", lat: 41.1096, lon: 29.0764,
                ozellikler: new[] { "Bahçe", "Garaj", "Şömine" },
                manzara: new[] { "Yeşil", "Boğaz" }, goruntulenme: 1123, acilSatilik: true,
                fiyatiDustu: false, fotoIndex: 5
            ),
            
            // ===== FİYATI DÜŞENLER =====
            CreateListing(
                baslik: "Fiyat Düştü! Şişli Merkez 1+1 Stüdyo",
                aciklama: "Yatırımcı fırsatı! Eskiden 2.8M idi, şimdi 2.3M! Yıllık %12 kira getirisi garantili. Kurumsal kiracı mevcut.",
                kategori: "Konut", altKategori: "Daire", islemTipi: "satilik",
                fiyat: 2300000, brutM2: 55, netM2: 48, odaSayisi: "1+1",
                binaYasi: "5-10", kat: 8, katSayisi: 15, il: "İstanbul", ilce: "Şişli",
                mahalle: "Mecidiyeköy", lat: 41.0667, lon: 28.9953,
                ozellikler: new[] { "Asansör", "Güvenlik" },
                manzara: new[] { "Şehir" }, goruntulenme: 2100, acilSatilik: false,
                fiyatiDustu: true, fotoIndex: 6
            ),
            
            CreateListing(
                baslik: "İndirimli! Kartal'da Site İçi 3+1",
                aciklama: "Fiyat 6.5M'den 5.9M'ye düştü! Kapalı yüzme havuzu, fitness, çocuk oyun alanı. Doğalgaz kombili.",
                kategori: "Konut", altKategori: "Daire", islemTipi: "satilik",
                fiyat: 5900000, brutM2: 135, netM2: 120, odaSayisi: "3+1",
                binaYasi: "5-10", kat: 7, katSayisi: 18, il: "İstanbul", ilce: "Kartal",
                mahalle: "Uğur Mumcu", lat: 40.8897, lon: 29.1887,
                ozellikler: new[] { "Havuz", "Site İçi", "Güvenlik", "Otopark" },
                manzara: new[] { "Deniz", "Adalar" }, goruntulenme: 1567, acilSatilik: false,
                fiyatiDustu: true, fotoIndex: 7
            ),
            
            // ===== SON EKLENENLER =====
            CreateListing(
                baslik: "Yeni! Pendik Marina'da Deniz Manzaralı",
                aciklama: "Dün yayına alındı! Marinaya yürüme mesafesinde, tekne sahibi için ideal. Geniş teras, jakuzi.",
                kategori: "Konut", altKategori: "Rezidans", islemTipi: "satilik",
                fiyat: 12500000, brutM2: 180, netM2: 160, odaSayisi: "3+1",
                binaYasi: "0", kat: 15, katSayisi: 25, il: "İstanbul", ilce: "Pendik",
                mahalle: "Kurtköy", lat: 40.8989, lon: 29.2934,
                ozellikler: new[] { "Teras", "Jakuzi", "Güvenlik", "Otopark" },
                manzara: new[] { "Deniz" }, goruntulenme: 234, acilSatilik: false,
                fiyatiDustu: false, fotoIndex: 8, hoursAgo: 6
            ),
            
            CreateListing(
                baslik: "Yeni! Üsküdar Çengelköy'de Tarihi Köşk",
                aciklama: "Restore edilmiş Osmanlı köşkü, 1200 m² arsa üzerinde. Boğaz seyir terası, antika şömine.",
                kategori: "Konut", altKategori: "Villa", islemTipi: "satilik",
                fiyat: 85000000, brutM2: 450, netM2: 380, odaSayisi: "6+2",
                binaYasi: "20+", kat: 1, katSayisi: 3, il: "İstanbul", ilce: "Üsküdar",
                mahalle: "Çengelköy", lat: 41.0564, lon: 29.0527,
                ozellikler: new[] { "Bahçe", "Şömine", "Tarihi" },
                manzara: new[] { "Boğaz" }, goruntulenme: 567, acilSatilik: false,
                fiyatiDustu: false, fotoIndex: 9, hoursAgo: 12
            ),
            
            CreateListing(
                baslik: "Yeni! Bebek'te Butik Daire Satılık",
                aciklama: "Az daire konseptinde, sadece 8 daireli binada. Concierge hizmeti, vale parking.",
                kategori: "Konut", altKategori: "Daire", islemTipi: "satilik",
                fiyat: 35000000, brutM2: 220, netM2: 195, odaSayisi: "4+1",
                binaYasi: "0", kat: 5, katSayisi: 6, il: "İstanbul", ilce: "Beşiktaş",
                mahalle: "Bebek", lat: 41.0763, lon: 29.0449,
                ozellikler: new[] { "Concierge", "Vale", "Güvenlik" },
                manzara: new[] { "Boğaz" }, goruntulenme: 789, acilSatilik: false,
                fiyatiDustu: false, fotoIndex: 10, hoursAgo: 24
            ),
            
            // ===== İŞ YERİ & ARSA =====
            CreateListing(
                baslik: "Levent'te Kiralık Ofis Katı",
                aciklama: "A+ plaza, 1000 m² açık ofis alanı. Fiber altyapı, jeneratör, UPS. Metro bağlantılı.",
                kategori: "IsYeri", altKategori: "Ofis", islemTipi: "kiralik",
                fiyat: 450000, brutM2: 1000, netM2: 950, odaSayisi: null,
                binaYasi: "5-10", kat: 18, katSayisi: 35, il: "İstanbul", ilce: "Beşiktaş",
                mahalle: "Levent", lat: 41.0823, lon: 29.0108,
                ozellikler: new[] { "Otopark", "Güvenlik", "Asansör" },
                manzara: new[] { "Şehir" }, goruntulenme: 432, acilSatilik: false,
                fiyatiDustu: false, fotoIndex: 11
            ),
            
            CreateListing(
                baslik: "Tuzla'da Konut İmarlı Arsa",
                aciklama: "E5'e cephe, 2500 m² konut imarlı. KAKS: 2.07, Gabari: 15 kat. Kat karşılığı verilir.",
                kategori: "Arsa", altKategori: "Konut", islemTipi: "satilik",
                fiyat: 45000000, brutM2: 2500, netM2: null, odaSayisi: null,
                binaYasi: null, kat: null, katSayisi: null, il: "İstanbul", ilce: "Tuzla",
                mahalle: "Aydınlı", lat: 40.8215, lon: 29.3012,
                ozellikler: new[] { "Kat Karşılığı" },
                manzara: new[] { "Deniz" }, goruntulenme: 876, acilSatilik: false,
                fiyatiDustu: false, fotoIndex: 12
            ),
            
            // ===== KİRALIK =====
            CreateListing(
                baslik: "Caddebostan'da Eşyalı 3+1 Kiralık",
                aciklama: "Denize 100 metre, full eşyalı lüks daire. Miele beyaz eşya, Natuzzi mobilya. Expat için ideal.",
                kategori: "Konut", altKategori: "Daire", islemTipi: "kiralik",
                fiyat: 75000, brutM2: 140, netM2: 125, odaSayisi: "3+1",
                binaYasi: "5-10", kat: 5, katSayisi: 8, il: "İstanbul", ilce: "Kadıköy",
                mahalle: "Caddebostan", lat: 40.9615, lon: 29.0631,
                ozellikler: new[] { "Eşyalı", "Balkon", "Asansör", "Otopark" },
                manzara: new[] { "Deniz" }, goruntulenme: 1234, acilSatilik: false,
                fiyatiDustu: false, fotoIndex: 13
            ),
            
            CreateListing(
                baslik: "Sarıyer Maslak 1453'te Lüks Kiralık",
                aciklama: "Alışveriş merkezi içinde, tüm ihtiyaçlar kapıda. 5 yıldızlı otel konforu, spa, havuz.",
                kategori: "Konut", altKategori: "Rezidans", islemTipi: "kiralik",
                fiyat: 120000, brutM2: 200, netM2: 175, odaSayisi: "3+1",
                binaYasi: "5-10", kat: 28, katSayisi: 45, il: "İstanbul", ilce: "Sarıyer",
                mahalle: "Maslak", lat: 41.1094, lon: 29.0172,
                ozellikler: new[] { "Havuz", "Spa", "Güvenlik", "AVM İçi" },
                manzara: new[] { "Şehir" }, goruntulenme: 1567, acilSatilik: false,
                fiyatiDustu: false, fotoIndex: 14
            )
        };
        
        return listings;
    }

    private Listing CreateListing(
        string baslik, string aciklama, string kategori, string altKategori, string islemTipi,
        decimal fiyat, int brutM2, int? netM2, string? odaSayisi,
        string? binaYasi, int? kat, int? katSayisi, string il, string ilce,
        string mahalle, double lat, double lon,
        string[] ozellikler, string[] manzara, int goruntulenme,
        bool acilSatilik, bool fiyatiDustu, int fotoIndex, int hoursAgo = 0)
    {
        // Rastgele 3-5 fotoğraf seç
        var fotograflar = new List<string> { _konutFotograflari[fotoIndex % _konutFotograflari.Length] };
        fotograflar.AddRange(_interiorFotograflari.OrderBy(_ => _random.Next()).Take(3));
        
        return new Listing
        {
            EmlakciId = "system_seed",
            Baslik = baslik,
            Aciklama = aciklama,
            Kategori = kategori,
            AltKategori = altKategori,
            IslemTipi = islemTipi,
            EmlakTipi = kategori,
            Fiyat = fiyat,
            BrutMetrekare = brutM2,
            NetMetrekare = netM2,
            OdaSayisi = odaSayisi,
            BinaYasi = binaYasi,
            BulunduguKat = kat,
            KatSayisi = katSayisi,
            IsitmaTipi = "Kombi",
            Il = il,
            Ilce = ilce,
            Mahalle = mahalle,
            Konum = new GeoLocation
            {
                Type = "Point",
                Coordinates = new[] { lon, lat }
            },
            Fotograflar = fotograflar,
            Aktif = true,
            Onaylandi = true,
            GoruntulemeSayisi = goruntulenme,
            AcilSatilik = acilSatilik,
            FiyatiDustu = fiyatiDustu,
            KrediyeUygun = fiyat > 1000000 && islemTipi == "satilik",
            Balkon = ozellikler.Contains("Balkon"),
            Asansor = ozellikler.Contains("Asansör"),
            Otopark = ozellikler.Contains("Otopark"),
            Havuz = ozellikler.Contains("Havuz"),
            SiteIcerisinde = ozellikler.Contains("Site İçi"),
            Guvenlik = ozellikler.Contains("Güvenlik"),
            Esyali = ozellikler.Contains("Eşyalı"),
            Manzara = manzara.ToList(),
            CreatedAt = DateTime.UtcNow.AddHours(-hoursAgo),
            UpdatedAt = DateTime.UtcNow
        };
    }
}
