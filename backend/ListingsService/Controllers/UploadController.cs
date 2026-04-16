using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using ListingsService.Services;

namespace ListingsService.Controllers;

/// <summary>
/// Controller for handling listing photo uploads with image optimization.
/// Features: multi-file upload, ImageSharp resize, WebP conversion, BlurHash generation
/// </summary>
[ApiController]
[Route("api/listings")]
public class UploadController : ControllerBase
{
    private readonly IWebHostEnvironment _env;
    private readonly IImageProcessingService _imageService;
    private readonly ILogger<UploadController> _logger;
    private readonly string[] _allowedExtensions = { ".jpg", ".jpeg", ".png", ".webp", ".bmp" };
    private const long MaxFileSize = 15 * 1024 * 1024; // 15MB max per file

    public UploadController(
        IWebHostEnvironment env,
        IImageProcessingService imageService,
        ILogger<UploadController> logger)
    {
        _env = env;
        _imageService = imageService;
        _logger = logger;
    }

    /// <summary>
    /// Upload and optimize multiple photos for a listing.
    /// Returns thumbnail, medium, and full-size WebP URLs + BlurHash for each image.
    /// </summary>
    [Authorize]
    [HttpPost("upload")]
    [RequestSizeLimit(100 * 1024 * 1024)] // 100MB total limit
    public async Task<ActionResult<UploadResult>> UploadPhotos([FromForm] List<IFormFile> files)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
            return Unauthorized();

        if (files == null || files.Count == 0)
            return BadRequest(new { error = "No files provided" });

        if (files.Count > 15)
            return BadRequest(new { error = "Maximum 15 files allowed per upload" });

        var processedImages = new List<ProcessedImageDto>();
        var errors = new List<string>();

        foreach (var file in files)
        {
            try
            {
                // Validate file
                if (file.Length == 0)
                {
                    errors.Add($"{file.FileName}: Empty file");
                    continue;
                }

                if (file.Length > MaxFileSize)
                {
                    errors.Add($"{file.FileName}: File too large (max 15MB)");
                    continue;
                }

                var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
                if (!_allowedExtensions.Contains(ext))
                {
                    errors.Add($"{file.FileName}: Invalid file type. Allowed: jpg, jpeg, png, webp, bmp");
                    continue;
                }

                // Process image (resize, WebP convert, BlurHash)
                using var stream = file.OpenReadStream();
                var result = await _imageService.ProcessImageAsync(stream, file.FileName);

                processedImages.Add(new ProcessedImageDto
                {
                    OriginalUrl = result.OriginalUrl,
                    MediumUrl = result.MediumUrl,
                    ThumbnailUrl = result.ThumbnailUrl,
                    BlurHash = result.BlurHash,
                    Width = result.OriginalWidth,
                    Height = result.OriginalHeight,
                    OriginalSizeKB = (int)(result.OriginalSizeBytes / 1024),
                    OptimizedSizeKB = (int)(result.OptimizedSizeBytes / 1024)
                });

                _logger.LogInformation(
                    "Processed photo {FileName} for user {UserId}: {OrigKB}KB → {OptKB}KB",
                    file.FileName, userId, result.OriginalSizeBytes / 1024, result.OptimizedSizeBytes / 1024);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error processing file {FileName}", file.FileName);
                errors.Add($"{file.FileName}: Processing failed");
            }
        }

        return Ok(new UploadResult
        {
            Success = processedImages.Count > 0,
            Images = processedImages,
            // Backward compatibility: UploadedUrls returns full-size URLs
            UploadedUrls = processedImages.Select(i => i.OriginalUrl).ToList(),
            Errors = errors,
            Message = $"{processedImages.Count} of {files.Count} files uploaded and optimized"
        });
    }

    /// <summary>
    /// Delete a photo (all variants: full, medium, thumbnail)
    /// </summary>
    [Authorize]
    [HttpDelete("photos/{fileName}")]
    public IActionResult DeletePhoto(string fileName)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
            return Unauthorized();

        var basePath = Path.Combine(_env.WebRootPath ?? "wwwroot", "images", "listings");
        var baseId = Path.GetFileNameWithoutExtension(fileName);

        // Try to delete all variants
        var variants = new[] { $"{baseId}.webp", $"{baseId}_full.webp", $"{baseId}_med.webp", $"{baseId}_thumb.webp", fileName };
        var deleted = 0;

        foreach (var variant in variants)
        {
            var path = Path.Combine(basePath, variant);
            if (System.IO.File.Exists(path))
            {
                System.IO.File.Delete(path);
                deleted++;
            }
        }

        if (deleted == 0)
            return NotFound(new { error = "File not found" });

        _logger.LogInformation("Deleted {Count} photo variants for {FileName} by user {UserId}", deleted, fileName, userId);
        return Ok(new { message = $"Deleted {deleted} file(s) successfully" });
    }
}

public class UploadResult
{
    public bool Success { get; set; }
    public List<ProcessedImageDto> Images { get; set; } = new();
    public List<string> UploadedUrls { get; set; } = new(); // Backward compatibility
    public List<string> Errors { get; set; } = new();
    public string Message { get; set; } = string.Empty;
}

public class ProcessedImageDto
{
    public string OriginalUrl { get; set; } = string.Empty;
    public string MediumUrl { get; set; } = string.Empty;
    public string ThumbnailUrl { get; set; } = string.Empty;
    public string BlurHash { get; set; } = string.Empty;
    public int Width { get; set; }
    public int Height { get; set; }
    public int OriginalSizeKB { get; set; }
    public int OptimizedSizeKB { get; set; }
}
