import 'listing_enums.dart';
import '../data/category_data.dart';

class User {
  final String id;
  final String ad;
  final String soyad;
  final String email;
  final String telefon;
  final String rol;
  final bool onayli;
  final String? profilFotoUrl;

  User({
    required this.id,
    required this.ad,
    required this.soyad,
    required this.email,
    required this.telefon,
    required this.rol,
    required this.onayli,
    this.profilFotoUrl,
  });

  String get fullName => '$ad $soyad';

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] ?? '',
    ad: json['ad'] ?? '',
    soyad: json['soyad'] ?? '',
    email: json['email'] ?? '',
    telefon: json['telefon'] ?? '',
    rol: json['rol'] ?? 'kullanici',
    onayli: json['onayli'] ?? false,
    profilFotoUrl: json['profilFotoUrl'],
  );
}

/// Sahibinden-style listing model with all detailed fields
class Listing {
  final String id;
  final String emlakciId;
  
  // Temel Bilgiler
  final String baslik;
  final String aciklama;
  
  // Kategori
  final String kategori;
  final String altKategori;
  final String islemTipi;
  final String emlakTipi; // Legacy
  
  // Fiyat
  final double fiyat;
  
  // Ölçüler
  final int? brutMetrekare;
  final int? netMetrekare;
  final double? metrekare; // Legacy
  
  // Oda & Bina
  final String? odaSayisi;
  final String? binaYasi;
  final int? banyoSayisi;
  final int? bulunduguKat;
  final int? katSayisi;
  
  // Özellikler
  final String? isitmaTipi;
  final bool esyali;
  final bool balkon;
  final bool asansor;
  final bool otopark;
  final bool siteIcerisinde;
  final bool havuz;
  final bool guvenlik;
  
  // ================== YENİ ALANLAR ==================
  final String? mutfakTipi;
  final String? otoparkTipi;
  final String? kullanimDurumu;
  final String? konutTipi;
  final String? bulunduguKatStr;
  final String? videoUrl;
  
  // ================== İŞ YERİ ALANLARI ==================
  final double? girisYuksekligi;
  final bool? zeminEtudu;
  final bool? devren;
  final bool? kiracili;
  final String? yapininDurumu;
  
  // ================== ARSA ALANLARI ==================
  final String? adaParsel;
  final double? gabari;
  final double? kaksEmsal;
  final bool? katKarsiligi;
  final String? imarDurumu;
  
  // ================== ÖZELLİK LİSTELERİ ==================
  final List<String> manzara;
  final List<String> cephe;
  final List<String> ulasim;
  final List<String> muhit;
  final List<String> icOzellikler;
  final List<String> disOzellikler;
  final List<String> engelliyeUygunluk;
  
  // ================== PROMOSYON ==================
  final bool acilSatilik;
  final bool fiyatiDustu;
  
  // Satış Detayları
  final bool krediyeUygun;
  final bool takasli;
  final String? tapuDurumu;
  final String? kimden;
  
  // Konum
  final String il;
  final String ilce;
  final String? mahalle;
  final double? latitude;
  final double? longitude;
  
  // Medya & Durum
  final List<String> fotograflar;
  final List<String> blurHashler;
  final bool aktif;
  final int goruntulemeSayisi;
  final DateTime createdAt;

