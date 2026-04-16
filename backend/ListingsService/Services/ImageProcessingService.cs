using SixLabors.ImageSharp;
using SixLabors.ImageSharp.Formats.Webp;
using SixLabors.ImageSharp.PixelFormats;
using SixLabors.ImageSharp.Processing;
using Blurhash.ImageSharp;

namespace ListingsService.Services;

/// <summary>
/// Image processing service that handles:
/// - Resize to multiple quality tiers (thumbnail, medium, full)
/// - Convert to WebP format for optimal mobile delivery
/// - Generate BlurHash placeholder strings
/// </summary>
public interface IImageProcessingService
{
    /// <summary>Process uploaded image: resize, convert to WebP, generate BlurHash</summary>
    Task<ImageProcessingResult> ProcessImageAsync(Stream imageStream, string originalFileName);
}

public class ImageProcessingResult
{
    public string OriginalUrl { get; set; } = string.Empty;
    public string ThumbnailUrl { get; set; } = string.Empty;
    public string MediumUrl { get; set; } = string.Empty;
    public string BlurHash { get; set; } = string.Empty;
    public int OriginalWidth { get; set; }
    public int OriginalHeight { get; set; }
    public long OriginalSizeBytes { get; set; }
    public long OptimizedSizeBytes { get; set; }
}

public class ImageProcessingService : IImageProcessingService
{
    private readonly IWebHostEnvironment _env;
    private readonly ILogger<ImageProcessingService> _logger;

    // Quality tiers for real estate photos
    private const int ThumbnailWidth = 300;
    private const int MediumWidth = 800;
    private const int FullWidth = 1920;
    private const int WebPQuality = 80;
    private const int ThumbnailQuality = 60;

    public ImageProcessingService(IWebHostEnvironment env, ILogger<ImageProcessingService> logger)
    {
        _env = env;
        _logger = logger;
    }

    public async Task<ImageProcessingResult> ProcessImageAsync(Stream imageStream, string originalFileName)
    {
        var result = new ImageProcessingResult();
        var uploadsBase = Path.Combine(_env.WebRootPath ?? "wwwroot", "images", "listings");
        Directory.CreateDirectory(uploadsBase);

        var id = Guid.NewGuid().ToString("N")[..12];
        result.OriginalSizeBytes = imageStream.Length;

        using var image = await Image.LoadAsync(imageStream);
        result.OriginalWidth = image.Width;
        result.OriginalHeight = image.Height;

        // 1. Generate BlurHash (from small version for speed)
        try
        {
            using var blurImage = image.CloneAs<Rgb24>();
            blurImage.Mutate(ctx => ctx.Resize(new ResizeOptions
            {
                Size = new Size(32, 32),
                Mode = ResizeMode.Max
            }));
            result.BlurHash = Blurhasher.Encode(blurImage, 4, 3);
            _logger.LogInformation("BlurHash generated: {Hash}", result.BlurHash);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "BlurHash generation failed, using empty string");
            result.BlurHash = string.Empty;
        }

        // 2. Save full-size WebP
        var fullName = $"{id}_full.webp";
        using (var fullImage = image.Clone(ctx =>
        {
            if (image.Width > FullWidth)
                ctx.Resize(new ResizeOptions { Size = new Size(FullWidth, 0), Mode = ResizeMode.Max });
        }))
        {
            var fullPath = Path.Combine(uploadsBase, fullName);
            await fullImage.SaveAsWebpAsync(fullPath, new WebpEncoder { Quality = WebPQuality });
            result.OriginalUrl = $"/images/listings/{fullName}";
            result.OptimizedSizeBytes = new FileInfo(fullPath).Length;
        }

        // 3. Save medium WebP (for listing cards)
        var medName = $"{id}_med.webp";
        using (var medImage = image.Clone(ctx => ctx.Resize(new ResizeOptions
        {
            Size = new Size(MediumWidth, 0),
            Mode = ResizeMode.Max
        })))
        {
            var medPath = Path.Combine(uploadsBase, medName);
            await medImage.SaveAsWebpAsync(medPath, new WebpEncoder { Quality = WebPQuality });
            result.MediumUrl = $"/images/listings/{medName}";
        }

        // 4. Save thumbnail WebP (for grid views)
        var thumbName = $"{id}_thumb.webp";
        using (var thumbImage = image.Clone(ctx => ctx.Resize(new ResizeOptions
        {
            Size = new Size(ThumbnailWidth, 0),
            Mode = ResizeMode.Max
        })))
        {
            var thumbPath = Path.Combine(uploadsBase, thumbName);
            await thumbImage.SaveAsWebpAsync(thumbPath, new WebpEncoder { Quality = ThumbnailQuality });
            result.ThumbnailUrl = $"/images/listings/{thumbName}";
        }

        var compressionRatio = result.OriginalSizeBytes > 0
            ? (1.0 - (double)result.OptimizedSizeBytes / result.OriginalSizeBytes) * 100
            : 0;

        _logger.LogInformation(
            "Image processed: {Original} → {Optimized}KB ({Ratio:F0}% smaller), BlurHash: {Hash}",
            result.OriginalSizeBytes / 1024, result.OptimizedSizeBytes / 1024, compressionRatio, result.BlurHash);

        return result;
    }
}
