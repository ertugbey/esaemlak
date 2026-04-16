using MongoDB.Bson;
using MongoDB.Bson.Serialization.Attributes;

namespace AuthService.Models;

public class User
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; } = string.Empty;

    [BsonElement("ad")]
    public string Ad { get; set; } = string.Empty;

    [BsonElement("soyad")]
    public string Soyad { get; set; } = string.Empty;

    [BsonElement("email")]
    public string Email { get; set; } = string.Empty;

    [BsonElement("telefon")]
    public string Telefon { get; set; } = string.Empty;

    [BsonElement("sifre")]
    public string PasswordHash { get; set; } = string.Empty;

    [BsonElement("rol")]
    public string Rol { get; set; } = "kullanici"; // emlakci, kullanici, admin

    [BsonElement("yetkiBelgesiNo")]
    public string? YetkiBelgesiNo { get; set; }

    [BsonElement("sirketAdi")]
    public string? SirketAdi { get; set; }

    [BsonElement("onayli")]
    public bool Onayli { get; set; } = false;

    [BsonElement("banli")]
    public bool Banli { get; set; } = false;

    [BsonElement("emailOnayli")]
    public bool EmailOnayli { get; set; } = false;

    [BsonElement("telefonOnayli")]
    public bool TelefonOnayli { get; set; } = false;

    [BsonElement("twoFactorEnabled")]
    public bool TwoFactorEnabled { get; set; } = false;

    [BsonElement("pushToken")]
    public string? PushToken { get; set; }

    [BsonElement("profilFoto")]
    public string? ProfilFoto { get; set; }

    [BsonElement("refreshToken")]
    public string? RefreshToken { get; set; }

    [BsonElement("refreshTokenExpiry")]
    public DateTime? RefreshTokenExpiry { get; set; }

    [BsonElement("passwordResetToken")]
    public string? PasswordResetToken { get; set; }

    [BsonElement("passwordResetExpiry")]
    public DateTime? PasswordResetExpiry { get; set; }

    [BsonElement("createdAt")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [BsonElement("updatedAt")]
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
