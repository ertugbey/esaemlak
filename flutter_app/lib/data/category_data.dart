/// Sahibinden.com standartlarında kategori hiyerarşisi ve dinamik filtre kuralları
/// Bu dosya tüm kategori ağacını, işlem tiplerini, alt kategorileri ve
/// filtre profillerini merkezi olarak tanımlar.
library category_data;

// ==================== KATEGORİ HİYERARŞİSİ ====================

/// Ana kategori tanımları (7 ana kategori)
class KategoriTanimlari {
  static const List<Map<String, dynamic>> anaKategoriler = [
    {'id': 'konut', 'label': 'Konut', 'icon': 'home'},
    {'id': 'isyeri', 'label': 'İş Yeri', 'icon': 'business'},
    {'id': 'arsa', 'label': 'Arsa', 'icon': 'landscape'},
    {'id': 'konutProjeleri', 'label': 'Konut Projeleri', 'icon': 'apartment'},
    {'id': 'bina', 'label': 'Bina', 'icon': 'domain'},
    {'id': 'devreMulk', 'label': 'Devre Mülk', 'icon': 'villa'},
    {'id': 'turistikTesis', 'label': 'Turistik Tesis', 'icon': 'hotel'},
  ];
}

/// Kategoriye göre işlem tipleri
class IslemTipleri {
  static const Map<String, List<Map<String, String>>> kategoriIslemTipleri = {
    'konut': [
      {'id': 'satilik', 'label': 'Satılık'},
      {'id': 'kiralik', 'label': 'Kiralık'},
      {'id': 'turistikGunlukKiralik', 'label': 'Turistik Günlük Kiralık'},
      {'id': 'devrenSatilik', 'label': 'Devren Satılık Konut'},
    ],
    'isyeri': [
      {'id': 'satilik', 'label': 'Satılık'},
      {'id': 'kiralik', 'label': 'Kiralık'},
      {'id': 'devrenSatilik', 'label': 'Devren Satılık'},
      {'id': 'devrenKiralik', 'label': 'Devren Kiralık'},
    ],
    'arsa': [
      {'id': 'katKarsiligiSatilik', 'label': 'Kat Karşılığı Satılık'},
      {'id': 'satilik', 'label': 'Satılık'},
      {'id': 'kiralik', 'label': 'Kiralık'},
    ],
    'konutProjeleri': [
      {'id': 'satilik', 'label': 'Satılık'},
    ],
    'bina': [
      {'id': 'satilik', 'label': 'Satılık'},
      {'id': 'kiralik', 'label': 'Kiralık'},
    ],
    'devreMulk': [
      {'id': 'satilik', 'label': 'Satılık'},
      {'id': 'kiralik', 'label': 'Kiralık'},
    ],
    'turistikTesis': [
      {'id': 'satilik', 'label': 'Satılık'},
      {'id': 'kiralik', 'label': 'Kiralık'},
    ],
  };
}

/// Kategori + İşlem Tipi'ne göre alt kategoriler
class AltKategoriler {
  // ==================== KONUT ====================
  static const List<String> konutSatilik = [
    'Daire', 'Rezidans', 'Müstakil Ev', 'Villa', 'Çiftlik Evi',
    'Köşk & Konak', 'Yalı', 'Yalı Dairesi', 'Yazlık', 'Kooperatif',
  ];

  static const List<String> konutKiralik = [
    'Daire', 'Rezidans', 'Müstakil Ev', 'Villa', 'Çiftlik Evi',
    'Köşk & Konak', 'Yalı', 'Yalı Dairesi',
  ];

  static const List<String> konutTuristikGunlukKiralik = [
    'Daire', 'Rezidans', 'Müstakil Ev', 'Villa', 'Devre Mülk', 'Apart & Pansiyon',
  ];

  static const List<String> konutDevrenSatilik = [
    'Daire', 'Villa',
  ];

