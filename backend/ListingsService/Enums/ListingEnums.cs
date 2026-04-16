namespace ListingsService.Enums;

/// <summary>
/// Comprehensive enum definitions for Sahibinden-style real estate platform
/// Türkçe karakter uyumlu enum yapıları
/// </summary>

// ==================== KATEGORİK ENUMLAR ====================

/// <summary>
/// Konut tipleri - Residential property types
/// </summary>
public enum KonutTipi
{
    Daire,
    Rezidans,
    MustakilEv,
    Villa,
    CiftlikEvi,
    KoskKonak,
    Yali,
    YaliDairesi,
    Yazlik,
    Kooperatif
}

/// <summary>
/// İş yeri tipleri - Commercial property types
/// </summary>
public enum IsYeriTipi
{
    Atolye,
    AVM,
    BuroOfis,
    Ciftlik,
    Depo,
    DukkanMagaza,
    Fabrika,
    Imalathane,
    KafeBar,
    KompleBina,
    MadenOcagi,
    Otopark,
    Plaza,
    Restoran,
    SpaHamam,
    TuristikTesis,
    AkaryakitIstasyonu
}

/// <summary>
/// Arsa imar durumları - Land zoning types
/// </summary>
public enum ArsaImarDurumu
{
    Konut,
    Ticari,
    Sanayi,
    Tarla,
    BagBahce,
    Zeytinlik,
    SitAlani
}

// ==================== ÖZELLİK ENUMLARI ====================

/// <summary>
/// Manzara seçenekleri - View options
/// </summary>
public enum Manzara
{
    Bogaz,
    Deniz,
    Doga,
    Gol,
    Havuz,
    Nehir,
    ParkYesilAlan,
    Sehir
}

/// <summary>
/// Cephe yönleri - Facade directions
/// </summary>
public enum Cephe
{
    Kuzey,
    Guney,
    Dogu,
    Bati,
    Kuzeydogu,
    Kuzeybati,
    Guneydogu,
    Guneybati
}

/// <summary>
/// Ulaşım seçenekleri - Transportation options
/// </summary>
public enum Ulasim
{
    Anayol,
    AvrasyaTuneli,
    BogazKopruleri,
    Metro,
    Metrobus,
    Marmaray,
    Tramvay,
    Teleferik,
    Iskele,
    Havaalani
}

/// <summary>
/// Muhit özellikleri - Neighborhood features
/// </summary>
public enum Muhit
{
    AVM,
    Belediye,
    Cami,
    Cemevi,
    Hastane,
    Okul,
    Universite,
    Adliye,
    SemtPazari
}

/// <summary>
/// Yapının durumu - Building condition
/// </summary>
public enum YapininDurumu
{
    IkinciEl,
    Sifir,
    YapimAsamasinda
}

// ==================== İÇ ÖZELLİKLER ====================

/// <summary>
/// İç özellikler - Interior features for residential
/// </summary>
public enum IcOzellik
{
    ADSL,
    AhsapDograma,
    AkilliEv,
    Alarm,
    AluminyumDograma,
    AmericanKapı,
    AmericanMutfak,
    Ankastre,
    BarbekuAlani,
    Beyaz_Esya,
    CelikKapi,
    DusakaKabin,
    Ebeveyn_Banyosu,
    Fiber_Optik,
    Giyinme_Odasi,
    GomuluDolap,
    Goruntulu_Diafon,
    Hilton_Banyo,
    Isicam,
    Jakuzi,
    Kablo_TV,
    Kartonpiyer,
    Kiler,
    Klima,
    Laminant_Zemin,
    Marley,
    Mobilya,
    Mutfak_Ankastre,
    PVC_Dograma,
    Parke,
    Seramik_Zemin,
    Set_Ustu_Ocak,
    Somine,
    Spot_Aydinlatma,
    Teras,
    Vestiyer,
    WI_FI,
    Yuz_Tanima
}

/// <summary>
/// Dış özellikler - Exterior features
/// </summary>
public enum DisOzellik
{
    AracSarjIstasyonu,
    Bekci,
    Garaj,
    Guvenlik,
    Hidrofor,
    Jenerator,
    Kapici,
    KapalıGaraj,
    Mantolama,
    Muhafız,
    OyunParki,
    PVCDograma,
    SitIci,
    SosyalTesis,
    SuDeposu,
    SuzmeHavuz,
    TenisKortu,
    YanginMerdiveni,
    YuzmeHavuzu,
    Yurume_Yolu
}

/// <summary>
/// Engelliye uygunluk seçenekleri - Accessibility features
/// </summary>
public enum EngelliyeUygunluk
{
    GenisKoridor,
    AsansorUygun,
    BanyoTutamagi,
    Rampa,
    AlcakMutfakTezgahi,
    OtoKapi,
    SesliIkaz,
    ZeminKat
}

// ==================== İŞ YERİ ÖZELLİKLERİ ====================

/// <summary>
/// İş yeri özellikleri - Commercial property features
/// </summary>
public enum IsYeriOzellik
{
    Buzhane,
    Gıda_Ruhsati,
    KablosuzInternet,
    Mutfak,
    Ofis,
    OtoKapi,
    SogukHava_Deposu,
    Tuvalet,
    Vitrin,
    WC_Lavabo,
    YanginCikisi,
    Rampa,
    Vinc,
    YukAsansoru
}

