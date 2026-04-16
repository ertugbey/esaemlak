using Microsoft.AspNetCore.Mvc;

namespace ListingsService.Controllers;

/// <summary>
/// Adres verileri için API endpoint'leri
/// İl > İlçe > Semt > Mahalle kaskad seçim yapısını destekler
/// </summary>
[ApiController]
[Route("api/locations")]
public class LocationController : ControllerBase
{
    /// <summary>
    /// Tüm illeri döndürür
    /// GET /api/locations/provinces
    /// </summary>
    [HttpGet("provinces")]
    public IActionResult GetProvinces()
    {
        return Ok(TurkiyeKonumlari.Iller);
    }

    /// <summary>
    /// Seçilen ile ait ilçeleri döndürür
    /// GET /api/locations/districts?cityName=İzmir
    /// </summary>
    [HttpGet("districts")]
    public IActionResult GetDistricts([FromQuery] string cityName)
    {
        if (string.IsNullOrEmpty(cityName))
            return BadRequest(new { error = "cityName parametresi gerekli" });

        if (TurkiyeKonumlari.Ilceler.TryGetValue(cityName, out var ilceler))
            return Ok(ilceler);

        return Ok(Array.Empty<string>());
    }

    /// <summary>
    /// Seçilen ilçeye ait semt ve mahalle bilgilerini döndürür
    /// GET /api/locations/neighborhoods?cityName=İzmir&districtName=Bayraklı&semt=Gümüşpala
    /// </summary>
    [HttpGet("neighborhoods")]
    public IActionResult GetNeighborhoods(
        [FromQuery] string cityName,
        [FromQuery] string districtName,
        [FromQuery] string? semt = null)
    {
        if (string.IsNullOrEmpty(cityName) || string.IsNullOrEmpty(districtName))
            return BadRequest(new { error = "cityName ve districtName parametreleri gerekli" });

        // Semt belirtilmişse mahalleler döndür
        if (!string.IsNullOrEmpty(semt))
        {
            var key = $"{cityName}|{districtName}|{semt}";
            if (TurkiyeKonumlari.Mahalleler.TryGetValue(key, out var mahalleler))
                return Ok(new { mahalleler });
            return Ok(new { mahalleler = Array.Empty<string>() });
        }

        // Semt belirtilmemişse semtleri döndür
        var semtKey = $"{cityName}|{districtName}";
        if (TurkiyeKonumlari.Semtler.TryGetValue(semtKey, out var semtler))
            return Ok(new { semtler });

        return Ok(new { semtler = Array.Empty<string>() });
    }
}

/// <summary>
/// Türkiye konum verileri — statik veri
/// İleride veritabanına taşınabilir
/// </summary>
public static class TurkiyeKonumlari
{
    public static readonly List<string> Iller = new()
    {
        "Adana", "Adıyaman", "Afyonkarahisar", "Ağrı", "Aksaray", "Amasya", "Ankara", "Antalya",
        "Ardahan", "Artvin", "Aydın", "Balıkesir", "Bartın", "Batman", "Bayburt", "Bilecik",
        "Bingöl", "Bitlis", "Bolu", "Burdur", "Bursa", "Çanakkale", "Çankırı", "Çorum",
        "Denizli", "Diyarbakır", "Düzce", "Edirne", "Elazığ", "Erzincan", "Erzurum",
        "Eskişehir", "Gaziantep", "Giresun", "Gümüşhane", "Hakkari", "Hatay", "Iğdır",
        "Isparta", "İstanbul", "İzmir", "Kahramanmaraş", "Karabük", "Karaman", "Kars",
        "Kastamonu", "Kayseri", "Kırıkkale", "Kırklareli", "Kırşehir", "Kilis", "Kocaeli",
        "Konya", "Kütahya", "Malatya", "Manisa", "Mardin", "Mersin", "Muğla", "Muş",
        "Nevşehir", "Niğde", "Ordu", "Osmaniye", "Rize", "Sakarya", "Samsun", "Siirt",
        "Sinop", "Sivas", "Şanlıurfa", "Şırnak", "Tekirdağ", "Tokat", "Trabzon", "Tunceli",
        "Uşak", "Van", "Yalova", "Yozgat", "Zonguldak"
    };

