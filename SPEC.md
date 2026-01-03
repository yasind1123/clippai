Clippai - Urun ve Teknik Spesifikasyon

Ozet
- clippai, macOS icin bir clipboard manager uygulamasidir.
- Kullanici metin ve resim kopyaladiginda otomatik yakalar, liste halinde gosterir.
- Cmd+Shift+V kısayolu ile hizli yapistirma paneli acar.

Hedefler
- Kopyalanan metin ve resimleri guvenilir sekilde yakalamak.
- Hizli yapistirma akisini klavye merkezli ve kesintisiz yapmak.
- Tum verileri yerel diskte saklamak; ag baglantisi kullanmamak.

Hedef Disi
- Bulut senkronizasyonu.
- Takim paylasimi veya ortak clipboard.
- Icerik analizi (OCR, NLP).

Kullanici Akislari
1) Kullanici metin kopyalar
- Uygulama yeni clipboard girisini yakalar ve listeye ekler.
- En son kopya listenin basinda gorunur.

2) Kullanici Cmd+Shift+V tuslar
- Hizli yapistirma paneli aktif uygulama uzerinde acilir.
- Ok tuslari ve Enter ile secim yapar.
- Secilen icerik aktif uygulamaya yapistirilir.

3) Kullanici ana uygulamayi acar
- Tum gecmis listesi ve arama gorunur.
- Girisler incelenebilir, sabitlenebilir veya silinebilir.

Fonksiyonel Gereksinimler
- Clipboard izleme
  - NSPasteboard.general.changeCount periyodik kontrol edilir.
  - Degisiklik algilaninca pasteboard okunur.
  - Desteklenen tipler: public.utf8-plain-text, public.rtf, public.tiff, public.png.
  - Metin ve resim disinda kalan tipler yok sayilir (v1).
- Gecmis listesi
  - Varsayilan maksimum 200 giris saklanir (ayar olarak degistirilebilir).
  - Tekrarli icerik istege bagli olarak birlestirilebilir (v1'de kapali).
- Hizli yapistirma paneli
  - Global kisayol: Cmd+Shift+V.
  - Klavye ile gezinme: Yukari/Asagi, Enter ile yapistir.
  - Secim yapildiginda clipboard guncellenir ve Cmd+V simule edilir.
- Kalicilik
  - Uygulama kapaninca liste diske yazilir.
  - Uygulama acilisinda liste geri yuklenir.
- Temel ayarlar
  - Gecmis boyutu.
  - Uygulama acilista baslasin.
  - Hizli yapistirma paneli kısayolu (ileri surum).

Olmayan Gereksinimler
- Gizlilik: veriler sadece yerelde tutulur, ag erisimi yoktur.
- Performans: 200 giriste listeleme akici olmalidir.
- Bellek: resimler disk uzerine yazilir, UI'da thumbnail kullanilir.
- Erişilebilirlik: global yapistirma icin Accessibility izni gerekir.

UI Tasarimi (MVP)
- Menu bar uygulamasi.
- Ana pencere:
  - Sol: arama kutusu.
  - Orta: gecmis liste (tip ikonu + onizleme).
  - Sag: secilen icerigin detay onizlemesi.
- Hizli yapistirma paneli:
  - Minimal liste, sadece klavye odakli.
  - Secili oge vurgulanir.

Veri Modeli
- ClipboardItem
  - id: UUID
  - createdAt: Date
  - type: enum (text, image)
  - text: String? (text ise)
  - imagePath: String? (image ise, disk yolu)
  - sourceAppBundleId: String? (opsiyonel)
  - hash: String (dedupe icin)

Teknik Mimari
- App (SwiftUI)
  - UI katmani, ViewModel'lar Combine ile baglanir.
- ClipboardMonitor
  - Timer ile changeCount izler.
  - Degisimde pasteboard tiplerini okur ve item uretir.
- ClipboardStore
  - Bellek listesi + disk kaliciligi.
  - Resimleri /Application Support/clippai/images altina yazar.
- HotkeyManager
  - Global kisayol icin Carbon RegisterEventHotKey kullanir.
- PasteController
  - Secilen item'i pasteboard'a yazar.
  - CGEvent ile Cmd+V gonderir (Accessibility izni gerekir).

Depolama
- Metin: JSON dosyasi icinde saklanir.
- Resim: PNG olarak dosya sistemine yazilir, modelde path tutulur.
- Disk yolu: ~/Library/Application Support/clippai/

Guvenlik ve Izinler
- Accessibility izni: klavye eventi gondermek icin gerekir.
- App Sandbox kullaniliyorsa, uygun entitlements ayarlanir.

Gelisim Planı (Yuksek Seviye)
1) MVP
  - ClipboardMonitor + listeleme
  - Hizli yapistirma paneli
  - Kalicilik
2) Iyilestirmeler
  - Arama ve filtre
  - Pinleme
  - Kısayol ozellestirme
3) Ileri Seviye
  - Senkronizasyon
  - Takim paylasimi

Acik Sorular
- Hizli yapistirma paneli aktif uygulama uzerinde mi, yoksa sabit bir konumda mi acilacak?
- Gecmis limiti ve resim boyutu icin varsayilan degerler?
- Dedupe davranisi v1'de gerekli mi?
