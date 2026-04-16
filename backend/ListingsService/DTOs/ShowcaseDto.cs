namespace ListingsService.DTOs;

/// <summary>
/// Showcase DTO containing categorized listings for homepage vitrin
/// </summary>
public class ShowcaseDto
{
    /// <summary>
    /// Günün fırsatları - Premium, featured listings
    /// </summary>
    public List<ListingDto> GununFirsatlari { get; set; } = new();
    
    /// <summary>
    /// Acil satılık ilanlar - Urgent sale listings
    /// </summary>
    public List<ListingDto> AcilSatiliklar { get; set; } = new();
    
    /// <summary>
    /// Son 48 saatte eklenen ilanlar
    /// </summary>
    public List<ListingDto> SonEklenenler { get; set; } = new();
    
    /// <summary>
    /// Çok görüntülenen ilanlar
    /// </summary>
    public List<ListingDto> CokGoruntulenler { get; set; } = new();
    
    /// <summary>
    /// Fiyatı düşen ilanlar
    /// </summary>
    public List<ListingDto> FiyatiDusenler { get; set; } = new();
}