  Listing({
    required this.id,
    required this.emlakciId,
    required this.baslik,
    required this.aciklama,
    required this.kategori,
    required this.altKategori,
    required this.islemTipi,
    required this.emlakTipi,
    required this.fiyat,
    this.brutMetrekare,
    this.netMetrekare,
    this.metrekare,
    this.odaSayisi,
    this.binaYasi,
    this.banyoSayisi,
    this.bulunduguKat,
    this.katSayisi,
    this.isitmaTipi,
    this.esyali = false,
    this.balkon = false,
    this.asansor = false,
    this.otopark = false,
    this.siteIcerisinde = false,
    this.havuz = false,
    this.guvenlik = false,
    // Yeni alanlar
    this.mutfakTipi,
    this.otoparkTipi,
    this.kullanimDurumu,
    this.konutTipi,
    this.bulunduguKatStr,
    this.videoUrl,
    // İş Yeri alanları
    this.girisYuksekligi,
    this.zeminEtudu,
    this.devren,
    this.kiracili,
    this.yapininDurumu,
    // Arsa alanları
    this.adaParsel,
    this.gabari,
    this.kaksEmsal,
    this.katKarsiligi,
    this.imarDurumu,
    // Özellik listeleri
    this.manzara = const [],
    this.cephe = const [],
    this.ulasim = const [],
    this.muhit = const [],
    this.icOzellikler = const [],
    this.disOzellikler = const [],
    this.engelliyeUygunluk = const [],
    // Promosyon
    this.acilSatilik = false,
    this.fiyatiDustu = false,
    // Satış detayları
    this.krediyeUygun = false,
    this.takasli = false,
    this.tapuDurumu,
    this.kimden,
    required this.il,
    required this.ilce,
    this.mahalle,
    this.latitude,
    this.longitude,
    required this.fotograflar,
    this.blurHashler = const [],
    required this.aktif,
    required this.goruntulemeSayisi,
    required this.createdAt,
  });

  // Computed properties
  String get formattedPrice {
    if (fiyat >= 1000000) {
      return '${(fiyat / 1000000).toStringAsFixed(fiyat % 1000000 == 0 ? 0 : 1)} M TL';
    } else if (fiyat >= 1000) {
      return '${(fiyat / 1000).toStringAsFixed(0)} K TL';
    }
    return '${fiyat.toStringAsFixed(0)} TL';
  }
  
  String get location => '$ilce, $il';
  
  int get displayMetrekare => brutMetrekare ?? netMetrekare ?? metrekare?.toInt() ?? 0;
  
  String get islemTipiLabel => IslemTipi.fromString(islemTipi)?.label ?? islemTipi;
  
  String get kategoriLabel => Kategori.fromString(kategori)?.label ?? kategori;

