using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using AuthService.Configuration;
using AuthService.DTOs;
using AuthService.Models;
using AuthService.Repositories;
using Shared.Events.Auth;

namespace AuthService.Services;

public interface IAuthenticationService
{
    Task<LoginResponse> RegisterAsync(RegisterRequest request);
    Task<LoginResponse> LoginAsync(LoginRequest request);
    Task<UserDto> GetCurrentUserAsync(string userId);
    Task LogoutAsync(string userId, string jwtToken);
    Task LogoutAllDevicesAsync(string userId);
    Task<LoginResponse> RefreshTokenAsync(string refreshToken);
    Task ForgotPasswordAsync(string email);
    Task ResetPasswordAsync(ResetPasswordRequest request);
    Task ChangePasswordAsync(string userId, ChangePasswordRequest request);
    Task<UserDto> UpdateProfileAsync(string userId, UpdateProfileRequest request);
}

public class AuthenticationService : IAuthenticationService
{
    private readonly IUserRepository _userRepository;
    private readonly JwtSettings _jwtSettings;
    private readonly ILogger<AuthenticationService> _logger;
    private readonly IEventBus _eventBus;
    private readonly ITokenBlacklistService _tokenBlacklist;

    public AuthenticationService(
        IUserRepository userRepository,
        IOptions<JwtSettings> jwtSettings,
        ILogger<AuthenticationService> logger,
        IEventBus eventBus,
        ITokenBlacklistService tokenBlacklist)
    {
        _userRepository = userRepository;
        _jwtSettings = jwtSettings.Value;
        _logger = logger;
        _eventBus = eventBus;
        _tokenBlacklist = tokenBlacklist;
    }

    public async Task<LoginResponse> RegisterAsync(RegisterRequest request)
    {
        _logger.LogInformation("Registration attempt for email: {Email}", request.Email);

        // Check if email exists
        if (await _userRepository.EmailExistsAsync(request.Email))
        {
            _logger.LogWarning("Registration failed: Email already exists {Email}", request.Email);
            throw new InvalidOperationException("Email already in use");
        }

        // Check if phone exists
        if (await _userRepository.PhoneExistsAsync(request.Telefon))
        {
            _logger.LogWarning("Registration failed: Phone already exists {Phone}", request.Telefon);
            throw new InvalidOperationException("Phone number already in use");
        }

        // Hash password
        var passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

        // Create user
        var user = new User
        {
            Ad = request.Ad,
            Soyad = request.Soyad,
            Email = request.Email,
            Telefon = request.Telefon,
            PasswordHash = passwordHash,
            Rol = request.Rol,
            YetkiBelgesiNo = request.YetkiBelgesiNo,
            SirketAdi = request.SirketAdi,
            Onayli = request.Rol == "kullanici", // Auto-approve regular users
            EmailOnayli = false,
            TelefonOnayli = false
        };

        var createdUser = await _userRepository.CreateAsync(user);
        
        _logger.LogInformation(
            "User registered successfully {Email} {UserId} {Role}", 
            createdUser.Email, 
            createdUser.Id, 
            createdUser.Rol
        );

        // Publish UserRegistered event to RabbitMQ
        await _eventBus.PublishAsync(new UserRegisteredEvent
        {
            UserId = createdUser.Id,
            Email = createdUser.Email,
            FullName = $"{createdUser.Ad} {createdUser.Soyad}",
            Role = createdUser.Rol,
            RequiresApproval = !createdUser.Onayli
        });

        _logger.LogInformation("UserRegistered event published for {UserId}", createdUser.Id);

        // Generate tokens
        var token = GenerateJwtToken(createdUser);
        var refreshToken = GenerateRefreshToken();

        // Store refresh token
        await _userRepository.UpdateRefreshTokenAsync(
            createdUser.Id,
            refreshToken,
            DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpirationDays)
        );