    public static readonly Dictionary<string, List<string>> Ilceler = new()
    {
        ["İstanbul"] = new() { "Adalar", "Arnavutköy", "Ataşehir", "Avcılar", "Bağcılar", "Bahçelievler", "Bakırköy", "Başakşehir", "Bayrampaşa", "Beşiktaş", "Beykoz", "Beylikdüzü", "Beyoğlu", "Büyükçekmece", "Çatalca", "Çekmeköy", "Esenler", "Esenyurt", "Eyüpsultan", "Fatih", "Gaziosmanpaşa", "Güngören", "Kadıköy", "Kağıthane", "Kartal", "Küçükçekmece", "Maltepe", "Pendik", "Sancaktepe", "Sarıyer", "Silivri", "Sultanbeyli", "Sultangazi", "Şile", "Şişli", "Tuzla", "Ümraniye", "Üsküdar", "Zeytinburnu" },
        ["Ankara"] = new() { "Akyurt", "Altındağ", "Ayaş", "Bala", "Beypazarı", "Çamlıdere", "Çankaya", "Çubuk", "Elmadağ", "Etimesgut", "Evren", "Gölbaşı", "Güdül", "Haymana", "Kahramankazan", "Kalecik", "Keçiören", "Kızılcahamam", "Mamak", "Nallıhan", "Polatlı", "Pursaklar", "Sincan", "Şereflikoçhisar", "Yenimahalle" },
        ["İzmir"] = new() { "Aliağa", "Balçova", "Bayındır", "Bayraklı", "Bergama", "Beydağ", "Bornova", "Buca", "Çeşme", "Çiğli", "Dikili", "Foça", "Gaziemir", "Güzelbahçe", "Karabağlar", "Karaburun", "Karşıyaka", "Kemalpaşa", "Kınık", "Kiraz", "Konak", "Menderes", "Menemen", "Narlıdere", "Ödemiş", "Seferihisar", "Selçuk", "Tire", "Torbalı", "Urla" },
        ["Bursa"] = new() { "Büyükorhan", "Gemlik", "Gürsu", "Harmancık", "İnegöl", "İznik", "Karacabey", "Keles", "Kestel", "Mudanya", "Mustafakemalpaşa", "Nilüfer", "Orhaneli", "Orhangazi", "Osmangazi", "Yenişehir", "Yıldırım" },
        ["Antalya"] = new() { "Akseki", "Aksu", "Alanya", "Demre", "Döşemealtı", "Elmalı", "Finike", "Gazipaşa", "Gündoğmuş", "İbradı", "Kaş", "Kemer", "Kepez", "Konyaaltı", "Korkuteli", "Kumluca", "Manavgat", "Muratpaşa", "Serik" },
    };