  /// List of active boolean features for display
  List<ListingFeature> get activeFeatures {
    final features = <ListingFeature>[];
    if (esyali) features.add(ListingFeature.esyali);
    if (balkon) features.add(ListingFeature.balkon);
    if (asansor) features.add(ListingFeature.asansor);
    if (otopark) features.add(ListingFeature.otopark);
    if (siteIcerisinde) features.add(ListingFeature.siteIcerisinde);
    if (havuz) features.add(ListingFeature.havuz);
    if (guvenlik) features.add(ListingFeature.guvenlik);
    if (krediyeUygun) features.add(ListingFeature.krediyeUygun);
    if (takasli) features.add(ListingFeature.takasli);
    return features;
  }

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
    id: json['id'] ?? '',
    emlakciId: json['emlakciId'] ?? '',
    baslik: json['baslik'] ?? '',
    aciklama: json['aciklama'] ?? '',
    kategori: json['kategori'] ?? json['emlakTipi'] ?? '',
    altKategori: json['altKategori'] ?? '',
    islemTipi: json['islemTipi'] ?? '',
    emlakTipi: json['emlakTipi'] ?? json['kategori'] ?? '',
    fiyat: (json['fiyat'] ?? 0).toDouble(),
    brutMetrekare: json['brutMetrekare'],
    netMetrekare: json['netMetrekare'],
    metrekare: json['metrekare']?.toDouble(),
    odaSayisi: json['odaSayisi'],
    binaYasi: json['binaYasi'],
    banyoSayisi: json['banyoSayisi'],
    bulunduguKat: json['bulunduguKat'],
    katSayisi: json['katSayisi'],
    isitmaTipi: json['isitmaTipi'],
    esyali: json['esyali'] ?? false,
    balkon: json['balkon'] ?? false,
    asansor: json['asansor'] ?? false,
    otopark: json['otopark'] ?? false,
    siteIcerisinde: json['siteIcerisinde'] ?? false,
    havuz: json['havuz'] ?? false,
    guvenlik: json['guvenlik'] ?? false,
    // Yeni alanlar
    mutfakTipi: json['mutfakTipi'],
    otoparkTipi: json['otoparkTipi'],
    kullanimDurumu: json['kullanimDurumu'],
    konutTipi: json['konutTipi'],
    bulunduguKatStr: json['bulunduguKatStr'],
    videoUrl: json['videoUrl'],
    // İş Yeri alanları
    girisYuksekligi: json['girisYuksekligi']?.toDouble(),
    zeminEtudu: json['zeminEtudu'],
    devren: json['devren'],
    kiracili: json['kiracili'],
    yapininDurumu: json['yapininDurumu'],
    // Arsa alanları
    adaParsel: json['adaParsel'],
    gabari: json['gabari']?.toDouble(),
    kaksEmsal: json['kaksEmsal']?.toDouble(),
    katKarsiligi: json['katKarsiligi'],
    imarDurumu: json['imarDurumu'],
    // Özellik listeleri
    manzara: List<String>.from(json['manzara'] ?? []),
    cephe: List<String>.from(json['cephe'] ?? []),
    ulasim: List<String>.from(json['ulasim'] ?? []),
    muhit: List<String>.from(json['muhit'] ?? []),
    icOzellikler: List<String>.from(json['icOzellikler'] ?? []),
    disOzellikler: List<String>.from(json['disOzellikler'] ?? []),
    engelliyeUygunluk: List<String>.from(json['engelliyeUygunluk'] ?? []),
    // Promosyon
    acilSatilik: json['acilSatilik'] ?? false,
    fiyatiDustu: json['fiyatiDustu'] ?? false,
    // Satış detayları
    krediyeUygun: json['krediyeUygun'] ?? false,
    takasli: json['takasli'] ?? false,
    tapuDurumu: json['tapuDurumu'],
    kimden: json['kimden'],
    il: json['il'] ?? '',
    ilce: json['ilce'] ?? '',
    mahalle: json['mahalle'],
    latitude: json['latitude']?.toDouble(),
    longitude: json['longitude']?.toDouble(),
    fotograflar: List<String>.from(json['fotograflar'] ?? []),
    blurHashler: List<String>.from(json['blurHashler'] ?? []),
    aktif: json['aktif'] ?? true,
    goruntulemeSayisi: json['goruntulemeSayisi'] ?? 0,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'baslik': baslik,
    'aciklama': aciklama,
    'kategori': kategori,
    'altKategori': altKategori,
    'islemTipi': islemTipi,
    'fiyat': fiyat,
    'brutMetrekare': brutMetrekare,
    'netMetrekare': netMetrekare,
    'odaSayisi': odaSayisi,
    'binaYasi': binaYasi,
    'banyoSayisi': banyoSayisi,
    'bulunduguKat': bulunduguKat,
    'katSayisi': katSayisi,
    'isitmaTipi': isitmaTipi,
    'esyali': esyali,
    'balkon': balkon,
    'asansor': asansor,
    'otopark': otopark,
    'siteIcerisinde': siteIcerisinde,
    'havuz': havuz,
    'guvenlik': guvenlik,
    // Yeni alanlar
    'mutfakTipi': mutfakTipi,
    'otoparkTipi': otoparkTipi,
    'kullanimDurumu': kullanimDurumu,
    'konutTipi': konutTipi,
    'bulunduguKatStr': bulunduguKatStr,
    'videoUrl': videoUrl,
    // İş Yeri alanları
    'girisYuksekligi': girisYuksekligi,
    'zeminEtudu': zeminEtudu,
    'devren': devren,
    'kiracili': kiracili,
    'yapininDurumu': yapininDurumu,
    // Arsa alanları
    'adaParsel': adaParsel,
    'gabari': gabari,
    'kaksEmsal': kaksEmsal,
    'katKarsiligi': katKarsiligi,
    'imarDurumu': imarDurumu,
    // Özellik listeleri
    'manzara': manzara,
    'cephe': cephe,
    'ulasim': ulasim,
    'muhit': muhit,
    'icOzellikler': icOzellikler,
    'disOzellikler': disOzellikler,
    'engelliyeUygunluk': engelliyeUygunluk,
    // Promosyon
    'acilSatilik': acilSatilik,
    'fiyatiDustu': fiyatiDustu,
    // Satış detayları
    'krediyeUygun': krediyeUygun,
    'takasli': takasli,
    'tapuDurumu': tapuDurumu,
    'kimden': kimden,
    'il': il,
    'ilce': ilce,
    'mahalle': mahalle,
    'latitude': latitude,
    'longitude': longitude,
  };
}