  // ==================== İŞ YERİ ====================
  static const List<String> isyeriSatilikKiralik = [
    'Akaryakıt İstasyonu', 'Apartman Dairesi', 'Atölye', 'AVM', 'Büfe',
    'Büro & Ofis', 'Çiftlik', 'Depo & Antrepo', 'Düğün Salonu',
    'Dükkan & Mağaza', 'Enerji Santrali', 'Fabrika & Üretim Tesisi',
    'Garaj & Park Yeri', 'İmalathane', 'İş Hanı Katı & Ofisi',
    'Kafe & Bar', 'Kantin', 'Kır & Kahvaltı Bahçesi', 'Kıraathane',
    'Komple Bina', 'Maden Ocağı', 'Otopark & Garaj', 'Oto Yıkama & Kuaför',
    'Pastane-Fırın & Tatlıcı', 'Pazar Yeri', 'Plaza', 'Plaza Katı & Ofisi',
    'Radyo İstasyonu & TV Kanalı', 'Restoran & Lokanta',
    'Rezidans Katı & Ofisi', 'Sağlık Merkezi', 'Sinema & Konferans Salonu',
    'SPA-Hamam & Sauna', 'Spor Tesisi', 'Villa', 'Yurt',
  ];

  static const List<String> isyeriDevrenSatilikKiralik = [
    'Acente', 'Akaryakıt İstasyonu', 'Aktar & Baharatçı', 'Anaokulu & Kreş',
    'Apartman Dairesi', 'Araç Showroom & Servis', 'Atölye', 'AVM Standı',
    'Balıkçı', 'Bar', 'Bijuteri', 'Börekçi', 'Büfe', 'Büro & Ofis',
    'Cep Telefonu Dükkanı', 'Çamaşırhane', 'Çay Ocağı', 'Çiçekçi & Fidanlık',
    'Çiftlik', 'Depo & Antrepo', 'Düğün Salonu', 'Dükkan & Mağaza',
    'Eczane & Medikal', 'Elektrikçi & Hırdavatçı', 'Elektronik Mağazası',
    'Enerji Santrali', 'Etkinlik & Performans Salonu', 'Fabrika & Üretim Tesisi',
    'Fotoğraf Stüdyosu', 'Gece Kulübü & Disko', 'Giyim Mağazası', 'Gözlükçü',
    'Halı Yıkama', 'Huzur Evi', 'İmalathane', 'İnternet & Oyun Kafe',
    'İş Hanı', 'İş Hanı Katı & Ofisi', 'Kafe', 'Kantin', 'Kasap',
    'Kır & Kahvaltı Bahçesi', 'Kıraathane', 'Kırtasiye', 'Kozmetik Mağazası',
    'Kuaför & Güzellik Merkezi', 'Kurs & Eğitim Merkezi', 'Kuru Temizleme',
    'Kuruyemişçi', 'Kuyumcu', 'Lunapark', 'Maden Ocağı', 'Manav', 'Market',
    'Matbaa', 'Modaevi', 'Muayenehane', 'Nakliyat & Kargo', 'Nalbur',
    'Okul & Kurs', 'Otopark / Garaj', 'Oto Servis & Bakım', 'Oto Yedek Parça',
    'Oto Yıkama & Kuaför', 'Öğrenci Yurdu', 'Pastane-Fırın & Tatlıcı',
    'Pazar Yeri', 'Pet Shop', 'Plaza Katı & Ofisi',
    'Radyo İstasyonu & TV Kanalı', 'Restoran & Lokanta',
    'Rezidans Katı & Ofisi', 'Sağlık Merkezi', 'Sebze & Meyve Hali',
    'Sinema & Konferans Salonu', 'Soğuk Hava Deposu', 'SPA-Hamam & Sauna',
    'Spor Tesisi', 'Su & Tüp Bayi', 'Şans Oyunları Bayisi', 'Şarküteri',
    'Taksi Durağı', 'Tamirhane', 'Tekel Bayi', 'Teknik Servis', 'Terzi',
    'Tuhafiye', 'Veteriner', 'Züccaciye',
  ];

  // ==================== ARSA ====================
  // Arsa'nın özel alt kategorisi yoktur (işlem tipi yeterli)

  // ==================== KONUT PROJELERİ ====================
  static const List<String> konutProjeleri = [
    'Daire', 'Residence', 'Villa',
  ];

  // ==================== BİNA / DEVRE MÜLK / TURİSTİK TESİS ====================
  // Bu kategorilerin alt kategorisi yoktur (sadece işlem tipi seçilir)

