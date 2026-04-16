using ListingsService.DTOs;
using ListingsService.Models;
using ListingsService.Repositories;

namespace ListingsService.Services;

public interface IShowcaseService
{
    Task<ShowcaseDto> GetShowcaseAsync();
}

/// <summary>
/// Service for generating homepage showcase/vitrin data
/// </summary>
public class ShowcaseService : IShowcaseService
{
    private readonly IListingRepository _repository;
    private readonly ILogger<ShowcaseService> _logger;

    public ShowcaseService(
        IListingRepository repository,
        ILogger<ShowcaseService> logger)
    {
        _repository = repository;
        _logger = logger;
    }

    /// <summary>
    /// Get all showcase sections for homepage
    /// </summary>
    public async Task<ShowcaseDto> GetShowcaseAsync()
    {
        _logger.LogInformation("Fetching showcase data for homepage");

        // Run all queries in parallel for performance
        var gununFirsatlariTask = _repository.GetCokGoruntulenlerAsync(6);
        var acilSatilikTask = _repository.GetAcilSatilikAsync(10);
        var sonEklenenlerTask = _repository.GetSonEklenenlerAsync(48, 10);
        var cokGoruntulenlerTask = _repository.GetCokGoruntulenlerAsync(10);
        var fiyatiDusenlerTask = _repository.GetFiyatiDusenlerAsync(10);

        await Task.WhenAll(
            gununFirsatlariTask, 
            acilSatilikTask, 
            sonEklenenlerTask, 
            cokGoruntulenlerTask,
            fiyatiDusenlerTask
        );

        return new ShowcaseDto
        {
            GununFirsatlari = (await gununFirsatlariTask).Select(MapToDto).ToList(),
            AcilSatiliklar = (await acilSatilikTask).Select(MapToDto).ToList(),
            SonEklenenler = (await sonEklenenlerTask).Select(MapToDto).ToList(),
            CokGoruntulenler = (await cokGoruntulenlerTask).Select(MapToDto).ToList(),
            FiyatiDusenler = (await fiyatiDusenlerTask).Select(MapToDto).ToList()
        };
    }

    private static ListingDto MapToDto(Listing listing) => new ListingDto(
        Id: listing.Id,
        EmlakciId: listing.EmlakciId,
        Baslik: listing.Baslik,
        Aciklama: listing.Aciklama,
        Kategori: listing.Kategori,
        AltKategori: listing.AltKategori,
        IslemTipi: listing.IslemTipi,
        EmlakTipi: listing.EmlakTipi,
        Fiyat: listing.Fiyat,
        BrutMetrekare: listing.BrutMetrekare,
        NetMetrekare: listing.NetMetrekare,
        Metrekare: listing.Metrekare,
        OdaSayisi: listing.OdaSayisi,
        BinaYasi: listing.BinaYasi,
        BanyoSayisi: listing.BanyoSayisi,
        BulunduguKat: listing.BulunduguKat,
        KatSayisi: listing.KatSayisi,
        IsitmaTipi: listing.IsitmaTipi,
        Esyali: listing.Esyali,
        Balkon: listing.Balkon,
        Asansor: listing.Asansor,
        Otopark: listing.Otopark,
        SiteIcerisinde: listing.SiteIcerisinde,
        Havuz: listing.Havuz,
        Guvenlik: listing.Guvenlik,
        GirisYuksekligi: listing.GirisYuksekligi,
        ZeminEtudu: listing.ZeminEtudu,
        Devren: listing.Devren,
        Kiracili: listing.Kiracili,
        YapininDurumu: listing.YapininDurumu,
        AdaParsel: listing.AdaParsel,
        Gabari: listing.Gabari,
        KaksEmsal: listing.KaksEmsal,
        KatKarsiligi: listing.KatKarsiligi,
        ImarDurumu: listing.ImarDurumu,
        Manzara: listing.Manzara ?? new List<string>(),
        Cephe: listing.Cephe ?? new List<string>(),
        Ulasim: listing.Ulasim ?? new List<string>(),
        Muhit: listing.Muhit ?? new List<string>(),
        IcOzellikler: listing.IcOzellikler ?? new List<string>(),
        DisOzellikler: listing.DisOzellikler ?? new List<string>(),
        EngelliyeUygunluk: listing.EngelliyeUygunluk ?? new List<string>(),
        AcilSatilik: listing.AcilSatilik,
        FiyatiDustu: listing.FiyatiDustu,
        KrediyeUygun: listing.KrediyeUygun,
        Takasli: listing.Takasli,
        TapuDurumu: listing.TapuDurumu,
        Kimden: listing.Kimden,
        Il: listing.Il,
        Ilce: listing.Ilce,
        Mahalle: listing.Mahalle,
        Latitude: listing.Konum?.Coordinates[1],
        Longitude: listing.Konum?.Coordinates[0],
        Fotograflar: listing.Fotograflar,
        Aktif: listing.Aktif,
        GoruntulemeSayisi: listing.GoruntulemeSayisi,
        CreatedAt: listing.CreatedAt
    );
}