/// Search filter request model for advanced filtering
class SearchFilter {
  String? query;
  String? kategori;
  String? altKategori;
  String? islemTipi;
  String? il;
  String? ilce;
  double? minFiyat;
  double? maxFiyat;
  int? minMetrekare;
  int? maxMetrekare;
  List<String>? odaSayilari;
  List<String>? binaYaslari;
  bool? esyali;
  bool? balkon;
  bool? asansor;
  bool? otopark;
  bool? siteIcerisinde;
  bool? havuz;
  bool? guvenlik;
  bool? krediyeUygun;
  String? kimden;
  // Yeni Sahibinden filtreleri
  List<String>? manzara;
  List<String>? cephe;
  bool? acilSatilik;
  bool? fiyatiDustu;
  // Yeni genişletilmiş filtreler
  String? siralama;
  String? mutfakTipi;
  String? otoparkTipi;
  String? kullanimDurumu;
  String? konutTipi;
  String? ilanTarihi;
  String? bulunduguKatStr;
  bool? takasli;
  String? isitmaTipi;
  List<String>? ulasim;
  List<String>? muhit;
  List<String>? icOzellikler;
  List<String>? disOzellikler;
  List<String>? engelliyeUygunluk;
  int? minBanyoSayisi;
  int? maxBanyoSayisi;
  int? minKatSayisi;
  int? maxKatSayisi;
  bool? videoVar;
  double? girisYuksekligiMin;
  double? girisYuksekligiMax;
  // Geo-BoundingBox for map-based search
  double? northEastLat;
  double? northEastLon;
  double? southWestLat;
  double? southWestLon;
  int skip;
  int limit;