// ==================== HELPER METHODS ====================

/// <summary>
/// Enum label helper for Turkish display names
/// </summary>
public static class EnumLabels
{
    public static string GetLabel(KonutTipi tip) => tip switch
    {
        KonutTipi.Daire => "Daire",
        KonutTipi.Rezidans => "Rezidans",
        KonutTipi.MustakilEv => "Müstakil Ev",
        KonutTipi.Villa => "Villa",
        KonutTipi.CiftlikEvi => "Çiftlik Evi",
        KonutTipi.KoskKonak => "Köşk & Konak",
        KonutTipi.Yali => "Yalı",
        KonutTipi.YaliDairesi => "Yalı Dairesi",
        KonutTipi.Yazlik => "Yazlık",
        KonutTipi.Kooperatif => "Kooperatif",
        _ => tip.ToString()
    };

    public static string GetLabel(IsYeriTipi tip) => tip switch
    {
        IsYeriTipi.Atolye => "Atölye",
        IsYeriTipi.AVM => "AVM",
        IsYeriTipi.BuroOfis => "Büro & Ofis",
        IsYeriTipi.Ciftlik => "Çiftlik",
        IsYeriTipi.Depo => "Depo",
        IsYeriTipi.DukkanMagaza => "Dükkan & Mağaza",
        IsYeriTipi.Fabrika => "Fabrika",
        IsYeriTipi.Imalathane => "İmalathane",
        IsYeriTipi.KafeBar => "Kafe & Bar",
        IsYeriTipi.KompleBina => "Komple Bina",
        IsYeriTipi.MadenOcagi => "Maden Ocağı",
        IsYeriTipi.Otopark => "Otopark",
        IsYeriTipi.Plaza => "Plaza",
        IsYeriTipi.Restoran => "Restoran",
        IsYeriTipi.SpaHamam => "Spa & Hamam",
        IsYeriTipi.TuristikTesis => "Turistik Tesis",
        IsYeriTipi.AkaryakitIstasyonu => "Akaryakıt İstasyonu",
        _ => tip.ToString()
    };

    public static string GetLabel(ArsaImarDurumu imar) => imar switch
    {
        ArsaImarDurumu.Konut => "Konut İmarlı",
        ArsaImarDurumu.Ticari => "Ticari İmarlı",
        ArsaImarDurumu.Sanayi => "Sanayi İmarlı",
        ArsaImarDurumu.Tarla => "Tarla",
        ArsaImarDurumu.BagBahce => "Bağ & Bahçe",
        ArsaImarDurumu.Zeytinlik => "Zeytinlik",
        ArsaImarDurumu.SitAlani => "Sit Alanı",
        _ => imar.ToString()
    };

    public static string GetLabel(Manzara manzara) => manzara switch
    {
        Manzara.Bogaz => "Boğaz",
        Manzara.Deniz => "Deniz",
        Manzara.Doga => "Doğa",
        Manzara.Gol => "Göl",
        Manzara.Havuz => "Havuz",
        Manzara.Nehir => "Nehir",
        Manzara.ParkYesilAlan => "Park & Yeşil Alan",
        Manzara.Sehir => "Şehir",
        _ => manzara.ToString()
    };

    public static string GetLabel(Cephe cephe) => cephe switch
    {
        Cephe.Kuzey => "Kuzey",
        Cephe.Guney => "Güney",
        Cephe.Dogu => "Doğu",
        Cephe.Bati => "Batı",
        Cephe.Kuzeydogu => "Kuzeydoğu",
        Cephe.Kuzeybati => "Kuzeybatı",
        Cephe.Guneydogu => "Güneydoğu",
        Cephe.Guneybati => "Güneybatı",
        _ => cephe.ToString()
    };

    public static string GetLabel(Ulasim ulasim) => ulasim switch
    {
        Ulasim.Anayol => "Anayol",
        Ulasim.AvrasyaTuneli => "Avrasya Tüneli",
        Ulasim.BogazKopruleri => "Boğaz Köprüleri",
        Ulasim.Metro => "Metro",
        Ulasim.Metrobus => "Metrobüs",
        Ulasim.Marmaray => "Marmaray",
        Ulasim.Tramvay => "Tramvay",
        Ulasim.Teleferik => "Teleferik",
        Ulasim.Iskele => "İskele",
        Ulasim.Havaalani => "Havaalanı",
        _ => ulasim.ToString()
    };

    public static string GetLabel(Muhit muhit) => muhit switch
    {
        Muhit.AVM => "AVM",
        Muhit.Belediye => "Belediye",
        Muhit.Cami => "Cami",
        Muhit.Cemevi => "Cemevi",
        Muhit.Hastane => "Hastane",
        Muhit.Okul => "Okul",
        Muhit.Universite => "Üniversite",
        Muhit.Adliye => "Adliye",
        Muhit.SemtPazari => "Semt Pazarı",
        _ => muhit.ToString()
    };