    // ─── Örnek Semt Verileri (büyük iller için) ───
    public static readonly Dictionary<string, List<string>> Semtler = new()
    {
        // İstanbul
        ["İstanbul|Kadıköy"] = new() { "Caferağa", "Fenerbahçe", "Fikirtepe", "Göztepe", "Koşuyolu", "Moda", "Osmanağa", "Rasimpaşa", "Suadiye", "Zühtüpaşa", "Bostancı", "Erenköy", "Caddebostan", "Acıbadem" },
        ["İstanbul|Beşiktaş"] = new() { "Abbasağa", "Arnavutköy", "Bebek", "Cihannüma", "Dikilitaş", "Etiler", "Kuruçeşme", "Levent", "Ortaköy", "Sinanpaşa", "Türkali", "Ulus", "Vişnezade", "Yıldız" },
        ["İstanbul|Fatih"] = new() { "Aksaray", "Balat", "Beyazıt", "Cankurtaran", "Cerrahpaşa", "Fener", "Kumkapı", "Laleli", "Sultanahmet", "Süleymaniye", "Vefa", "Zeyrek" },
        ["İstanbul|Üsküdar"] = new() { "Acıbadem", "Altunizade", "Beylerbeyi", "Burhaniye", "Çengelköy", "Ferah", "Kısıklı", "Küplüce", "Murat Reis", "Selimiye", "Ünalan", "Validei Atik" },
        ["İstanbul|Şişli"] = new() { "Bomonti", "Fulya", "Halaskargazi", "Harbiye", "Kuştepe", "Mecidiyeköy", "Meşrutiyet", "Nişantaşı", "Osmanbey", "Teşvikiye" },

        // Ankara
        ["Ankara|Çankaya"] = new() { "Ayrancı", "Bahçelievler", "Balgat", "Cebeci", "Çayyolu", "Dikmen", "Emek", "Gaziosmanpaşa", "Kavaklıdere", "Kızılay", "Kocatepe", "Maltepe", "Öveçler", "Ümitköy", "Yaşamkent" },
        ["Ankara|Keçiören"] = new() { "Atapark", "Bağlum", "Etlik", "Kalaba", "Karşıyaka", "Kuşcağız", "Ovacık", "Subayevleri", "Yakacık" },
        ["Ankara|Yenimahalle"] = new() { "Batıkent", "Demetevler", "Karşıyaka", "Macunköy", "Ostim", "Şentepe" },

        // İzmir
        ["İzmir|Bayraklı"] = new() { "Adalet", "Bayraklı", "Çiçek", "Gümüşpala", "Mansuroğlu", "Manavkuyu", "Onur", "Osmangazi", "Postacılar", "Salhane", "Selçuk", "Soğukkuyu", "Turan", "Yamanlar" },
        ["İzmir|Bornova"] = new() { "Altındağ", "Çamdibi", "Ergene", "Evka", "Işıkkent", "Kazımdirik", "Kemalpaşa", "Mevlana", "Naldöken", "Yeşilova" },
        ["İzmir|Karşıyaka"] = new() { "Aksoy", "Bahariye", "Bostanlı", "Çarşı", "Dedebaşı", "Donanmacı", "Latife Hanım", "Mavişehir", "Tersane", "Yalı" },
        ["İzmir|Konak"] = new() { "Alsancak", "Basmane", "Çankaya", "Güzelyalı", "Hatay", "Kahramanlar", "Kemeraltı", "Konak", "Küçükyalı", "Umurbey" },
    };

    // ─── Örnek Mahalle Verileri ───
    public static readonly Dictionary<string, List<string>> Mahalleler = new()
    {
        ["İstanbul|Kadıköy|Caferağa"] = new() { "Caferağa Mh.", "Moda Cad. Civarı", "Bahariye Civarı" },
        ["İstanbul|Kadıköy|Fenerbahçe"] = new() { "Fenerbahçe Mh.", "Dalyan Mh.", "Münir Nurettin Selçuk Cad. Civarı" },
        ["İstanbul|Kadıköy|Göztepe"] = new() { "Göztepe Mh.", "Merdivenköy Mh.", "Fahrettin Kerim Gökay Cad. Civarı" },
        ["İstanbul|Beşiktaş|Etiler"] = new() { "Etiler Mh.", "Nisbetiye Cad. Civarı", "Akatlar Sınırı" },
        ["İstanbul|Beşiktaş|Levent"] = new() { "Levent Mh.", "1. Levent", "2. Levent", "3. Levent", "4. Levent" },
        ["Ankara|Çankaya|Kızılay"] = new() { "Kızılay Mh.", "Kocatepe Mh.", "Meşrutiyet Mh." },
        ["Ankara|Çankaya|Çayyolu"] = new() { "Çayyolu Mh.", "Ümitköy Mh.", "Yaşamkent Mh.", "Koru Mh." },
        ["İzmir|Bayraklı|Gümüşpala"] = new() { "Gümüşpala Mh.", "Doğançay Mh.", "Emek Mh." },
        ["İzmir|Karşıyaka|Bostanlı"] = new() { "Bostanlı Mh.", "Tersane Mh.", "Bahariye Mh." },
        ["İzmir|Konak|Alsancak"] = new() { "Alsancak Mh.", "Kültür Mh.", "1. Kordon Civarı" },
    };
}