  SearchFilter({
    this.query,
    this.kategori,
    this.altKategori,
    this.islemTipi,
    this.il,
    this.ilce,
    this.minFiyat,
    this.maxFiyat,
    this.minMetrekare,
    this.maxMetrekare,
    this.odaSayilari,
    this.binaYaslari,
    this.esyali,
    this.balkon,
    this.asansor,
    this.otopark,
    this.siteIcerisinde,
    this.havuz,
    this.guvenlik,
    this.krediyeUygun,
    this.kimden,
    this.manzara,
    this.cephe,
    this.acilSatilik,
    this.fiyatiDustu,
    // Yeni parametreler
    this.siralama,
    this.mutfakTipi,
    this.otoparkTipi,
    this.kullanimDurumu,
    this.konutTipi,
    this.ilanTarihi,
    this.bulunduguKatStr,
    this.takasli,
    this.isitmaTipi,
    this.ulasim,
    this.muhit,
    this.icOzellikler,
    this.disOzellikler,
    this.engelliyeUygunluk,
    this.minBanyoSayisi,
    this.maxBanyoSayisi,
    this.minKatSayisi,
    this.maxKatSayisi,
    this.videoVar,
    this.girisYuksekligiMin,
    this.girisYuksekligiMax,
    this.northEastLat,
    this.northEastLon,
    this.southWestLat,
    this.southWestLon,
    this.skip = 0,
    this.limit = 20,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'skip': skip,
      'limit': limit,
    };
    
    if (query != null && query!.isNotEmpty) map['query'] = query;
    if (kategori != null) map['kategori'] = kategori;
    if (altKategori != null) map['altKategori'] = altKategori;
    if (islemTipi != null) map['islemTipi'] = islemTipi;
    if (il != null) map['il'] = il;
    if (ilce != null) map['ilce'] = ilce;
    if (minFiyat != null) map['minFiyat'] = minFiyat;
    if (maxFiyat != null) map['maxFiyat'] = maxFiyat;
    if (minMetrekare != null) map['minMetrekare'] = minMetrekare;
    if (maxMetrekare != null) map['maxMetrekare'] = maxMetrekare;
    if (odaSayilari != null && odaSayilari!.isNotEmpty) map['odaSayilari'] = odaSayilari;
    if (binaYaslari != null && binaYaslari!.isNotEmpty) map['binaYaslari'] = binaYaslari;
    if (esyali == true) map['esyali'] = true;
    if (balkon == true) map['balkon'] = true;
    if (asansor == true) map['asansor'] = true;
    if (otopark == true) map['otopark'] = true;
    if (siteIcerisinde == true) map['siteIcerisinde'] = true;
    if (havuz == true) map['havuz'] = true;
    if (guvenlik == true) map['guvenlik'] = true;
    if (krediyeUygun == true) map['krediyeUygun'] = true;
    if (kimden != null) map['kimden'] = kimden;
    // Yeni filtreler
    if (manzara != null && manzara!.isNotEmpty) map['manzara'] = manzara;
    if (cephe != null && cephe!.isNotEmpty) map['cephe'] = cephe;
    if (acilSatilik == true) map['acilSatilik'] = true;
    if (fiyatiDustu == true) map['fiyatiDustu'] = true;
    // Genişletilmiş filtreler
    if (siralama != null) {
      final sortParams = SiralamaSecenekleri.getSortParams(siralama!);
      map['sortBy'] = sortParams['sortBy'];
      map['sortOrder'] = sortParams['sortOrder'];
    }
    if (mutfakTipi != null) map['mutfakTipi'] = mutfakTipi;
    if (otoparkTipi != null) map['otoparkTipi'] = otoparkTipi;
    if (kullanimDurumu != null) map['kullanimDurumu'] = kullanimDurumu;
    if (konutTipi != null) map['konutTipi'] = konutTipi;
    if (ilanTarihi != null) map['ilanTarihi'] = ilanTarihi;
    if (bulunduguKatStr != null) map['bulunduguKatStr'] = bulunduguKatStr;
    if (takasli == true) map['takasli'] = true;
    if (isitmaTipi != null) map['isitmaTipi'] = isitmaTipi;
    if (ulasim != null && ulasim!.isNotEmpty) map['ulasim'] = ulasim;
    if (muhit != null && muhit!.isNotEmpty) map['muhit'] = muhit;
    if (icOzellikler != null && icOzellikler!.isNotEmpty) map['icOzellikler'] = icOzellikler;
    if (disOzellikler != null && disOzellikler!.isNotEmpty) map['disOzellikler'] = disOzellikler;
    if (engelliyeUygunluk != null && engelliyeUygunluk!.isNotEmpty) map['engelliyeUygunluk'] = engelliyeUygunluk;
    if (minBanyoSayisi != null) map['minBanyoSayisi'] = minBanyoSayisi;
    if (maxBanyoSayisi != null) map['maxBanyoSayisi'] = maxBanyoSayisi;
    if (minKatSayisi != null) map['minKatSayisi'] = minKatSayisi;
    if (maxKatSayisi != null) map['maxKatSayisi'] = maxKatSayisi;
    if (videoVar == true) map['videoVar'] = true;
    if (girisYuksekligiMin != null) map['girisYuksekligiMin'] = girisYuksekligiMin;
    if (girisYuksekligiMax != null) map['girisYuksekligiMax'] = girisYuksekligiMax;
    // Geo-BoundingBox
    if (northEastLat != null) map['northEastLat'] = northEastLat;
    if (northEastLon != null) map['northEastLon'] = northEastLon;
    if (southWestLat != null) map['southWestLat'] = southWestLat;
    if (southWestLon != null) map['southWestLon'] = southWestLon;
    
    return map;
  }