    public static string GetLabel(YapininDurumu durum) => durum switch
    {
        YapininDurumu.IkinciEl => "İkinci El",
        YapininDurumu.Sifir => "Sıfır",
        YapininDurumu.YapimAsamasinda => "Yapım Aşamasında",
        _ => durum.ToString()
    };

    public static string GetLabel(IcOzellik ozellik) => ozellik switch
    {
        IcOzellik.ADSL => "ADSL",
        IcOzellik.AhsapDograma => "Ahşap Doğrama",
        IcOzellik.AkilliEv => "Akıllı Ev",
        IcOzellik.Alarm => "Alarm",
        IcOzellik.AluminyumDograma => "Alüminyum Doğrama",
        IcOzellik.AmericanKapı => "Amerikan Kapı",
        IcOzellik.AmericanMutfak => "Amerikan Mutfak",
        IcOzellik.Ankastre => "Ankastre",
        IcOzellik.BarbekuAlani => "Barbekü Alanı",
        IcOzellik.Beyaz_Esya => "Beyaz Eşya",
        IcOzellik.CelikKapi => "Çelik Kapı",
        IcOzellik.DusakaKabin => "Duşakabin",
        IcOzellik.Ebeveyn_Banyosu => "Ebeveyn Banyosu",
        IcOzellik.Fiber_Optik => "Fiber Optik",
        IcOzellik.Giyinme_Odasi => "Giyinme Odası",
        IcOzellik.GomuluDolap => "Gömülü Dolap",
        IcOzellik.Goruntulu_Diafon => "Görüntülü Diafon",
        IcOzellik.Hilton_Banyo => "Hilton Banyo",
        IcOzellik.Isicam => "Isıcam",
        IcOzellik.Jakuzi => "Jakuzi",
        IcOzellik.Kablo_TV => "Kablo TV",
        IcOzellik.Kartonpiyer => "Kartonpiyer",
        IcOzellik.Kiler => "Kiler",
        IcOzellik.Klima => "Klima",
        IcOzellik.Laminant_Zemin => "Laminant Zemin",
        IcOzellik.Marley => "Marley",
        IcOzellik.Mobilya => "Mobilya",
        IcOzellik.Mutfak_Ankastre => "Mutfak Ankastre",
        IcOzellik.PVC_Dograma => "PVC Doğrama",
        IcOzellik.Parke => "Parke",
        IcOzellik.Seramik_Zemin => "Seramik Zemin",
        IcOzellik.Set_Ustu_Ocak => "Set Üstü Ocak",
        IcOzellik.Somine => "Şömine",
        IcOzellik.Spot_Aydinlatma => "Spot Aydınlatma",
        IcOzellik.Teras => "Teras",
        IcOzellik.Vestiyer => "Vestiyer",
        IcOzellik.WI_FI => "Wi-Fi",
        IcOzellik.Yuz_Tanima => "Yüz Tanıma",
        _ => ozellik.ToString()
    };

    public static string GetLabel(DisOzellik ozellik) => ozellik switch
    {
        DisOzellik.AracSarjIstasyonu => "Araç Şarj İstasyonu",
        DisOzellik.Bekci => "Bekçi",
        DisOzellik.Garaj => "Garaj",
        DisOzellik.Guvenlik => "Güvenlik",
        DisOzellik.Hidrofor => "Hidrofor",
        DisOzellik.Jenerator => "Jeneratör",
        DisOzellik.Kapici => "Kapıcı",
        DisOzellik.KapalıGaraj => "Kapalı Garaj",
        DisOzellik.Mantolama => "Mantolama",
        DisOzellik.Muhafız => "Muhafız",
        DisOzellik.OyunParki => "Oyun Parkı",
        DisOzellik.PVCDograma => "PVC Doğrama",
        DisOzellik.SitIci => "Site İçi",
        DisOzellik.SosyalTesis => "Sosyal Tesis",
        DisOzellik.SuDeposu => "Su Deposu",
        DisOzellik.SuzmeHavuz => "Süzme Havuz",
        DisOzellik.TenisKortu => "Tenis Kortu",
        DisOzellik.YanginMerdiveni => "Yangın Merdiveni",
        DisOzellik.YuzmeHavuzu => "Yüzme Havuzu",
        DisOzellik.Yurume_Yolu => "Yürüme Yolu",
        _ => ozellik.ToString()
    };

    public static string GetLabel(EngelliyeUygunluk ozellik) => ozellik switch
    {
        EngelliyeUygunluk.GenisKoridor => "Geniş Koridor",
        EngelliyeUygunluk.AsansorUygun => "Engelli Asansörü",
        EngelliyeUygunluk.BanyoTutamagi => "Banyo Tutamağı",
        EngelliyeUygunluk.Rampa => "Rampa",
        EngelliyeUygunluk.AlcakMutfakTezgahi => "Alçak Mutfak Tezgahı",
        EngelliyeUygunluk.OtoKapi => "Otomatik Kapı",
        EngelliyeUygunluk.SesliIkaz => "Sesli İkaz",
        EngelliyeUygunluk.ZeminKat => "Zemin Kat",
        _ => ozellik.ToString()
    };
}
