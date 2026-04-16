import 'dart:io';
import 'package:flutter/foundation.dart';

/// Taslak ilan verisi — wizard ekranları arasında paylaşılır
class DraftListing {
  // Ekran 1: Kategori
  String? kategoriId;
  String? kategoriLabel;

  // Ekran 2: İşlem Tipi
  String? islemTipiId;
  String? islemTipiLabel;

  // Ekran 3: Alt Kategori
  String? altKategori;

  // Ekran 4: Adres
  String? il;
  String? ilce;
  String? semt;
  String? mahalle;
  bool siteIcerisinde = false;
  String? siteAdi;

  // Harita
  double? latitude;
  double? longitude;

  // Ekran 5: Detaylar
  String? baslik;
  String? aciklama;
  double? fiyat;
  int? brutMetrekare;
  int? netMetrekare;
  String? odaSayisi;
  String? binaYasi;
  String? isitmaTipi;
  String? tapuDurumu;
  String? kimden;
  int? bulunduguKat;
  int? katSayisi;
  int? banyoSayisi;

  // Özellikler
  bool esyali = false;
  bool balkon = false;
  bool asansor = false;
  bool otopark = false;
  bool havuz = false;
  bool guvenlik = false;
  bool krediyeUygun = false;
  bool takasli = false;

  // İş Yeri Özel
  double? girisYuksekligi;
  bool zeminEtudu = false;
  bool devren = false;
  bool kiracili = false;
  String? yapininDurumu;

  // Arsa Özel
  String? adaParsel;
  String? gabari;
  String? kaksEmsal;
  bool katKarsiligi = false;
  String? imarDurumu;

  // Çoklu Seçimler
  Set<String> manzara = {};
  Set<String> cephe = {};
  Set<String> ulasim = {};
  Set<String> muhit = {};
  Set<String> icOzellikler = {};
  Set<String> disOzellikler = {};
  Set<String> engelliye = {};

  // Promosyon
  bool acilSatilik = false;
  bool fiyatiDustu = false;

  // Medya
  List<File> images = [];
  List<String> uploadedImageUrls = [];

  /// Breadcrumb oluşturur (AppBar için)
  String get breadcrumb {
    final parts = <String>['Kategoriler', 'Emlak'];
    if (kategoriLabel != null) parts.add(kategoriLabel!);
    if (islemTipiLabel != null) parts.add(islemTipiLabel!);
    if (altKategori != null) parts.add(altKategori!);
    return parts.join(' > ');
  }

  /// Adres özet metni
  String get adresOzet {
    final parts = <String>[];
    if (mahalle != null) parts.add(mahalle!);
    if (semt != null) parts.add(semt!);
    if (ilce != null) parts.add(ilce!);
    if (il != null) parts.add(il!);
    return parts.join(', ');
  }

  /// Tüm verileri JSON'a çevirir (API submit için)
  Map<String, dynamic> toJson() {
    return {
      'kategori': kategoriId,
      'altKategori': altKategori,
      'islemTipi': islemTipiId,
      'il': il,
      'ilce': ilce,
      'semt': semt,
      'mahalle': mahalle,
      'siteIcerisinde': siteIcerisinde,
      if (siteAdi != null) 'siteAdi': siteAdi,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'baslik': baslik,
      'aciklama': aciklama,
      'fiyat': fiyat,
      if (brutMetrekare != null) 'brutMetrekare': brutMetrekare,
      if (netMetrekare != null) 'netMetrekare': netMetrekare,
      if (odaSayisi != null) 'odaSayisi': odaSayisi,
      if (binaYasi != null) 'binaYasi': binaYasi,
      if (isitmaTipi != null) 'isitmaTipi': isitmaTipi,
      if (tapuDurumu != null) 'tapuDurumu': tapuDurumu,
      if (kimden != null) 'kimden': kimden,
      if (bulunduguKat != null) 'bulunduguKat': bulunduguKat,
      if (katSayisi != null) 'katSayisi': katSayisi,
      if (banyoSayisi != null) 'banyoSayisi': banyoSayisi,
      'esyali': esyali,
      'balkon': balkon,
      'asansor': asansor,
      'otopark': otopark,
      'havuz': havuz,
      'guvenlik': guvenlik,
      'krediyeUygun': krediyeUygun,
      'takasli': takasli,
      if (girisYuksekligi != null) 'girisYuksekligi': girisYuksekligi,
      'zeminEtudu': zeminEtudu,
      'devren': devren,
      'kiracili': kiracili,
      if (yapininDurumu != null) 'yapininDurumu': yapininDurumu,
      if (adaParsel != null) 'adaParsel': adaParsel,
      if (gabari != null) 'gabari': gabari,
      if (kaksEmsal != null) 'kaksEmsal': kaksEmsal,
      'katKarsiligi': katKarsiligi,
      if (imarDurumu != null) 'imarDurumu': imarDurumu,
      if (manzara.isNotEmpty) 'manzara': manzara.toList(),
      if (cephe.isNotEmpty) 'cephe': cephe.toList(),
      if (ulasim.isNotEmpty) 'ulasim': ulasim.toList(),
      if (muhit.isNotEmpty) 'muhit': muhit.toList(),
      if (icOzellikler.isNotEmpty) 'icOzellikler': icOzellikler.toList(),
      if (disOzellikler.isNotEmpty) 'disOzellikler': disOzellikler.toList(),
      if (engelliye.isNotEmpty) 'engelliyeUygunluk': engelliye.toList(),
      'acilSatilik': acilSatilik,
      'fiyatiDustu': fiyatiDustu,
      if (uploadedImageUrls.isNotEmpty) 'fotograflar': uploadedImageUrls,
    };
  }

