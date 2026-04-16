/// Listing category and feature enums for Sahibinden-style forms
library listing_enums;

// ==================== KATEGORI YAPISI ====================

/// Ana kategori (7 ana kategori)
enum Kategori {
  konut('Konut'),
  isyeri('İş Yeri'),
  arsa('Arsa'),
  konutProjeleri('Konut Projeleri'),
  bina('Bina'),
  devreMulk('Devre Mülk'),
  turistikTesis('Turistik Tesis');

  final String label;
  const Kategori(this.label);

  static Kategori? fromString(String? value) {
    if (value == null) return null;
    return Kategori.values.firstWhere(
      (e) => e.name == value || e.name == value.toLowerCase(),
      orElse: () => Kategori.konut,
    );
  }
}

// ==================== ISLEM TIPI ====================

enum IslemTipi {
  satilik('Satılık'),
  kiralik('Kiralık'),
  turistikGunlukKiralik('Turistik Günlük Kiralık'),
  devrenSatilik('Devren Satılık'),
  devrenKiralik('Devren Kiralık'),
  katKarsiligiSatilik('Kat Karşılığı Satılık');

  final String label;
  const IslemTipi(this.label);

  static IslemTipi? fromString(String? value) {
    if (value == null) return null;
    return IslemTipi.values.firstWhere(
      (e) => e.name == value || e.name == value.toLowerCase(),
      orElse: () => IslemTipi.satilik,
    );
  }
}

// ==================== ODA SAYISI ====================

enum OdaSayisi {
  studio('Stüdyo (1+0)', 1),
  birArtiBir('1+1', 2),
  birBucukArtiBir('1.5+1', 3),
  ikiArtiSifir('2+0', 2),
  ikiArtiBir('2+1', 3),
  ikiBucukArtiBir('2.5+1', 4),
  ikiArtiIki('2+2', 4),
  ucArtiSifir('3+0', 3),
  ucArtiBir('3+1', 4),
  ucBucukArtiBir('3.5+1', 5),
  ucArtiIki('3+2', 5),
  ucArtiUc('3+3', 6),
  dortArtiSifir('4+0', 4),
  dortArtiBir('4+1', 5),
  dortBucukArtiBir('4.5+1', 6),
  dortBucukArtiIki('4.5+2', 7),
  dortArtiIki('4+2', 6),
  dortArtiUc('4+3', 7),
  dortArtiDort('4+4', 8),
  besArtiBir('5+1', 6),
  besBucukArtiBir('5.5+1', 7),
  besArtiIki('5+2', 7),
  besArtiUc('5+3', 8),
  besArtiDort('5+4', 9),
  altiArtiBir('6+1', 7),
  altiArtiIki('6+2', 8),
  altiBucukArtiBir('6.5+1', 8),
  altiArtiUc('6+3', 9),
  altiArtiDort('6+4', 10),
  yediArtiBir('7+1', 8),
  yediArtiIki('7+2', 9),
  yediArtiUc('7+3', 10),
  sekizArtiBir('8+1', 9),
  sekizArtiIki('8+2', 10),
  sekizArtiUc('8+3', 11),
  sekizArtiDort('8+4', 12),
  dokuzArtiBir('9+1', 10),
  dokuzArtiIki('9+2', 11),
  dokuzArtiUc('9+3', 12),
  dokuzArtiDort('9+4', 13),
  dokuzArtiBes('9+5', 14),
  dokuzArtiAlti('9+6', 15),
  onArtiBir('10+1', 11),
  onArtiIki('10+2', 12),
  onUzeri('10 Üzeri', 11);

  final String label;
  final int totalRooms;
  const OdaSayisi(this.label, this.totalRooms);

  static OdaSayisi? fromString(String? value) {
    if (value == null) return null;
    return OdaSayisi.values.firstWhere(
      (e) => e.label == value || e.name == value,
      orElse: () => OdaSayisi.ucArtiBir,
    );
  }
}

// ==================== BINA YASI ====================

enum BinaYasi {
  sifirHazir('0 (Oturuma Hazır)', 0),
  sifirYapim('0 (Yapım Aşamasında)', 0),
  bir('1', 1),
  iki('2', 2),
  uc('3', 3),
  dort('4', 4),
  bes('5', 5),
  altiOn('6-10 arası', 8),
  onbirOnbes('11-15 arası', 13),
  onaltiYirmi('16-20 arası', 18),
  yirmibirYirmiBes('21-25 arası', 23),
  yirmiAltiOtuz('26-30 arası', 28),
  otuzBirUstu('31 ve üzeri', 35);

  final String label;
  final int avgYears;
  const BinaYasi(this.label, this.avgYears);

  static BinaYasi? fromString(String? value) {
    if (value == null) return null;
    return BinaYasi.values.firstWhere(
      (e) => e.label == value || e.name == value,
      orElse: () => BinaYasi.altiOn,
    );
  }
}

// ==================== BULUNDUĞU KAT ====================

