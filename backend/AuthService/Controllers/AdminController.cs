using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using AuthService.Repositories;
using AuthService.Models;

namespace AuthService.Controllers;

[ApiController]
[Route("api/auth/admin")]
[Authorize(Roles = "admin")]
public class AdminController : ControllerBase
{
    private readonly IUserRepository _userRepository;
    private readonly ILogger<AdminController> _logger;

    public AdminController(IUserRepository userRepository, ILogger<AdminController> logger)
    {
        _userRepository = userRepository;
        _logger = logger;
    }

    /// <summary>Admin: Tüm kullanıcıları listele (sayfalı, aranabilir)</summary>
    [HttpGet("users")]
    public async Task<IActionResult> GetUsers(
        [FromQuery] int skip = 0,
        [FromQuery] int limit = 20,
        [FromQuery] string? search = null,
        [FromQuery] string? rol = null)
    {
        var users = await _userRepository.GetAllAsync(skip, limit, search, rol);
        var total = await _userRepository.GetTotalCountAsync(search, rol);

        return Ok(new
        {
            total,
            skip,
            limit,
            users = users.Select(u => new
            {
                u.Id,
                u.Ad,
                u.Soyad,
                u.Email,
                u.Telefon,
                u.Rol,
                u.Onayli,
                u.Banli,
                u.EmailOnayli,
                u.TelefonOnayli,
                u.TwoFactorEnabled,
                u.CreatedAt,
                u.UpdatedAt
            })
        });
    }

    /// <summary>Admin: Tek kullanıcı detayı</summary>
    [HttpGet("users/{id}")]
    public async Task<IActionResult> GetUser(string id)
    {
        var user = await _userRepository.GetByIdAsync(id);
        if (user == null) return NotFound(new { error = "Kullanıcı bulunamadı" });

        return Ok(new
        {
            user.Id, user.Ad, user.Soyad, user.Email, user.Telefon,
            user.Rol, user.Onayli, user.Banli, user.EmailOnayli,
            user.TelefonOnayli, user.TwoFactorEnabled,
            user.YetkiBelgesiNo, user.SirketAdi,
            user.CreatedAt, user.UpdatedAt
        });
    }

    /// <summary>Admin: Yeni kullanıcı oluştur</summary>
    [HttpPost("users")]
    public async Task<IActionResult> CreateUser([FromBody] AdminCreateUserRequest request)
    {
        if (await _userRepository.EmailExistsAsync(request.Email))
            return BadRequest(new { error = "Bu e-posta adresi zaten kullanımda" });

        if (await _userRepository.PhoneExistsAsync(request.Telefon))
            return BadRequest(new { error = "Bu telefon numarası zaten kullanımda" });

        var passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
        var user = new User
        {
            Ad = request.Ad,
            Soyad = request.Soyad,
            Email = request.Email,
            Telefon = request.Telefon,
            PasswordHash = passwordHash,
            Rol = request.Rol ?? "kullanici",
            Onayli = request.Onayli,
        };

        var created = await _userRepository.CreateAsync(user);
        _logger.LogInformation("Admin created user: {Email}", created.Email);
        return Ok(new { message = "Kullanıcı oluşturuldu", id = created.Id });
    }

    /// <summary>Admin: Kullanıcı bilgilerini güncelle</summary>
    [HttpPut("users/{id}")]
    public async Task<IActionResult> UpdateUser(string id, [FromBody] AdminUpdateUserRequest request)
    {
        var user = await _userRepository.GetByIdAsync(id);
        if (user == null) return NotFound(new { error = "Kullanıcı bulunamadı" });

        if (!string.IsNullOrEmpty(request.Email) && request.Email != user.Email)
        {
            if (await _userRepository.EmailExistsAsync(request.Email))
                return BadRequest(new { error = "Bu e-posta adresi zaten kullanımda" });
            user.Email = request.Email;
        }

        if (!string.IsNullOrEmpty(request.Ad)) user.Ad = request.Ad;
        if (!string.IsNullOrEmpty(request.Soyad)) user.Soyad = request.Soyad;
        if (!string.IsNullOrEmpty(request.Telefon)) user.Telefon = request.Telefon;
        if (!string.IsNullOrEmpty(request.Rol)) user.Rol = request.Rol;
        if (request.Onayli.HasValue) user.Onayli = request.Onayli.Value;
        if (!string.IsNullOrEmpty(request.Password))
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

        await _userRepository.UpdateAsync(id, user);
        _logger.LogInformation("Admin updated user: {UserId}", id);
        return Ok(new { message = "Kullanıcı güncellendi" });
    }

    /// <summary>Admin: Kullanıcıyı sil</summary>
    [HttpDelete("users/{id}")]
    public async Task<IActionResult> DeleteUser(string id)
    {
        var deleted = await _userRepository.DeleteAsync(id);
        if (!deleted) return NotFound(new { error = "Kullanıcı bulunamadı" });

        _logger.LogWarning("Admin deleted user: {UserId}", id);
        return Ok(new { message = "Kullanıcı silindi" });
    }

    /// <summary>Admin: Kullanıcıyı ban'la / ban kaldır (toggle)</summary>
    [HttpPatch("users/{id}/ban")]
    public async Task<IActionResult> ToggleBan(string id)
    {
        var user = await _userRepository.BanToggleAsync(id);
        if (user == null) return NotFound(new { error = "Kullanıcı bulunamadı" });

        _logger.LogWarning("Admin ban toggle: {UserId} → banli={Banli}", id, user.Banli);
        return Ok(new { message = user.Banli ? "Kullanıcı banlandı" : "Ban kaldırıldı", banli = user.Banli });
    }

    /// <summary>Admin: Kullanıcı rolünü değiştir</summary>
    [HttpPatch("users/{id}/rol")]
    public async Task<IActionResult> UpdateRol(string id, [FromBody] UpdateRolRequest request)
    {
        var validRoles = new[] { "kullanici", "emlakci", "admin" };
        if (!validRoles.Contains(request.Rol))
            return BadRequest(new { error = "Geçersiz rol. kullanici, emlakci veya admin olmalı" });

        var user = await _userRepository.UpdateRolAsync(id, request.Rol);
        if (user == null) return NotFound(new { error = "Kullanıcı bulunamadı" });

        _logger.LogInformation("Admin rol changed: {UserId} → {Rol}", id, request.Rol);
        return Ok(new { message = "Rol güncellendi", rol = user.Rol });
    }

    /// <summary>Admin: Kullanıcı istatistikleri</summary>
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats()
    {
        var stats = await _userRepository.GetStatsAsync();
        return Ok(stats);
    }
}

public record UpdateRolRequest(string Rol);
public record AdminCreateUserRequest(
    string Ad, string Soyad, string Email, string Telefon, string Password,
    string? Rol = "kullanici", bool Onayli = false
);
public record AdminUpdateUserRequest(
    string? Ad, string? Soyad, string? Email, string? Telefon,
    string? Rol, bool? Onayli, string? Password
);