  /// Tüm taslağı sıfırlar
  void reset() {
    kategoriId = null;
    kategoriLabel = null;
    islemTipiId = null;
    islemTipiLabel = null;
    altKategori = null;
    il = null;
    ilce = null;
    semt = null;
    mahalle = null;
    siteIcerisinde = false;
    siteAdi = null;
    latitude = null;
    longitude = null;
    baslik = null;
    aciklama = null;
    fiyat = null;
    brutMetrekare = null;
    netMetrekare = null;
    odaSayisi = null;
    binaYasi = null;
    isitmaTipi = null;
    tapuDurumu = null;
    kimden = null;
    bulunduguKat = null;
    katSayisi = null;
    banyoSayisi = null;
    esyali = false;
    balkon = false;
    asansor = false;
    otopark = false;
    havuz = false;
    guvenlik = false;
    krediyeUygun = false;
    takasli = false;
    girisYuksekligi = null;
    zeminEtudu = false;
    devren = false;
    kiracili = false;
    yapininDurumu = null;
    adaParsel = null;
    gabari = null;
    kaksEmsal = null;
    katKarsiligi = false;
    imarDurumu = null;
    manzara = {};
    cephe = {};
    ulasim = {};
    muhit = {};
    icOzellikler = {};
    disOzellikler = {};
    engelliye = {};
    acilSatilik = false;
    fiyatiDustu = false;
    images = [];
    uploadedImageUrls = [];
  }
}

/// Global state provider for draft listing wizard
class DraftListingProvider extends ChangeNotifier {
  final DraftListing _draft = DraftListing();

  DraftListing get draft => _draft;

  // ─── Ekran 1: Kategori ───
  void setKategori(String id, String label) {
    _draft.kategoriId = id;
    _draft.kategoriLabel = label;
    // Alt seçimleri sıfırla
    _draft.islemTipiId = null;
    _draft.islemTipiLabel = null;
    _draft.altKategori = null;
    notifyListeners();
  }

  // ─── Ekran 2: İşlem Tipi ───
  void setIslemTipi(String id, String label) {
    _draft.islemTipiId = id;
    _draft.islemTipiLabel = label;
    _draft.altKategori = null;
    notifyListeners();
  }

  // ─── Ekran 3: Alt Kategori ───
  void setAltKategori(String altKategori) {
    _draft.altKategori = altKategori;
    notifyListeners();
  }

  // ─── Ekran 4: Adres ───
  void setIl(String il) {
    _draft.il = il;
    _draft.ilce = null;
    _draft.semt = null;
    _draft.mahalle = null;
    notifyListeners();
  }

  void setIlce(String ilce) {
    _draft.ilce = ilce;
    _draft.semt = null;
    _draft.mahalle = null;
    notifyListeners();
  }

  void setSemt(String semt) {
    _draft.semt = semt;
    _draft.mahalle = null;
    notifyListeners();
  }

  void setMahalle(String mahalle) {
    _draft.mahalle = mahalle;
    notifyListeners();
  }

  void setSiteIcerisinde(bool value) {
    _draft.siteIcerisinde = value;
    notifyListeners();
  }

  // ─── Harita ───
  void setKoordinat(double lat, double lng) {
    _draft.latitude = lat;
    _draft.longitude = lng;
    notifyListeners();
  }

  // ─── Tam sıfırlama ───
  void resetDraft() {
    _draft.reset();
    notifyListeners();
  }
}