enum BulunduguKat {
  girisAltiKot4('Giriş Altı Kot 4'),
  girisAltiKot3('Giriş Altı Kot 3'),
  girisAltiKot2('Giriş Altı Kot 2'),
  girisAltiKot1('Giriş Altı Kot 1'),
  bodrumKat('Bodrum Kat'),
  zeminKat('Zemin Kat'),
  bahceKati('Bahçe Katı'),
  girisKati('Giriş Katı'),
  yuksekGiris('Yüksek Giriş'),
  mustakil('Müstakil'),
  villaTipi('Villa Tipi'),
  catiKati('Çatı Katı'),
  kat1('1'), kat2('2'), kat3('3'), kat4('4'), kat5('5'),
  kat6('6'), kat7('7'), kat8('8'), kat9('9'), kat10('10'),
  kat11('11'), kat12('12'), kat13('13'), kat14('14'), kat15('15'),
  kat16('16'), kat17('17'), kat18('18'), kat19('19'), kat20('20'),
  kat21('21'), kat22('22'), kat23('23'), kat24('24'), kat25('25'),
  kat26('26'), kat27('27'), kat28('28'), kat29('29'), kat30Uzeri('30 ve üzeri');

  final String label;
  const BulunduguKat(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== MUTFAK TİPİ ====================

enum MutfakTipi {
  acik('Açık (Amerikan)'),
  kapali('Kapalı');

  final String label;
  const MutfakTipi(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== OTOPARK TİPİ ====================

enum OtoparkTipi {
  acikOtopark('Açık Otopark'),
  kapaliOtopark('Kapalı Otopark'),
  acikKapali('Açık & Kapalı Otopark'),
  yok('Yok');

  final String label;
  const OtoparkTipi(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== KULLANIM DURUMU ====================

enum KullanimDurumu {
  bos('Boş'),
  kiracili('Kiracılı'),
  mulkSahibi('Mülk Sahibi');

  final String label;
  const KullanimDurumu(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== KONUT TİPİ ====================

enum KonutTipi {
  dubleks('Dubleks'),
  enUstKat('En Üst Kat'),
  araKat('Ara Kat'),
  araKatDubleks('Ara Kat Dubleks'),
  bahceDubleksi('Bahçe Dubleksi'),
  catiDubleksi('Çatı Dubleksi'),
  forleks('Forleks'),
  tersDubleks('Ters Dubleks'),
  tripleks('Tripleks');

  final String label;
  const KonutTipi(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== İLAN TARİHİ ====================

enum IlanTarihi {
  son24Saat('Son 24 saat', Duration(hours: 24)),
  son3Gun('Son 3 gün içinde', Duration(days: 3)),
  son7Gun('Son 7 gün içinde', Duration(days: 7)),
  son15Gun('Son 15 gün içinde', Duration(days: 15)),
  son30Gun('Son 30 gün içinde', Duration(days: 30));

  final String label;
  final Duration duration;
  const IlanTarihi(this.label, this.duration);

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== ISITMA TIPI ====================

enum IsitmaTipi {
  kombi('Kombi'),
  merkezi('Merkezi'),
  soba('Soba'),
  klima('Klima'),
  yerdenIsitma('Yerden Isıtma'),
  dogalgaz('Doğalgaz'),
  fuelOil('Fuel Oil'),
  gunes('Güneş Enerjisi'),
  elektrikli('Elektrikli'),
  katiYakit('Katı Yakıt'),
  jeotermal('Jeotermal');

  final String label;
  const IsitmaTipi(this.label);

  static IsitmaTipi? fromString(String? value) {
    if (value == null) return null;
    return IsitmaTipi.values.firstWhere(
      (e) => e.name == value.toLowerCase() || e.label == value,
      orElse: () => IsitmaTipi.kombi,
    );
  }

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== TAPU DURUMU ====================

enum TapuDurumu {
  katMulkiyetli('Kat Mülkiyetli'),
  katIrtifakli('Kat İrtifaklı'),
  hisseli('Hisseli Tapu'),
  mustakil('Müstakil Tapulu'),
  arsa('Arsa Tapulu'),
  kooperatifHisseli('Kooperatif Hisseli Tapu'),
  intifaHakki('İntifa Hakkı Tesisli'),
  yurtDisi('Yurt Dışı Tapulu'),
  yok('Tapu Kaydı Yok');

  final String label;
  const TapuDurumu(this.label);

  static TapuDurumu? fromString(String? value) {
    if (value == null) return null;
    return TapuDurumu.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => TapuDurumu.katMulkiyetli,
    );
  }

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== KIMDEN ====================

enum Kimden {
  sahibinden('Sahibinden'),
  emlakOfisi('Emlak Ofisinden'),
  insaatFirmasi('İnşaat Firmasından'),
  banka('Bankadan'),
  turizmIsletmesi('Turizm İşletmesinden');

  final String label;
  const Kimden(this.label);

  static Kimden? fromString(String? value) {
    if (value == null) return null;
    return Kimden.values.firstWhere(
      (e) => e.name == value || e.label == value,
      orElse: () => Kimden.sahibinden,
    );
  }

  static List<String> get labels => values.map((e) => e.label).toList();
}

/// All boolean features for filtering UI
enum ListingFeature {
  esyali('Eşyalı', 'esyali'),
  balkon('Balkon', 'balkon'),
  asansor('Asansör', 'asansor'),
  otopark('Otopark', 'otopark'),
  siteIcerisinde('Site İçerisinde', 'siteIcerisinde'),
  havuz('Havuz', 'havuz'),
  guvenlik('Güvenlik', 'guvenlik'),
  krediyeUygun('Krediye Uygun', 'krediyeUygun'),
  takasli('Takaslı', 'takasli');

  final String label;
  final String apiKey;
  const ListingFeature(this.label, this.apiKey);
}

// ==================== MANZARA ====================

enum Manzara {
  bogaz('Boğaz'),
  deniz('Deniz'),
  doga('Doğa'),
  gol('Göl'),
  havuz('Havuz'),
  nehir('Nehir'),
  parkYesilAlan('Park & Yeşil Alan'),
  sehir('Şehir');

  final String label;
  const Manzara(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== CEPHE ====================

enum Cephe {
  kuzey('Kuzey'),
  guney('Güney'),
  dogu('Doğu'),
  bati('Batı'),
  kuzeydogu('Kuzeydoğu'),
  kuzeybati('Kuzeybatı'),
  guneydogu('Güneydoğu'),
  guneybati('Güneybatı');

  final String label;
  const Cephe(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== ULASIM ====================

enum Ulasim {
  anayol('Anayol'),
  avrasyaTuneli('Avrasya Tüneli'),
  bogazKopruleri('Boğaz Köprüleri'),
  cadde('Cadde'),
  denizOtobusu('Deniz Otobüsü'),
  dolmus('Dolmuş'),
  e5('E-5'),
  havaalani('Havaalanı'),
  iskele('İskele'),
  marmaray('Marmaray'),
  metro('Metro'),
  metrobus('Metrobüs'),
  minibus('Minibüs'),
  otobusDuragi('Otobüs Durağı'),
  sahil('Sahil'),
  teleferik('Teleferik'),
  tem('TEM'),
  tramvay('Tramvay'),
  trenIstasyonu('Tren İstasyonu');

  final String label;
  const Ulasim(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== MUHIT ====================

enum Muhit {
  avm('Alışveriş Merkezi'),
  belediye('Belediye'),
  cami('Cami'),
  cemevi('Cemevi'),
  denizeGoleSifir('Denize/Göle Sıfır'),
  eczane('Eczane'),
  eglenceMerkezi('Eğlence Merkezi'),
  fuar('Fuar'),
  hastane('Hastane'),
  havra('Havra'),
  ilkokulOrtaokul('İlkokul-Ortaokul'),
  itfaiye('İtfaiye'),
  kilise('Kilise'),
  lise('Lise'),
  market('Market'),
  park('Park'),
  plaj('Plaj'),
  polisMerkezi('Polis Merkezi'),
  saglikOcagi('Sağlık Ocağı'),
  semtPazari('Semt Pazarı'),
  sporSalonu('Spor Salonu'),
  sehirMerkezi('Şehir Merkezi'),
  universite('Üniversite');

  final String label;
  const Muhit(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== YAPININ DURUMU ====================

enum YapininDurumu {
  ikinciEl('İkinci El'),
  sifir('Sıfır'),
  yapimAsamasinda('Yapım Aşamasında');

  final String label;
  const YapininDurumu(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== İÇ ÖZELLİKLER ====================

enum IcOzellik {
  adsl('ADSL'),
  ahsapDograma('Ahşap Doğrama'),
  akilliEv('Akıllı Ev'),
  alarm('Alarm (Hırsız/Yangın)'),
  alaturkaTuvalet('Alaturka Tuvalet'),
  aluminyumDograma('Alüminyum Doğrama'),
  amerikanKapi('Amerikan Kapı'),
  ankastreFirin('Ankastre Fırın'),
  barbeku('Barbekü'),
  beyazEsya('Beyaz Eşya'),
  boyali('Boyalı'),
  bulasikMakinesi('Bulaşık Makinesi'),
  buzdolabi('Buzdolabı'),
  camasirKurutma('Çamaşır/Kurutma Makinesi'),
  camasirOdasi('Çamaşır Odası'),
  celikKapi('Çelik Kapı'),
  dusakabin('Duşakabin'),
  duvarKagidi('Duvar Kağıdı'),
  ebeveynBanyosu('Ebeveyn Banyosu'),
  firin('Fırın'),
  fiberInternet('Fiber İnternet'),
  giyinmeOdasi('Giyinme Odası'),
  gomuluDolap('Gömme Dolap'),
  goruntuluDiafon('Görüntülü Diyafon'),
  hiltonBanyo('Hilton Banyo'),
  intercom('Intercom'),
  isicam('Isıcam'),
  jakuzi('Jakuzi'),
  kartonpiyer('Kartonpiyer'),
  kiler('Kiler'),
  klima('Klima'),
  kuvet('Küvet'),
  laminatZemin('Laminat Zemin'),
  marleyZemin('Marley Zemin'),
  parkeZemin('Parke Zemin'),
  seramikZemin('Seramik Zemin'),
  mobilya('Mobilya'),
  mutfakAnkastre('Mutfak Ankastre'),
  mutfakLaminat('Mutfak Laminat'),
  mutfakDogalgaz('Mutfak Doğalgazı'),
  panjurJaluzi('Panjur/Jaluzi'),
  pvcDograma('PVC Doğrama'),
  setUstuOcak('Set Üstü Ocak'),
  spotAydinlatma('Spot Aydınlatma'),
  sofben('Şofben'),
  somine('Şömine'),
  teras('Teras'),
  termosifon('Termosifon'),
  vestiyer('Vestiyer'),
  wifi('Wi-Fi'),
  yuzTanimaParmakIzi('Yüz Tanıma & Parmak İzi');

  final String label;
  const IcOzellik(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== DIŞ ÖZELLİKLER ====================

enum DisOzellik {
  aracSarjIstasyonu('Araç Şarj İstasyonu'),
  yirmiDortSaatGuvenlik('24 Saat Güvenlik'),
  apartmanGorevlisi('Apartman Görevlisi'),
  buharOdasi('Buhar Odası'),
  cocukOyunParki('Çocuk Oyun Parkı'),
  hamam('Hamam'),
  hidrofor('Hidrofor'),
  isiSesYalitimi('Isı/Ses Yalıtımı'),
  jenerator('Jeneratör'),
  kabloTv('Kablo TV'),
  kameraSistemi('Kamera Sistemi'),
  kres('Kreş'),
  mustakilHavuz('Müstakil Yüzme Havuzu'),
  acikHavuz('Açık Yüzme Havuzu'),
  kapaliHavuz('Kapalı Yüzme Havuzu'),
  sauna('Sauna'),
  siding('Siding'),
  sporAlani('Spor Alanı'),
  suDeposu('Su Deposu'),
  tenisKortu('Tenis Kortu'),
  uydu('Uydu'),
  yanginMerdiveni('Yangın Merdiveni');

  final String label;
  const DisOzellik(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== ENGELLİYE UYGUNLUK ====================

enum EngelliyeUygunluk {
  aracParkYeri('Araç Park Yeri'),
  asansor('Asansör'),
  banyo('Banyo'),
  mutfak('Mutfak'),
  park('Park'),
  genisKoridor('Geniş Koridor'),
  girisRampa('Giriş/Rampa'),
  merdiven('Merdiven'),
  odaKapisi('Oda Kapısı'),
  prizElektrik('Priz/Elektrik Anahtarı'),
  tutamakKorkuluk('Tutamak/Korkuluk'),
  tuvalet('Tuvalet'),
  yuzmeHavuzu('Yüzme Havuzu');

  final String label;
  const EngelliyeUygunluk(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

// ==================== SIRALAMA ====================

enum SiralamaTipi {
  gelismis('Gelişmiş Sıralama'),
  fiyatArtan('Fiyata Göre (Önce En Düşük)'),
  fiyatAzalan('Fiyata Göre (Önce En Yüksek)'),
  tarihYeni('Tarihe Göre (Önce En Yeni)'),
  tarihEski('Tarihe Göre (Önce En Eski)'),
  adresAZ('Adrese Göre (A-Z)'),
  adresZA('Adrese Göre (Z-A)');

  final String label;
  const SiralamaTipi(this.label);

  static List<String> get labels => values.map((e) => e.label).toList();
}

/// Türkiye İl/İlçe Verileri - Alfabetik Sıralı
class TurkiyeKonumlari {
  /// Tüm 81 il - A'dan Z'ye sıralı
  static const List<String> iller = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray', 'Amasya', 'Ankara', 'Antalya', 'Ardahan', 'Artvin',
    'Aydın', 'Balıkesir', 'Bartın', 'Batman', 'Bayburt', 'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur',
    'Bursa', 'Çanakkale', 'Çankırı', 'Çorum', 'Denizli', 'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan',
    'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane', 'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul',
    'İzmir', 'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars', 'Kastamonu', 'Kayseri', 'Kırıkkale', 'Kırklareli', 'Kırşehir',
    'Kilis', 'Kocaeli', 'Konya', 'Kütahya', 'Malatya', 'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş',
    'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye', 'Rize', 'Sakarya', 'Samsun', 'Şanlıurfa', 'Siirt', 'Sinop',
    'Sivas', 'Şırnak', 'Tekirdağ', 'Tokat', 'Trabzon', 'Tunceli', 'Uşak', 'Van', 'Yalova', 'Yozgat', 'Zonguldak',
  ];

  /// İlçe verileri
  static Map<String, List<String>> ilceler = {
    'Adana': ['Aladağ', 'Ceyhan', 'Çukurova', 'Feke', 'İmamoğlu', 'Karaisalı', 'Karataş', 'Kozan', 'Pozantı', 'Saimbeyli', 'Sarıçam', 'Seyhan', 'Tufanbeyli', 'Yumurtalık', 'Yüreğir'],
    'Adıyaman': ['Besni', 'Çelikhan', 'Gerger', 'Gölbaşı', 'Kahta', 'Merkez', 'Samsat', 'Sincik', 'Tut'],
    'Afyonkarahisar': ['Başmakçı', 'Bayat', 'Bolvadin', 'Çay', 'Çobanlar', 'Dazkırı', 'Dinar', 'Emirdağ', 'Evciler', 'Hocalar', 'İhsaniye', 'İscehisar', 'Kızılören', 'Merkez', 'Sandıklı', 'Sinanpaşa', 'Sultandağı', 'Şuhut'],
    'Ağrı': ['Diyadin', 'Doğubayazıt', 'Eleşkirt', 'Hamur', 'Merkez', 'Patnos', 'Taşlıçay', 'Tutak'],
    'Aksaray': ['Ağaçören', 'Eskil', 'Gülağaç', 'Güzelyurt', 'Merkez', 'Ortaköy', 'Sarıyahşi', 'Sultanhanı'],
    'Amasya': ['Göynücek', 'Gümüşhacıköy', 'Hamamözü', 'Merkez', 'Merzifon', 'Suluova', 'Taşova'],
    'Ankara': ['Akyurt', 'Altındağ', 'Ayaş', 'Balâ', 'Beypazarı', 'Çamlıdere', 'Çankaya', 'Çubuk', 'Elmadağ', 'Etimesgut', 'Evren', 'Gölbaşı', 'Güdül', 'Haymana', 'Kalecik', 'Kahramankazan', 'Keçiören', 'Kızılcahamam', 'Mamak', 'Nallıhan', 'Polatlı', 'Pursaklar', 'Sincan', 'Şereflikoçhisar', 'Yenimahalle'],
    'Antalya': ['Akseki', 'Aksu', 'Alanya', 'Demre', 'Döşemealtı', 'Elmalı', 'Finike', 'Gazipaşa', 'Gündoğmuş', 'İbradı', 'Kaş', 'Kemer', 'Kepez', 'Konyaaltı', 'Korkuteli', 'Kumluca', 'Manavgat', 'Muratpaşa', 'Serik'],
    'Ardahan': ['Çıldır', 'Damal', 'Göle', 'Hanak', 'Merkez', 'Posof'],
    'Artvin': ['Ardanuç', 'Arhavi', 'Borçka', 'Hopa', 'Merkez', 'Murgul', 'Şavşat', 'Yusufeli'],
    'Aydın': ['Bozdoğan', 'Buharkent', 'Çine', 'Didim', 'Efeler', 'Germencik', 'İncirliova', 'Karacasu', 'Karpuzlu', 'Koçarlı', 'Köşk', 'Kuşadası', 'Kuyucak', 'Nazilli', 'Söke', 'Sultanhisar', 'Yenipazar'],
    'Balıkesir': ['Altıeylül', 'Ayvalık', 'Balya', 'Bandırma', 'Bigadiç', 'Burhaniye', 'Dursunbey', 'Edremit', 'Erdek', 'Gömeç', 'Gönen', 'Havran', 'İvrindi', 'Karesi', 'Kepsut', 'Manyas', 'Marmara', 'Savaştepe', 'Sındırgı', 'Susurluk'],
    'Bartın': ['Amasra', 'Kurucaşile', 'Merkez', 'Ulus'],
    'Batman': ['Beşiri', 'Gercüş', 'Hasankeyf', 'Kozluk', 'Merkez', 'Sason'],
    'Bayburt': ['Aydıntepe', 'Demirözü', 'Merkez'],
    'Bilecik': ['Bozüyük', 'Gölpazarı', 'İnhisar', 'Merkez', 'Osmaneli', 'Pazaryeri', 'Söğüt', 'Yenipazar'],
    'Bingöl': ['Adaklı', 'Genç', 'Karlıova', 'Kiğı', 'Merkez', 'Solhan', 'Yayladere', 'Yedisu'],
    'Bitlis': ['Adilcevaz', 'Ahlat', 'Güroymak', 'Hizan', 'Merkez', 'Mutki', 'Tatvan'],
    'Bolu': ['Dörtdivan', 'Gerede', 'Göynük', 'Kıbrıscık', 'Mengen', 'Merkez', 'Mudurnu', 'Seben', 'Yeniçağa'],
    'Burdur': ['Ağlasun', 'Altınyayla', 'Bucak', 'Çavdır', 'Çeltikçi', 'Gölhisar', 'Karamanlı', 'Kemer', 'Merkez', 'Tefenni', 'Yeşilova'],
    'Bursa': ['Büyükorhan', 'Gemlik', 'Gürsu', 'Harmancık', 'İnegöl', 'İznik', 'Karacabey', 'Keles', 'Kestel', 'Mudanya', 'Mustafakemalpaşa', 'Nilüfer', 'Orhaneli', 'Orhangazi', 'Osmangazi', 'Yenişehir', 'Yıldırım'],
    'Çanakkale': ['Ayvacık', 'Bayramiç', 'Biga', 'Bozcaada', 'Çan', 'Eceabat', 'Ezine', 'Gelibolu', 'Gökçeada', 'Lapseki', 'Merkez', 'Yenice'],
    'Çankırı': ['Atkaracalar', 'Bayramören', 'Çerkeş', 'Eldivan', 'Ilgaz', 'Kızılırmak', 'Korgun', 'Kurşunlu', 'Merkez', 'Orta', 'Şabanözü', 'Yapraklı'],
    'Çorum': ['Alaca', 'Bayat', 'Boğazkale', 'Dodurga', 'İskilip', 'Kargı', 'Laçin', 'Mecitözü', 'Merkez', 'Oğuzlar', 'Ortaköy', 'Osmancık', 'Sungurlu', 'Uğurludağ'],
    'Denizli': ['Acıpayam', 'Babadağ', 'Baklan', 'Bekilli', 'Beyağaç', 'Bozkurt', 'Buldan', 'Çal', 'Çameli', 'Çardak', 'Çivril', 'Güney', 'Honaz', 'Kale', 'Merkezefendi', 'Pamukkale', 'Sarayköy', 'Serinhisar', 'Tavas'],
    'Diyarbakır': ['Bağlar', 'Bismil', 'Çermik', 'Çınar', 'Çüngüş', 'Dicle', 'Eğil', 'Ergani', 'Hani', 'Hazro', 'Kayapınar', 'Kocaköy', 'Kulp', 'Lice', 'Silvan', 'Sur', 'Yenişehir'],
    'Düzce': ['Akçakoca', 'Cumayeri', 'Çilimli', 'Gölyaka', 'Gümüşova', 'Kaynaşlı', 'Merkez', 'Yığılca'],
    'Edirne': ['Enez', 'Havsa', 'İpsala', 'Keşan', 'Lalapaşa', 'Meriç', 'Merkez', 'Süloğlu', 'Uzunköprü'],
    'Elazığ': ['Ağın', 'Alacakaya', 'Arıcak', 'Baskil', 'Karakoçan', 'Keban', 'Kovancılar', 'Maden', 'Merkez', 'Palu', 'Sivrice'],
    'Erzincan': ['Çayırlı', 'İliç', 'Kemah', 'Kemaliye', 'Merkez', 'Otlukbeli', 'Refahiye', 'Tercan', 'Üzümlü'],
    'Erzurum': ['Aşkale', 'Aziziye', 'Çat', 'Hınıs', 'Horasan', 'İspir', 'Karaçoban', 'Karayazı', 'Köprüköy', 'Narman', 'Oltu', 'Olur', 'Palandöken', 'Pasinler', 'Pazaryolu', 'Şenkaya', 'Tekman', 'Tortum', 'Uzundere', 'Yakutiye'],
    'Eskişehir': ['Alpu', 'Beylikova', 'Çifteler', 'Günyüzü', 'Han', 'İnönü', 'Mahmudiye', 'Mihalgazi', 'Mihalıççık', 'Odunpazarı', 'Sarıcakaya', 'Seyitgazi', 'Sivrihisar', 'Tepebaşı'],
    'Gaziantep': ['Araban', 'İslahiye', 'Karkamış', 'Nizip', 'Nurdağı', 'Oğuzeli', 'Şahinbey', 'Şehitkamil', 'Yavuzeli'],
    'Giresun': ['Alucra', 'Bulancak', 'Çamoluk', 'Çanakçı', 'Dereli', 'Doğankent', 'Espiye', 'Eynesil', 'Görele', 'Güce', 'Keşap', 'Merkez', 'Piraziz', 'Şebinkarahisar', 'Tirebolu', 'Yağlıdere'],
    'Gümüşhane': ['Kelkit', 'Köse', 'Kürtün', 'Merkez', 'Şiran', 'Torul'],
    'Hakkari': ['Çukurca', 'Derecik', 'Merkez', 'Şemdinli', 'Yüksekova'],
    'Hatay': ['Altınözü', 'Antakya', 'Arsuz', 'Belen', 'Defne', 'Dörtyol', 'Erzin', 'Hassa', 'İskenderun', 'Kırıkhan', 'Kumlu', 'Payas', 'Reyhanlı', 'Samandağ', 'Yayladağı'],
    'Iğdır': ['Aralık', 'Karakoyunlu', 'Merkez', 'Tuzluca'],
    'Isparta': ['Aksu', 'Atabey', 'Eğirdir', 'Gelendost', 'Gönen', 'Keçiborlu', 'Merkez', 'Senirkent', 'Sütçüler', 'Şarkikaraağaç', 'Uluborlu', 'Yalvaç', 'Yenişarbademli'],
    'İstanbul': ['Adalar', 'Arnavutköy', 'Ataşehir', 'Avcılar', 'Bağcılar', 'Bahçelievler', 'Bakırköy', 'Başakşehir', 'Bayrampaşa', 'Beşiktaş', 'Beykoz', 'Beylikdüzü', 'Beyoğlu', 'Büyükçekmece', 'Çatalca', 'Çekmeköy', 'Esenler', 'Esenyurt', 'Eyüpsultan', 'Fatih', 'Gaziosmanpaşa', 'Güngören', 'Kadıköy', 'Kağıthane', 'Kartal', 'Küçükçekmece', 'Maltepe', 'Pendik', 'Sancaktepe', 'Sarıyer', 'Silivri', 'Sultanbeyli', 'Sultangazi', 'Şile', 'Şişli', 'Tuzla', 'Ümraniye', 'Üsküdar', 'Zeytinburnu'],
    'İzmir': ['Aliağa', 'Balçova', 'Bayındır', 'Bayraklı', 'Bergama', 'Beydağ', 'Bornova', 'Buca', 'Çeşme', 'Çiğli', 'Dikili', 'Foça', 'Gaziemir', 'Güzelbahçe', 'Karabağlar', 'Karaburun', 'Karşıyaka', 'Kemalpaşa', 'Kınık', 'Kiraz', 'Konak', 'Menderes', 'Menemen', 'Narlıdere', 'Ödemiş', 'Seferihisar', 'Selçuk', 'Tire', 'Torbalı', 'Urla'],
    'Kahramanmaraş': ['Afşin', 'Andırın', 'Çağlayancerit', 'Dulkadiroğlu', 'Ekinözü', 'Elbistan', 'Göksun', 'Nurhak', 'Onikişubat', 'Pazarcık', 'Türkoğlu'],
    'Karabük': ['Eflani', 'Eskipazar', 'Merkez', 'Ovacık', 'Safranbolu', 'Yenice'],
    'Karaman': ['Ayrancı', 'Başyayla', 'Ermenek', 'Kazımkarabekir', 'Merkez', 'Sarıveliler'],
    'Kars': ['Akyaka', 'Arpaçay', 'Digor', 'Kağızman', 'Merkez', 'Sarıkamış', 'Selim', 'Susuz'],
    'Kastamonu': ['Abana', 'Ağlı', 'Araç', 'Azdavay', 'Bozkurt', 'Cide', 'Çatalzeytin', 'Daday', 'Devrekani', 'Doğanyurt', 'Hanönü', 'İhsangazi', 'İnebolu', 'Küre', 'Merkez', 'Pınarbaşı', 'Seydiler', 'Şenpazar', 'Taşköprü', 'Tosya'],
    'Kayseri': ['Akkışla', 'Bünyan', 'Develi', 'Felahiye', 'Hacılar', 'İncesu', 'Kocasinan', 'Melikgazi', 'Özvatan', 'Pınarbaşı', 'Sarıoğlan', 'Sarız', 'Talas', 'Tomarza', 'Yahyalı', 'Yeşilhisar'],
    'Kırıkkale': ['Bahşılı', 'Balışeyh', 'Çelebi', 'Delice', 'Karakeçili', 'Keskin', 'Merkez', 'Sulakyurt', 'Yahşihan'],
    'Kırklareli': ['Babaeski', 'Demirköy', 'Kofçaz', 'Lüleburgaz', 'Merkez', 'Pehlivanköy', 'Pınarhisar', 'Vize'],
    'Kırşehir': ['Akçakent', 'Akpınar', 'Boztepe', 'Çiçekdağı', 'Kaman', 'Merkez', 'Mucur'],
    'Kilis': ['Elbeyli', 'Merkez', 'Musabeyli', 'Polateli'],
    'Kocaeli': ['Başiskele', 'Çayırova', 'Darıca', 'Derince', 'Dilovası', 'Gebze', 'Gölcük', 'İzmit', 'Kandıra', 'Karamürsel', 'Kartepe', 'Körfez'],
    'Konya': ['Ahırlı', 'Akören', 'Akşehir', 'Altınekin', 'Beyşehir', 'Bozkır', 'Cihanbeyli', 'Çeltik', 'Çumra', 'Derbent', 'Derebucak', 'Doğanhisar', 'Emirgazi', 'Ereğli', 'Güneysınır', 'Hadım', 'Halkapınar', 'Hüyük', 'Ilgın', 'Kadınhanı', 'Karapınar', 'Karatay', 'Kulu', 'Meram', 'Sarayönü', 'Selçuklu', 'Seydişehir', 'Taşkent', 'Tuzlukçu', 'Yalıhüyük', 'Yunak'],
    'Kütahya': ['Altıntaş', 'Aslanapa', 'Çavdarhisar', 'Domaniç', 'Dumlupınar', 'Emet', 'Gediz', 'Hisarcık', 'Merkez', 'Pazarlar', 'Şaphane', 'Simav', 'Tavşanlı'],
    'Malatya': ['Akçadağ', 'Arapgir', 'Arguvan', 'Battalgazi', 'Darende', 'Doğanşehir', 'Doğanyol', 'Hekimhan', 'Kale', 'Kuluncak', 'Pütürge', 'Yazıhan', 'Yeşilyurt'],
    'Manisa': ['Ahmetli', 'Akhisar', 'Alaşehir', 'Demirci', 'Gölmarmara', 'Gördes', 'Kırkağaç', 'Köprübaşı', 'Kula', 'Salihli', 'Sarıgöl', 'Saruhanlı', 'Selendi', 'Soma', 'Şehzadeler', 'Turgutlu', 'Yunusemre'],
    'Mardin': ['Artuklu', 'Dargeçit', 'Derik', 'Kızıltepe', 'Mazıdağı', 'Midyat', 'Nusaybin', 'Ömerli', 'Savur', 'Yeşilli'],
    'Mersin': ['Akdeniz', 'Anamur', 'Aydıncık', 'Bozyazı', 'Çamlıyayla', 'Erdemli', 'Gülnar', 'Mezitli', 'Mut', 'Silifke', 'Tarsus', 'Toroslar', 'Yenişehir'],
    'Muğla': ['Bodrum', 'Dalaman', 'Datça', 'Fethiye', 'Kavaklıdere', 'Köyceğiz', 'Marmaris', 'Menteşe', 'Milas', 'Ortaca', 'Seydikemer', 'Ula', 'Yatağan'],
    'Muş': ['Bulanık', 'Hasköy', 'Korkut', 'Malazgirt', 'Merkez', 'Varto'],
    'Nevşehir': ['Acıgöl', 'Avanos', 'Derinkuyu', 'Gülşehir', 'Hacıbektaş', 'Kozaklı', 'Merkez', 'Ürgüp'],
    'Niğde': ['Altunhisar', 'Bor', 'Çamardı', 'Çiftlik', 'Merkez', 'Ulukışla'],
    'Ordu': ['Akkuş', 'Altınordu', 'Aybastı', 'Çamaş', 'Çatalpınar', 'Çaybaşı', 'Fatsa', 'Gölköy', 'Gülyalı', 'Gürgentepe', 'İkizce', 'Kabadüz', 'Kabataş', 'Korgan', 'Kumru', 'Mesudiye', 'Perşembe', 'Ulubey', 'Ünye'],
    'Osmaniye': ['Bahçe', 'Düziçi', 'Hasanbeyli', 'Kadirli', 'Merkez', 'Sumbas', 'Toprakkale'],
    'Rize': ['Ardeşen', 'Çamlıhemşin', 'Çayeli', 'Derepazarı', 'Fındıklı', 'Güneysu', 'Hemşin', 'İkizdere', 'İyidere', 'Kalkandere', 'Merkez', 'Pazar'],
    'Sakarya': ['Adapazarı', 'Akyazı', 'Arifiye', 'Erenler', 'Ferizli', 'Geyve', 'Hendek', 'Karapürçek', 'Karasu', 'Kaynarca', 'Kocaali', 'Pamukova', 'Sapanca', 'Serdivan', 'Söğütlü', 'Taraklı'],
    'Samsun': ['Alaçam', 'Asarcık', 'Atakum', 'Ayvacık', 'Bafra', 'Canik', 'Çarşamba', 'Havza', 'İlkadım', 'Kavak', 'Ladik', 'Ondokuzmayıs', 'Salıpazarı', 'Tekkeköy', 'Terme', 'Vezirköprü', 'Yakakent'],
    'Şanlıurfa': ['Akçakale', 'Birecik', 'Bozova', 'Ceylanpınar', 'Eyyübiye', 'Halfeti', 'Haliliye', 'Harran', 'Hilvan', 'Karaköprü', 'Siverek', 'Suruç', 'Viranşehir'],
    'Siirt': ['Baykan', 'Eruh', 'Kurtalan', 'Merkez', 'Pervari', 'Şirvan', 'Tillo'],
    'Sinop': ['Ayancık', 'Boyabat', 'Dikmen', 'Durağan', 'Erfelek', 'Gerze', 'Merkez', 'Saraydüzü', 'Türkeli'],
    'Sivas': ['Akıncılar', 'Altınyayla', 'Divriği', 'Doğanşar', 'Gemerek', 'Gölova', 'Gürün', 'Hafik', 'İmranlı', 'Kangal', 'Koyulhisar', 'Merkez', 'Suşehri', 'Şarkışla', 'Ulaş', 'Yıldızeli', 'Zara'],
    'Şırnak': ['Beytüşşebap', 'Cizre', 'Güçlükonak', 'İdil', 'Merkez', 'Silopi', 'Uludere'],
    'Tekirdağ': ['Çerkezköy', 'Çorlu', 'Ergene', 'Hayrabolu', 'Kapaklı', 'Malkara', 'Marmaraereğlisi', 'Muratlı', 'Saray', 'Süleymanpaşa', 'Şarköy'],
    'Tokat': ['Almus', 'Artova', 'Başçiftlik', 'Erbaa', 'Merkez', 'Niksar', 'Pazar', 'Reşadiye', 'Sulusaray', 'Turhal', 'Yeşilyurt', 'Zile'],
    'Trabzon': ['Akçaabat', 'Araklı', 'Arsin', 'Beşikdüzü', 'Çarşıbaşı', 'Çaykara', 'Dernekpazarı', 'Düzköy', 'Hayrat', 'Köprübaşı', 'Maçka', 'Of', 'Ortahisar', 'Sürmene', 'Şalpazarı', 'Tonya', 'Vakfıkebir', 'Yomra'],
    'Tunceli': ['Çemişgezek', 'Hozat', 'Mazgirt', 'Merkez', 'Nazımiye', 'Ovacık', 'Pertek', 'Pülümür'],
    'Uşak': ['Banaz', 'Eşme', 'Karahallı', 'Merkez', 'Sivaslı', 'Ulubey'],
    'Van': ['Bahçesaray', 'Başkale', 'Çaldıran', 'Çatak', 'Edremit', 'Erciş', 'Gevaş', 'Gürpınar', 'İpekyolu', 'Muradiye', 'Özalp', 'Saray', 'Tuşba'],
    'Yalova': ['Altınova', 'Armutlu', 'Çiftlikköy', 'Çınarcık', 'Merkez', 'Termal'],
    'Yozgat': ['Akdağmadeni', 'Aydıncık', 'Boğazlıyan', 'Çandır', 'Çayıralan', 'Çekerek', 'Kadışehri', 'Merkez', 'Saraykent', 'Sarıkaya', 'Sorgun', 'Şefaatli', 'Yenifakılı', 'Yerköy'],
    'Zonguldak': ['Alaplı', 'Çaycuma', 'Devrek', 'Ereğli', 'Gökçebey', 'Kilimli', 'Kozlu', 'Merkez'],
  };

  /// İlçe getir — Türkçe alfabetik sıralı kopya döndürür (kaynak listeyi mutasyona uğratmaz)
  static List<String> getIlceler(String il) {
    final list = ilceler[il];
    if (list == null || list.isEmpty) {
      return ['Merkez'];
    }
    final sorted = List<String>.from(list);
    sorted.sort(_turkishCompare);
    return sorted;
  }

  /// Türkçe locale-duyarlı karşılaştırıcı
  static int _turkishCompare(String a, String b) {
    const turkishOrder = 'AaBbCcÇçDdEeFfGgĞğHhIıİiJjKkLlMmNnOoÖöPpQqRrSsŞşTtUuÜüVvWwXxYyZz';
    final minLen = a.length < b.length ? a.length : b.length;
    for (int i = 0; i < minLen; i++) {
      final idxA = turkishOrder.indexOf(a[i]);
      final idxB = turkishOrder.indexOf(b[i]);
      final cA = idxA == -1 ? a.codeUnitAt(i) + 10000 : idxA;
      final cB = idxB == -1 ? b.codeUnitAt(i) + 10000 : idxB;
      if (cA != cB) return cA.compareTo(cB);
    }
    return a.length.compareTo(b.length);
  }
}


// ==================== FIYAT VE METREKARE ARALIGI ====================

class FiyatAraligi {
  static const List<int> satilikFiyatlar = [
    100000, 250000, 500000, 750000, 1000000,
    1500000, 2000000, 3000000, 5000000, 10000000,
  ];

  static const List<int> kiralikFiyatlar = [
    1000, 2500, 5000, 7500, 10000,
    15000, 20000, 30000, 50000, 100000,
  ];

  static String format(int fiyat) {
    if (fiyat >= 1000000) {
      return '${(fiyat / 1000000).toStringAsFixed(fiyat % 1000000 == 0 ? 0 : 1)} M';
    } else if (fiyat >= 1000) {
      return '${(fiyat / 1000).toStringAsFixed(0)} K';
    }
    return fiyat.toString();
  }
}

class MetrekareAraligi {
  static const List<int> degerler = [
    50, 75, 100, 125, 150, 175, 200, 250, 300, 400, 500,
  ];
}
