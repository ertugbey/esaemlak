namespace AuthService.DTOs;

public record LoginRequest(string Email, string Password);

public record RegisterRequest(
    string Ad,
    string Soyad,
    string Email,
    string Telefon,
    string Password,
    string Rol = "kullanici",
    string? YetkiBelgesiNo = null,
    string? SirketAdi = null
);

public record LoginResponse(
    string Token,
    string RefreshToken,
    UserDto User
);

public record UserDto(
    string Id,
    string Ad,
    string Soyad,
    string Email,
    string Telefon,
    string Rol,
    bool Onayli,
    bool EmailOnayli,
    string? ProfilFoto = null,
    string? SirketAdi = null,
    string? YetkiBelgesiNo = null
);

// --- New DTOs ---

public record RefreshTokenRequest(string RefreshToken);

public record ForgotPasswordRequest(string Email);

public record ResetPasswordRequest(string Email, string Token, string NewPassword);

public record ChangePasswordRequest(string CurrentPassword, string NewPassword);

public record UpdateProfileRequest(
    string? Ad = null,
    string? Soyad = null,
    string? Telefon = null,
    string? ProfilFoto = null,
    string? SirketAdi = null,
    string? YetkiBelgesiNo = null
);

public record MessageResponse(string Message);
