using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace ListingsService.Models;

[BsonIgnoreExtraElements]
public class Listing
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    public string EmlakciId { get; set; } = string.Empty;

    // ================== TEMEL BİLGİLER ==================
    public string Baslik { get; set; } = string.Empty;

    public string Aciklama { get; set; } = string.Empty;

    // ================== KATEGORİ YAPISI ==================
    public string Kategori { get; set; } = string.Empty; // Konut, IsYeri, Arsa

    public string AltKategori { get; set; } = string.Empty; // Daire, Villa, Rezidans, Mustakil, Dukkan, Ofis

    public string IslemTipi { get; set; } = string.Empty; // satilik, kiralik

    // Backward compatibility - maps to kategori
    public string EmlakTipi { get; set; } = string.Empty;

    // ================== FİYAT ==================
    public decimal Fiyat { get; set; }

    // ================== ÖLÇÜLER ==================
    public int? BrutMetrekare { get; set; }

    public int? NetMetrekare { get; set; }

    // Legacy field - for backward compatibility
    public double? Metrekare { get; set; }

    // ================== ODA & BİNA BİLGİLERİ ==================
    public string? OdaSayisi { get; set; } // 1+0, 1+1, 2+1, 3+1, 3+2, 4+1, 4+2, 5+1, 5+2, 6+

    public string? BinaYasi { get; set; } // 0, 1-5, 5-10, 10-15, 15-20, 20+

    public int? BanyoSayisi { get; set; }

    public int? BulunduguKat { get; set; }

    public int? KatSayisi { get; set; }

    // ================== DONANIM & ÖZELLİKLER ==================
    public string? IsitmaTipi { get; set; } // Kombi, Merkezi, Soba, Klima, YerdenIsitma, Dogalgaz

    public bool Esyali { get; set; } = false;

    public bool Balkon { get; set; } = false;

    public bool Asansor { get; set; } = false;

    public bool Otopark { get; set; } = false;

    public bool SiteIcerisinde { get; set; } = false;

    public bool Havuz { get; set; } = false;

    public bool Guvenlik { get; set; } = false;

    // ================== YENİ ALANLAR ==================
    public string? MutfakTipi { get; set; }

    public string? OtoparkTipi { get; set; }

    public string? KullanimDurumu { get; set; }

    public string? KonutTipi { get; set; }

    public string? BulunduguKatStr { get; set; }

    public string? VideoUrl { get; set; }

    // ================== İŞ YERİ ÖZEL ALANLARI ==================
    public double? GirisYuksekligi { get; set; }  // Metre cinsinden tavan yüksekliği

    public bool? ZeminEtudu { get; set; }

    public bool? Devren { get; set; }

    public bool? Kiracili { get; set; }

    public string? YapininDurumu { get; set; }  // IkinciEl, Sifir, YapimAsamasinda

    // ================== ARSA ÖZEL ALANLARI ==================
    public string? AdaParsel { get; set; }

    public double? Gabari { get; set; }

    public double? KaksEmsal { get; set; }  // İmar KAKS/Emsal oranı

    public bool? KatKarsiligi { get; set; }

    public string? ImarDurumu { get; set; }

    // ================== ÖZELLİK LİSTELERİ ==================
    public List<string> Manzara { get; set; } = new();

    public List<string> Cephe { get; set; } = new();

    public List<string> Ulasim { get; set; } = new();

    public List<string> Muhit { get; set; } = new();

    public List<string> IcOzellikler { get; set; } = new();

    public List<string> DisOzellikler { get; set; } = new();

    public List<string> EngelliyeUygunluk { get; set; } = new();

    // ================== PROMOSYON ==================
    public bool AcilSatilik { get; set; } = false;

    public bool FiyatiDustu { get; set; } = false;

    // ================== SATIŞ DETAYLARI ==================
    public bool KrediyeUygun { get; set; } = false;

    public bool Takasli { get; set; } = false;

    public string? TapuDurumu { get; set; } // KatMulkiyetli, KatIrtifakli, Hisseli, Mustakil

    public string? Kimden { get; set; } // Sahibinden, EmlakOfisi

    // ================== KONUM BİLGİLERİ ==================
    public string Il { get; set; } = string.Empty;

    public string Ilce { get; set; } = string.Empty;

    public string? Mahalle { get; set; }

    public string? Adres { get; set; }

    public GeoLocation? Konum { get; set; }

    // ================== MEDYA ==================
    public List<string> Fotograflar { get; set; } = new();

    /// <summary>BlurHash strings for each photo (same order as Fotograflar)</summary>
    public List<string> BlurHashes { get; set; } = new();

    // ================== DURUM BİLGİLERİ ==================
    public bool Aktif { get; set; } = true;

    public bool Onaylandi { get; set; } = false;

    public int GoruntulemeSayisi { get; set; } = 0;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

[BsonIgnoreExtraElements]
public class GeoLocation
{
    [BsonElement("type")]
    public string Type { get; set; } = "Point";

    [BsonElement("coordinates")]
    public double[] Coordinates { get; set; } = new double[2]; // [longitude, latitude]
}

public class MongoDBSettings
{
    public string ConnectionString { get; set; } = string.Empty;
    public string DatabaseName { get; set; } = string.Empty;
    public string ListingsCollectionName { get; set; } = "ilans";
}