  /// Verilen kategori ve işlem tipine göre alt kategori listesi döndürür
  static List<String> getAltKategoriler(String kategori, String islemTipi) {
    switch (kategori) {
      case 'konut':
        switch (islemTipi) {
          case 'satilik':
            return konutSatilik;
          case 'kiralik':
            return konutKiralik;
          case 'turistikGunlukKiralik':
            return konutTuristikGunlukKiralik;
          case 'devrenSatilik':
            return konutDevrenSatilik;
          default:
            return konutSatilik;
        }
      case 'isyeri':
        switch (islemTipi) {
          case 'satilik':
          case 'kiralik':
            return isyeriSatilikKiralik;
          case 'devrenSatilik':
          case 'devrenKiralik':
            return isyeriDevrenSatilikKiralik;
          default:
            return isyeriSatilikKiralik;
        }
      case 'konutProjeleri':
        return konutProjeleri;
      // Arsa, Bina, Devre Mülk, Turistik Tesis alt kategorisi yok
      default:
        return [];
    }
  }

  /// Alt kategori gerektiren kategoriler
  static bool altKategoriGerekli(String kategori) {
    return ['konut', 'isyeri', 'konutProjeleri'].contains(kategori);
  }
}

// ==================== DİNAMİK FİLTRE PROFİLLERİ ====================

/// Kategoriye göre hangi filtrelerin gösterileceğini/gizleneceğini belirler
class FiltreProfilleri {
  /// Tüm olası filtre alanları
  static const List<String> tumFiltreler = [
    'fiyat', 'brutMetrekare', 'netMetrekare', 'odaSayisi', 'binaYasi',
    'bulunduguKat', 'katSayisi', 'banyoSayisi', 'mutfakTipi', 'balkon',
    'asansor', 'otoparkTipi', 'esyali', 'kullanimDurumu', 'konutTipi',
    'tapuDurumu', 'kimden', 'isitmaTipi', 'siteIcerisinde', 'krediyeUygun',
    'takasli', 'ilanTarihi', 'fotoVideo', 'cephe', 'manzara',
    'icOzellikler', 'disOzellikler', 'muhit', 'ulasim',
    'engelliyeUygunluk', 'harita',
    // İş yerine özel
    'girisYuksekligi', 'zeminEtudu', 'yapininDurumu',
    // Arsa'ya özel
    'imarDurumu', 'gabari', 'kaksEmsal', 'adaParsel', 'katKarsiligi',
  ];

  /// Konut kategorisi için görünür filtreler
  static const Set<String> konutFiltreler = {
    'fiyat', 'brutMetrekare', 'netMetrekare', 'odaSayisi', 'binaYasi',
    'bulunduguKat', 'katSayisi', 'banyoSayisi', 'mutfakTipi', 'balkon',
    'asansor', 'otoparkTipi', 'esyali', 'kullanimDurumu', 'konutTipi',
    'tapuDurumu', 'kimden', 'isitmaTipi', 'siteIcerisinde', 'krediyeUygun',
    'takasli', 'ilanTarihi', 'fotoVideo', 'cephe', 'manzara',
    'icOzellikler', 'disOzellikler', 'muhit', 'ulasim',
    'engelliyeUygunluk', 'harita',
  };

  /// İş Yeri kategorisi için görünür filtreler
  static const Set<String> isyeriFiltreler = {
    'fiyat', 'brutMetrekare', 'netMetrekare', 'binaYasi',
    'bulunduguKat', 'katSayisi', 'banyoSayisi',
    'otoparkTipi', 'kullanimDurumu',
    'tapuDurumu', 'kimden', 'isitmaTipi', 'krediyeUygun',
    'takasli', 'ilanTarihi', 'fotoVideo', 'cephe', 'manzara',
    'icOzellikler', 'disOzellikler', 'muhit', 'ulasim', 'harita',
    // İş yerine özel
    'girisYuksekligi', 'zeminEtudu', 'yapininDurumu',
  };

  /// Arsa kategorisi için görünür filtreler
  static const Set<String> arsaFiltreler = {
    'fiyat', 'brutMetrekare', 'netMetrekare',
    'tapuDurumu', 'kimden', 'ilanTarihi', 'fotoVideo', 'harita',
    // Arsa'ya özel
    'imarDurumu', 'gabari', 'kaksEmsal', 'adaParsel', 'katKarsiligi',
  };

