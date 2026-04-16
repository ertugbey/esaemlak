using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace ListingsService.Models;

/// <summary>
/// Emlak Ofisi (Real Estate Agency) model for corporate profiles
/// </summary>
public class Agency
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = ObjectId.GenerateNewId().ToString();
    
    // Temel Bilgiler
    public string OwnerId { get; set; } = string.Empty; // User who owns this agency
    public string FirmaAdi { get; set; } = string.Empty; // Company name
    public string? Logo { get; set; }
    public string? KapakFoto { get; set; } // Cover photo
    
    // İletişim
    public string Telefon { get; set; } = string.Empty;
    public string? Telefon2 { get; set; }
    public string? Email { get; set; }
    public string? Website { get; set; }
    public string? WhatsApp { get; set; }
    
    // Konum
    public string Il { get; set; } = string.Empty;
    public string Ilce { get; set; } = string.Empty;
    public string? Adres { get; set; }
    public GeoLocation? Konum { get; set; }
    
    // Firma Detayları
    public string? Hakkinda { get; set; } // About section
    public int KurulusYili { get; set; }
    public string? VergiNo { get; set; }
    public bool Onaylanmis { get; set; } = false; // Verified badge
    
    // Çalışma Saatleri
    public string? CalismaSaatleri { get; set; } // e.g., "09:00-18:00"
    public List<string> CalismaGunleri { get; set; } = new() { "Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma" };
    
    // Sosyal Medya
    public string? FacebookUrl { get; set; }
    public string? InstagramUrl { get; set; }
    public string? TwitterUrl { get; set; }
    public string? YouTubeUrl { get; set; }
    
    // İstatistikler (computed or cached)
    public int ToplamIlan { get; set; }
    public int AktifIlan { get; set; }
    public double Puan { get; set; } // Rating out of 5
    public int YorumSayisi { get; set; }
    
    // Meta
    public bool Aktif { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>
/// DTO for agency public profile view
/// </summary>
public record AgencyDto(
    string Id,
    string FirmaAdi,
    string? Logo,
    string? KapakFoto,
    string Telefon,
    string? Email,
    string? Website,
    string Il,
    string Ilce,
    string? Adres,
    string? Hakkinda,
    int KurulusYili,
    bool Onaylanmis,
    string? CalismaSaatleri,
    List<string> CalismaGunleri,
    string? FacebookUrl,
    string? InstagramUrl,
    int ToplamIlan,
    int AktifIlan,
    double Puan,
    int YorumSayisi,
    DateTime CreatedAt
);

/// <summary>
/// Request DTO for creating/updating an agency
/// </summary>
public record CreateAgencyRequest(
    string FirmaAdi,
    string Telefon,
    string? Telefon2,
    string? Email,
    string? Website,
    string? WhatsApp,
    string Il,
    string Ilce,
    string? Adres,
    double? Latitude,
    double? Longitude,
    string? Hakkinda,
    int KurulusYili,
    string? VergiNo,
    string? CalismaSaatleri,
    List<string>? CalismaGunleri,
    string? FacebookUrl,
    string? InstagramUrl,
    string? TwitterUrl,
    string? YouTubeUrl
);