        return new LoginResponse(
            token,
            refreshToken,
            MapToUserDto(createdUser)
        );
    }

    public async Task<LoginResponse> LoginAsync(LoginRequest request)
    {
        _logger.LogInformation("Login attempt for email: {Email}", request.Email);

        var user = await _userRepository.GetByEmailAsync(request.Email);

        if (user == null)
        {
            _logger.LogWarning("Login failed: User not found {Email}", request.Email);
            throw new UnauthorizedAccessException("Invalid credentials");
        }

        if (user.Banli)
        {
            _logger.LogWarning("Login failed: User is banned {Email} {UserId}", request.Email, user.Id);
            throw new UnauthorizedAccessException("Account is banned");
        }

        if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
        {
            _logger.LogWarning("Login failed: Invalid password {Email} {UserId}", request.Email, user.Id);
            throw new UnauthorizedAccessException("Invalid credentials");
        }

        _logger.LogInformation(
            "User logged in successfully {Email} {UserId} {Role}",
            user.Email,
            user.Id,
            user.Rol
        );

        // Publish UserLoggedIn event
        await _eventBus.PublishAsync(new UserLoggedInEvent
        {
            UserId = user.Id,
            Email = user.Email
        });

        var token = GenerateJwtToken(user);
        var refreshToken = GenerateRefreshToken();

        // Store refresh token
        await _userRepository.UpdateRefreshTokenAsync(
            user.Id,
            refreshToken,
            DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpirationDays)
        );

        return new LoginResponse(
            token,
            refreshToken,
            MapToUserDto(user)
        );
    }

    public async Task<UserDto> GetCurrentUserAsync(string userId)
    {
        _logger.LogDebug("Fetching current user: {UserId}", userId);
        
        var user = await _userRepository.GetByIdAsync(userId);
        
        if (user == null)
        {
            _logger.LogWarning("User not found: {UserId}", userId);
            throw new InvalidOperationException("User not found");
        }

        return MapToUserDto(user);
    }

    public async Task LogoutAsync(string userId, string jwtToken)
    {
        _logger.LogInformation("User logout: {UserId}", userId);
        
        // Blacklist the current JWT token in Redis
        await _tokenBlacklist.BlacklistTokenAsync(jwtToken);
        
        // Clear refresh token in MongoDB
        await _userRepository.ClearRefreshTokenAsync(userId);
        
        _logger.LogInformation("User {UserId} logged out — token blacklisted", userId);
    }

    public async Task LogoutAllDevicesAsync(string userId)
    {
        _logger.LogInformation("User logout from all devices: {UserId}", userId);
        
        // Blacklist ALL tokens for this user in Redis
        await _tokenBlacklist.BlacklistAllUserTokensAsync(userId);
        
        // Clear refresh token in MongoDB
        await _userRepository.ClearRefreshTokenAsync(userId);
        
        _logger.LogInformation("User {UserId} logged out from all devices", userId);
    }

    public async Task<LoginResponse> RefreshTokenAsync(string refreshToken)
    {
        _logger.LogInformation("Refresh token attempt");

        var user = await _userRepository.GetByRefreshTokenAsync(refreshToken);

        if (user == null)
        {
            _logger.LogWarning("Refresh token failed: Token not found");
            throw new UnauthorizedAccessException("Invalid refresh token");
        }

        if (user.RefreshTokenExpiry < DateTime.UtcNow)
        {
            _logger.LogWarning("Refresh token failed: Token expired for {UserId}", user.Id);
            await _userRepository.ClearRefreshTokenAsync(user.Id);
            throw new UnauthorizedAccessException("Refresh token expired");
        }

        if (user.Banli)
        {
            _logger.LogWarning("Refresh token failed: User is banned {UserId}", user.Id);
            throw new UnauthorizedAccessException("Account is banned");
        }

        // Generate new tokens
        var newJwt = GenerateJwtToken(user);
        var newRefreshToken = GenerateRefreshToken();

        await _userRepository.UpdateRefreshTokenAsync(
            user.Id,
            newRefreshToken,
            DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpirationDays)
        );

        _logger.LogInformation("Token refreshed for {UserId}", user.Id);

        return new LoginResponse(
            newJwt,
            newRefreshToken,
            MapToUserDto(user)
        );
    }

    public async Task ForgotPasswordAsync(string email)
    {
        _logger.LogInformation("Forgot password request for {Email}", email);

        var user = await _userRepository.GetByEmailAsync(email);

        if (user == null)
        {
            // Don't reveal whether email exists
            _logger.LogWarning("Forgot password: User not found {Email}", email);
            return;
        }

        // Generate a 6-digit reset code
        var resetCode = new Random().Next(100000, 999999).ToString();
        var expiry = DateTime.UtcNow.AddMinutes(15);

        await _userRepository.UpdatePasswordResetTokenAsync(user.Id, resetCode, expiry);

        _logger.LogInformation(
            "Password reset token generated for {UserId}", 
            user.Id
        );

        // Publish event to RabbitMQ — NotificationService will send the email
        await _eventBus.PublishAsync(new PasswordResetRequestedEvent
        {
            UserId = user.Id,
            Email = user.Email,
            FullName = $"{user.Ad} {user.Soyad}",
            ResetCode = resetCode,
            ExpiresAt = expiry
        });

        _logger.LogInformation("PasswordResetRequested event published for {UserId}", user.Id);
    }

    public async Task ResetPasswordAsync(ResetPasswordRequest request)
    {
        _logger.LogInformation("Reset password attempt for {Email}", request.Email);

        var user = await _userRepository.GetByEmailAsync(request.Email);

        if (user == null)
        {
            throw new InvalidOperationException("Invalid reset request");
        }

        if (user.PasswordResetToken != request.Token)
        {
            _logger.LogWarning("Reset password: Invalid token for {Email}", request.Email);
            throw new InvalidOperationException("Invalid or expired reset code");
        }

        if (user.PasswordResetExpiry < DateTime.UtcNow)
        {
            _logger.LogWarning("Reset password: Expired token for {Email}", request.Email);
            throw new InvalidOperationException("Invalid or expired reset code");
        }

        var newHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        await _userRepository.UpdatePasswordAsync(user.Id, newHash);

        // Clear refresh tokens (force re-login)
        await _userRepository.ClearRefreshTokenAsync(user.Id);

        _logger.LogInformation("Password reset successful for {UserId}", user.Id);
    }

    public async Task ChangePasswordAsync(string userId, ChangePasswordRequest request)
    {
        _logger.LogInformation("Change password for {UserId}", userId);

        var user = await _userRepository.GetByIdAsync(userId);

        if (user == null)
        {
            throw new InvalidOperationException("User not found");
        }

        if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
        {
            _logger.LogWarning("Change password failed: Invalid current password {UserId}", userId);
            throw new UnauthorizedAccessException("Current password is incorrect");
        }

        var newHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        await _userRepository.UpdatePasswordAsync(userId, newHash);

        // Invalidate all existing sessions (security best practice)
        await _tokenBlacklist.BlacklistAllUserTokensAsync(userId);
        await _userRepository.ClearRefreshTokenAsync(userId);

        _logger.LogInformation("Password changed and all sessions invalidated for {UserId}", userId);
    }

    public async Task<UserDto> UpdateProfileAsync(string userId, UpdateProfileRequest request)
    {
        _logger.LogInformation("Profile update for {UserId}", userId);

        var user = await _userRepository.GetByIdAsync(userId);
        if (user == null)
        {
            throw new InvalidOperationException("User not found");
        }

        var updates = new Dictionary<string, object?>();

        if (request.Ad != null) updates["ad"] = request.Ad;
        if (request.Soyad != null) updates["soyad"] = request.Soyad;
        if (request.Telefon != null)
        {
            // Check if new phone is taken by another user
            if (request.Telefon != user.Telefon && await _userRepository.PhoneExistsAsync(request.Telefon))
            {
                throw new InvalidOperationException("Phone number already in use");
            }
            updates["telefon"] = request.Telefon;
        }
        if (request.ProfilFoto != null) updates["profilFoto"] = request.ProfilFoto;
        if (request.SirketAdi != null) updates["sirketAdi"] = request.SirketAdi;
        if (request.YetkiBelgesiNo != null) updates["yetkiBelgesiNo"] = request.YetkiBelgesiNo;

        if (updates.Count > 0)
        {
            await _userRepository.UpdateProfileFieldsAsync(userId, updates);
        }

        // Return updated user
        var updatedUser = await _userRepository.GetByIdAsync(userId);
        _logger.LogInformation("Profile updated for {UserId}", userId);
        return MapToUserDto(updatedUser!);
    }

    private string GenerateJwtToken(User user)
    {
        var claims = new[]
        {
            new Claim(JwtRegisteredClaimNames.Sub, user.Id),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim(ClaimTypes.Name, $"{user.Ad} {user.Soyad}"),
            new Claim(ClaimTypes.Role, user.Rol),
            new Claim("rol", user.Rol), // Custom claim
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtSettings.Secret));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _jwtSettings.Issuer,
            audience: _jwtSettings.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(_jwtSettings.ExpirationMinutes),
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private string GenerateRefreshToken()
    {
        var randomBytes = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomBytes);
        return Convert.ToBase64String(randomBytes);
    }

    private UserDto MapToUserDto(User user) => new UserDto(
        user.Id,
        user.Ad,
        user.Soyad,
        user.Email,
        user.Telefon,
        user.Rol,
        user.Onayli,
        user.EmailOnayli,
        user.ProfilFoto,
        user.SirketAdi,
        user.YetkiBelgesiNo
    );
}