  /// Konut Projeleri kategorisi için görünür filtreler
  static const Set<String> konutProjeleriFiltreler = {
    'fiyat', 'brutMetrekare', 'netMetrekare', 'odaSayisi',
    'bulunduguKat', 'katSayisi', 'banyoSayisi', 'konutTipi',
    'kimden', 'ilanTarihi', 'fotoVideo', 'manzara',
    'icOzellikler', 'disOzellikler', 'muhit', 'ulasim', 'harita',
  };

  /// Bina kategorisi için görünür filtreler
  static const Set<String> binaFiltreler = {
    'fiyat', 'brutMetrekare', 'netMetrekare', 'binaYasi', 'katSayisi',
    'tapuDurumu', 'kimden', 'isitmaTipi', 'krediyeUygun',
    'ilanTarihi', 'fotoVideo', 'harita',
  };

  /// Devre Mülk kategorisi için görünür filtreler
  static const Set<String> devreMulkFiltreler = {
    'fiyat', 'brutMetrekare', 'netMetrekare', 'odaSayisi',
    'banyoSayisi', 'esyali',
    'kimden', 'ilanTarihi', 'fotoVideo', 'manzara', 'harita',
  };

  /// Turistik Tesis kategorisi için görünür filtreler
  static const Set<String> turistikTesisFiltreler = {
    'fiyat', 'brutMetrekare', 'netMetrekare', 'binaYasi', 'katSayisi',
    'otoparkTipi', 'tapuDurumu', 'kimden', 'krediyeUygun',
    'ilanTarihi', 'fotoVideo', 'manzara', 'harita',
    'icOzellikler', 'disOzellikler', 'muhit', 'ulasim',
  };

  /// Verilen kategoriye göre aktif filtre setini döndürür
  static Set<String> getAktifFiltreler(String kategori) {
    switch (kategori) {
      case 'konut':
        return konutFiltreler;
      case 'isyeri':
        return isyeriFiltreler;
      case 'arsa':
        return arsaFiltreler;
      case 'konutProjeleri':
        return konutProjeleriFiltreler;
      case 'bina':
        return binaFiltreler;
      case 'devreMulk':
        return devreMulkFiltreler;
      case 'turistikTesis':
        return turistikTesisFiltreler;
      default:
        return konutFiltreler; // Varsayılan
    }
  }

  /// Bir filtrenin seçilen kategoride görünüp görünmeyeceğini döndürür
  static bool filtreGorunurMu(String kategori, String filtreAdi) {
    return getAktifFiltreler(kategori).contains(filtreAdi);
  }
}

// ==================== SIRALAMA SEÇENEKLERİ ====================

class SiralamaSecenekleri {
  static const List<Map<String, String>> secenekler = [
    {'id': 'gelismis', 'label': 'Gelişmiş Sıralama'},
    {'id': 'fiyatArtan', 'label': 'Fiyata Göre (Önce En Düşük)'},
    {'id': 'fiyatAzalan', 'label': 'Fiyata Göre (Önce En Yüksek)'},
    {'id': 'tarihYeni', 'label': 'Tarihe Göre (Önce En Yeni)'},
    {'id': 'tarihEski', 'label': 'Tarihe Göre (Önce En Eski)'},
    {'id': 'adresAZ', 'label': 'Adrese Göre (A-Z)'},
    {'id': 'adresZA', 'label': 'Adrese Göre (Z-A)'},
  ];

  /// API sort parametresi oluşturur
  static Map<String, String> getSortParams(String siralamaId) {
    switch (siralamaId) {
      case 'fiyatArtan':
        return {'sortBy': 'fiyat', 'sortOrder': 'asc'};
      case 'fiyatAzalan':
        return {'sortBy': 'fiyat', 'sortOrder': 'desc'};
      case 'tarihYeni':
        return {'sortBy': 'createdAt', 'sortOrder': 'desc'};
      case 'tarihEski':
        return {'sortBy': 'createdAt', 'sortOrder': 'asc'};
      case 'adresAZ':
        return {'sortBy': 'il', 'sortOrder': 'asc'};
      case 'adresZA':
        return {'sortBy': 'il', 'sortOrder': 'desc'};
      case 'gelismis':
      default:
        return {'sortBy': 'createdAt', 'sortOrder': 'desc'};
    }
  }
}
