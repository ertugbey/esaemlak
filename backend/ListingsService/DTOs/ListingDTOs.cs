namespace ListingsService.DTOs;

/// <summary>
/// Request DTO for creating a new listing with Sahibinden-style fields
/// </summary>
public record CreateListingRequest(
    // Temel Bilgiler
    string Baslik,
    string Aciklama,
    
    // Kategori
    string Kategori,        // Konut, IsYeri, Arsa
    string AltKategori,     // Daire, Villa, Rezidans, Mustakil, Dukkan, Ofis
    string IslemTipi,       // satilik, kiralik
    
    // Fiyat
    decimal Fiyat,
    
    // Ölçüler
    int? BrutMetrekare,
    int? NetMetrekare,
    
    // Oda & Bina
    string? OdaSayisi,      // 1+0, 1+1, 2+1, 3+1, 3+2, 4+1, 4+2, 5+1, 5+2, 6+
    string? BinaYasi,       // 0, 1-5, 5-10, 10-15, 15-20, 20+
    int? BanyoSayisi,
    int? BulunduguKat,
    int? KatSayisi,
    
    // Donanım & Özellikler
    string? IsitmaTipi,     // Kombi, Merkezi, Soba, Klima, YerdenIsitma, Dogalgaz
    bool Esyali,
    bool Balkon,
    bool Asansor,
    bool Otopark,
    bool SiteIcerisinde,
    bool Havuz,
    bool Guvenlik,
    
    // ================== İŞ YERİ ALANLARI ==================
    double? GirisYuksekligi,
    bool? ZeminEtudu,
    bool? Devren,
    bool? Kiracili,
    string? YapininDurumu,
    
    // ================== ARSA ALANLARI ==================
    string? AdaParsel,
    double? Gabari,
    double? KaksEmsal,
    bool? KatKarsiligi,
    string? ImarDurumu,
    
    // ================== ÖZELLİK LİSTELERİ ==================
    List<string>? Manzara,
    List<string>? Cephe,
    List<string>? Ulasim,
    List<string>? Muhit,
    List<string>? IcOzellikler,
    List<string>? DisOzellikler,
    List<string>? EngelliyeUygunluk,
    
    // ================== PROMOSYON ==================
    bool AcilSatilik,
    bool FiyatiDustu,
    
    // Satış Detayları
    bool KrediyeUygun,
    bool Takasli,
    string? TapuDurumu,     // KatMulkiyetli, KatIrtifakli, Hisseli, Mustakil
    string? Kimden,         // Sahibinden, EmlakOfisi
    
    // Konum
    string Il,
    string Ilce,
    string? Mahalle,
    double? Latitude,
    double? Longitude
);

/// <summary>
/// Request DTO for updating an existing listing
/// </summary>
public record UpdateListingRequest(
    string? Baslik,
    string? Aciklama,
    decimal? Fiyat,
    int? BrutMetrekare,
    int? NetMetrekare,
    string? OdaSayisi,
    string? BinaYasi,
    int? BanyoSayisi,
    string? IsitmaTipi,
    bool? Esyali,
    bool? Balkon,
    bool? Asansor,
    bool? Otopark,
    bool? SiteIcerisinde,
    bool? Havuz,
    bool? Guvenlik,
    bool? KrediyeUygun,
    bool? Takasli,
    string? TapuDurumu,
    string? Kimden,
    bool? Aktif
);

/// <summary>
/// Response DTO for listing data with all Sahibinden-style fields
/// </summary>
public record ListingDto(
    string Id,
    string EmlakciId,
    
    // Temel
    string Baslik,
    string Aciklama,
    
    // Kategori
    string Kategori,
    string AltKategori,
    string IslemTipi,
    string EmlakTipi, // Legacy compatibility
    
    // Fiyat
    decimal Fiyat,
    
    // Ölçüler
    int? BrutMetrekare,
    int? NetMetrekare,
    double? Metrekare, // Legacy
    
    // Oda & Bina
    string? OdaSayisi,
    string? BinaYasi,
    int? BanyoSayisi,
    int? BulunduguKat,
    int? KatSayisi,
    
    // Özellikler
    string? IsitmaTipi,
    bool Esyali,
    bool Balkon,
    bool Asansor,
    bool Otopark,
    bool SiteIcerisinde,
    bool Havuz,
    bool Guvenlik,
    
    // İş Yeri Alanları
    double? GirisYuksekligi,
    bool? ZeminEtudu,
    bool? Devren,
    bool? Kiracili,
    string? YapininDurumu,
    
    // Arsa Alanları
    string? AdaParsel,
    double? Gabari,
    double? KaksEmsal,
    bool? KatKarsiligi,
    string? ImarDurumu,
    
    // Özellik Listeleri
    List<string> Manzara,
    List<string> Cephe,
    List<string> Ulasim,
    List<string> Muhit,
    List<string> IcOzellikler,
    List<string> DisOzellikler,
    List<string> EngelliyeUygunluk,
    
    // Promosyon
    bool AcilSatilik,
    bool FiyatiDustu,
    
    // Satış Detayları
    bool KrediyeUygun,
    bool Takasli,
    string? TapuDurumu,
    string? Kimden,
    
    // Konum
    string Il,
    string Ilce,
    string? Mahalle,
    double? Latitude,
    double? Longitude,
    
    // Medya & Durum
    List<string> Fotograflar,
    bool Aktif,
    int GoruntulemeSayisi,
    DateTime CreatedAt
);

/// <summary>
/// DTO for price drop listings (Günün Fırsatları)
/// </summary>
public record PriceDropDto(
    string Id,
    string Baslik,
    string Kategori,
    string AltKategori,
    string IslemTipi,
    decimal Fiyat,
    decimal OldPrice,
    decimal DiscountPercent,
    string Il,
    string Ilce,
    int? BrutMetrekare,
    string? OdaSayisi,
    List<string> Fotograflar,
    DateTime PriceUpdatedAt
);

/// <summary>
/// Advanced search filter request with Geo-BoundingBox support
/// </summary>
public record SearchFilterRequest(
    // Text search
    string? Query,
    
    // Kategori
    string? Kategori,
    string? AltKategori,
    string? IslemTipi,
    
    // Konum
    string? Il,
    string? Ilce,
    
    // Fiyat aralığı
    decimal? MinFiyat,
    decimal? MaxFiyat,
    
    // Metrekare aralığı
    int? MinMetrekare,
    int? MaxMetrekare,
    
    // Oda sayısı (çoklu seçim)
    List<string>? OdaSayilari,
    
    // Bina yaşı
    List<string>? BinaYaslari,
    
    // Boolean özellikler
    bool? Esyali,
    bool? Balkon,
    bool? Asansor,
    bool? Otopark,
    bool? SiteIcerisinde,
    bool? Havuz,
    bool? Guvenlik,
    bool? KrediyeUygun,
    
    // Özellik Listeleri (çoklu seçim)
    List<string>? Manzara,
    List<string>? Cephe,
    
    // Promosyon filtreleri
    bool? AcilSatilik,
    bool? FiyatiDustu,
    
    // Satış detayları
    string? Kimden,
    
    // ================== GEO BOUNDING BOX ==================
    // Map-based search: filter listings within visible map area
    double? NorthEastLat,  // Top-right corner latitude
    double? NorthEastLon,  // Top-right corner longitude
    double? SouthWestLat,  // Bottom-left corner latitude
    double? SouthWestLon,  // Bottom-left corner longitude
    
    // Pagination
    int Skip = 0,
    int Limit = 20
);