  void reset() {
    query = null;
    kategori = null;
    altKategori = null;
    islemTipi = null;
    il = null;
    ilce = null;
    minFiyat = null;
    maxFiyat = null;
    minMetrekare = null;
    maxMetrekare = null;
    odaSayilari = null;
    binaYaslari = null;
    esyali = null;
    balkon = null;
    asansor = null;
    otopark = null;
    siteIcerisinde = null;
    havuz = null;
    guvenlik = null;
    krediyeUygun = null;
    kimden = null;
    manzara = null;
    cephe = null;
    acilSatilik = null;
    fiyatiDustu = null;
    // Yeni filtreler reset
    siralama = null;
    mutfakTipi = null;
    otoparkTipi = null;
    kullanimDurumu = null;
    konutTipi = null;
    ilanTarihi = null;
    bulunduguKatStr = null;
    takasli = null;
    isitmaTipi = null;
    ulasim = null;
    muhit = null;
    icOzellikler = null;
    disOzellikler = null;
    engelliyeUygunluk = null;
    minBanyoSayisi = null;
    maxBanyoSayisi = null;
    minKatSayisi = null;
    maxKatSayisi = null;
    videoVar = null;
    girisYuksekligiMin = null;
    girisYuksekligiMax = null;
    northEastLat = null;
    northEastLon = null;
    southWestLat = null;
    southWestLon = null;
    skip = 0;
    limit = 20;
  }

  int get activeFilterCount {
    int count = 0;
    if (query != null && query!.isNotEmpty) count++;
    if (kategori != null) count++;
    if (altKategori != null) count++;
    if (islemTipi != null) count++;
    if (il != null) count++;
    if (ilce != null) count++;
    if (minFiyat != null) count++;
    if (maxFiyat != null) count++;
    if (minMetrekare != null) count++;
    if (maxMetrekare != null) count++;
    if (odaSayilari != null && odaSayilari!.isNotEmpty) count++;
    if (binaYaslari != null && binaYaslari!.isNotEmpty) count++;
    if (esyali == true) count++;
    if (balkon == true) count++;
    if (asansor == true) count++;
    if (otopark == true) count++;
    if (siteIcerisinde == true) count++;
    if (havuz == true) count++;
    if (guvenlik == true) count++;
    if (krediyeUygun == true) count++;
    if (kimden != null) count++;
    if (manzara != null && manzara!.isNotEmpty) count++;
    if (cephe != null && cephe!.isNotEmpty) count++;
    if (acilSatilik == true) count++;
    if (fiyatiDustu == true) count++;
    // Yeni filtre sayaçları
    if (mutfakTipi != null) count++;
    if (otoparkTipi != null) count++;
    if (kullanimDurumu != null) count++;
    if (konutTipi != null) count++;
    if (ilanTarihi != null) count++;
    if (bulunduguKatStr != null) count++;
    if (takasli == true) count++;
    if (isitmaTipi != null) count++;
    if (ulasim != null && ulasim!.isNotEmpty) count++;
    if (muhit != null && muhit!.isNotEmpty) count++;
    if (icOzellikler != null && icOzellikler!.isNotEmpty) count++;
    if (disOzellikler != null && disOzellikler!.isNotEmpty) count++;
    if (engelliyeUygunluk != null && engelliyeUygunluk!.isNotEmpty) count++;
    if (videoVar == true) count++;
    return count;
  }
}
