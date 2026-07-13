# WINATRA AI — Project Blueprint

> **Dokumen ini adalah pegangan utama proyek Winatra AI.**
> Ditujukan untuk dibaca oleh AI mana pun yang membantu development (AI agent di VS Code, Gemini, DeepSeek, Claude, dll) maupun oleh developer manusia.
> Jika kamu adalah AI/agent yang membaca file ini: **baca seluruh dokumen sebelum menulis kode apa pun.** Semua keputusan produk sudah difinalisasi oleh pemilik proyek kecuali ditandai `[TBD]`. Jangan mengubah keputusan yang sudah fix tanpa konfirmasi eksplisit dari user.

---

## 0. Cara Pakai Dokumen Ini (untuk AI Agent)

- Bagian **1-2**: konteks produk & branding — wajib dipahami sebelum ngoding UI apa pun.
- Bagian **3**: spesifikasi lengkap tiap fitur — ini "source of truth" logic bisnis.
- Bagian **4**: sistem tier, kuota, monetisasi — kritikal, jangan sampai salah implementasi karena ini sumber pendapatan.
- Bagian **5**: prinsip teknis wajib (hemat biaya API, budget 0 rupiah).
- Bagian **6**: flow aplikasi end-to-end.
- Bagian **7**: daftar keputusan terbuka `[TBD]` — kalau agent menemukan hal yang belum diputuskan di sini, **tanya ke user, jangan asumsi sendiri.**
- Update dokumen ini setiap ada keputusan baru dari user, jangan buat dokumen terpisah yang bikin informasi kececer.

---

## 1. Ringkasan Proyek

**Nama:** Winatra AI
**Positioning:** Aplikasi efisiensi untuk orang yang gak punya banyak waktu — kombinasi asisten belajar, asisten harian, keyboard AI, dan asisten aksesibilitas dalam satu ekosistem.
**Model bisnis:** Freemium 3 tier (Free / Premium / Legend) dengan monetisasi dari iklan + kemungkinan langganan premium.
**Budget:** **Rp0** untuk infrastruktur/layanan pihak ketiga. Satu-satunya biaya berbayar yang diterima adalah **biaya API (DeepSeek)**. Semua komponen lain wajib pakai layanan gratis/free-tier (Firebase free tier, dst).

---

## 2. Branding

| Elemen | Ketentuan |
|---|---|
| Nama | Winatra AI |
| Logo | Baru, tapi tetap mengandung elemen huruf **"W"** |
| Tema warna | **Electric blue + neon** — dipakai konsisten di semua fitur mendatang (notifikasi, keyboard, AI popup, UI umum) |
| Tone pengembang | Splash screen menyebut "Dikembangkan oleh Tim Winatra" |

---

## 3. Spesifikasi Fitur

### 3.1 Notifikasi Mengambang (Persistent, gaya notifikasi Spotify)

- Selalu ada di atas layar, bisa **di-toggle on/off**, dan **bisa diatur** (punya mode).
- Dua mode operasi (nama final masih bisa diganti, placeholder di bawah):

**Mode Pelajar**
- Tombol utama: **Jawab**
- Setelah ditekan → sub-pilihan: **Pilihan Ganda** atau **Essay**
- Alur: user copy soal → tekan Jawab → dikirim ke API DeepSeek → hasil dikirim balik dalam bentuk notifikasi baru (mirip notifikasi WA masuk)
  - **Pilihan Ganda**: output singkat, hanya huruf (A/B/C/D). Ada tombol tambahan **"Kenapa?"** di notif (mirip tombol Balas di WA) yang saat ditekan menampilkan alasan jawaban.
  - **Essay**: output lebih panjang, dan **otomatis ter-paste ke keyboard user** (tidak perlu copy-paste manual oleh user).
- Ada **sub-pemilihan bidang/mata pelajaran** (SD sampai Kuliah — semua mapel) untuk membuat prompt ke DeepSeek lebih spesifik & akurat sesuai konteks belajar user.

**Mode Daily**
- Tombol berubah menjadi: **Nanya** dan **Ini Apa?**
- **Nanya**: membuka roomchat mengambang (floating chat), mirip fitur reply WA, user bisa tanya bebas dan dapat jawaban lewat notifikasi juga.
- **Ini Apa?**: aplikasi membaca konten yang sedang tampil di layar, menjelaskan isinya, dan user bisa lanjut tanya-jawab (mirip fitur asisten kontekstual ala Google).

**Mode Ujian** (tambahan, bukan mode notifikasi biasa, tapi state sementara)
- User set rentang tanggal (misal "UAS: 20–25 Juli") dari Home.
- Selama rentang aktif:
  - Semua notifikasi non-esensial (pengumuman harian, obrolan santai AI Popup, dll) **dibisukan otomatis**.
  - Hanya tombol **Jawab** (Mode Pelajar) yang tetap aktif dan diprioritaskan — respons lebih cepat/ringkas, tidak ada rate-limit ketat, tanpa basa-basi.
- Setelah rentang tanggal selesai, semua kembali normal **otomatis**, tidak perlu dimatikan manual oleh user.

**Prinsip teknis fitur ini:** tidak semua proses harus lewat AI. Jika suatu tugas bisa diselesaikan dengan logic native/Python biasa, gunakan itu dulu untuk menghemat pemakaian token API.

---

### 3.2 Keyboard Custom

- **Harus jadi keyboard sistem sungguhan** (bukan overlay palsu) — nyaman, responsif, lengkap, ada emoji. Referensi implementasi dari keyboard open-source di GitHub (riset dulu sebelum membangun dari nol; proyek keyboard sebelumnya tidak responsif — jangan ulangi kesalahan itu).
- Perbedaan dari keyboard biasa: ada tombol khusus **"Winatra"** untuk bertanya ke AI langsung dari keyboard.
  - Setelah user bertanya, keyboard **tidak langsung hilang** — area jawaban muncul di atas dan bisa **di-scroll**, baru setelah itu keyboard collapse/hilang.
  - **History jawaban tersimpan lokal dan bisa dibuka langsung dari keyboard itu sendiri** (tidak perlu buka app Winatra).
- **Gesture recovery:** tap layar 3x untuk memanggil kembali keyboard (mengatasi masalah "keyboard hilang" dari proyek sebelumnya).
- Ini benar-benar harus berfungsi sebagai keyboard pengganti keyboard sistem, bukan sekadar widget tambahan.

---

### 3.3 AI Popup (Karakter Kepala Robot Kecil, Ekspresif)

- Berbentuk kepala robot kecil yang ekspresif, terasa seperti "bisa melihat" user.
- Interaksi: tap → muncul input box + output berupa textbox scrollable.
- **Mata "melirik" ke layar** — membaca konten layar yang sedang ditampilkan, lalu bisa diajak ngobrol kontekstual soal itu.
- **Kontekstual per-aplikasi**: saat user buka app lain (TikTok, WA, dll), karakter muncul dengan **speech bubble kecil gaya komik**, menawarkan bantuan relevan dengan konteks app tersebut. User bisa tap untuk lanjut chat kalau mau (tidak dipaksa).
- **Di dalam app Winatra sendiri**: muncul otomatis, pelan-pelan menjelaskan fitur-fitur Winatra secara bergilir (tour/onboarding pasif).
  - Developer bisa override konten ini kapan saja untuk broadcast pengumuman mendadak ke semua user.
  - Jika user tidak mengaktifkan fitur ini secara manual, karakter hilang saat keluar app, dan muncul lagi menjelaskan Winatra dari awal setiap kali masuk app.
- Ekspresi berubah sesuai konteks (misal: lama tidak dibuka → ekspresi "kangen"; kuota mau habis → ekspresi "waspada") — murah secara compute (cukup ganti sprite/animasi), menambah personality kuat untuk branding.

---

### 3.4 Winatra Asisten (Accessibility Service — untuk disabilitas & orang sibuk)

- Diaktifkan manual oleh user (nama fitur: **Winatra Asisten**).
- Memanfaatkan Android Accessibility Service.
- Target: asisten full-service ala Jarvis. Harus benar-benar paham apa yang harus dikerjakan, termasuk:
  - Mengerjakan e-learning user
  - Membalas chat
  - Mengatur alarm
  - Mengingatkan jadwal/tugas user
- Muncul di **lock screen** menampilkan task yang sedang/perlu dikerjakan user.
- Bisa **ngobrol interaktif** dengan user layaknya teman, bukan cuma eksekusi task satu arah.
- Mode tambahan:
  - **Mode Fokus**: user set jam belajar/kerja → asisten otomatis membisukan notifikasi lain, hanya memberi reminder yang relevan.
  - **Daily Briefing**: saat alarm pagi dimatikan, asisten memberi ringkasan: jadwal hari ini + deadline tugas + pengumuman dari Winatra. Fitur andalan untuk mendorong upgrade ke tier Legend.
- `[TBD]` — detail arsitektur & scope penuh fitur ini belum final, akan didalami di sesi terpisah.

---

### 3.5 Fitur Otak (RAG — mirip NotebookLM)

- User bisa upload file apapun sebagai basis pengetahuan pribadi ("Otak").
- Semua fitur lain (keyboard, notifikasi, chatbot) bisa memproses jawaban berdasarkan isi Otak ini.
- Sub-fitur:
  - **Auto-summary saat upload**: begitu file diupload, langsung dikasih ringkasan singkat + key topics.
  - **Multi-folder/Otak per topik**: misal "Otak Fisika" vs "Otak Skripsi" — supaya konteks tidak tercampur saat user multitasking banyak topik.
  - **Citation ke sumber**: setiap jawaban chatbot dari Otak menyertakan referensi ("dari halaman X file Y") agar user percaya jawaban bukan halusinasi AI.

### 3.6 Chatbot Winatra

- Merepresentasikan "Winatra" — berbicara berdasarkan isi Otak yang diupload user.
- **Reset konteks mingguan** (bukan harian) — supaya chatbot punya waktu cukup mengenal gaya belajar/kebiasaan user secara lebih mendalam sebelum konteks direset.
- Secara tidak langsung, user "melatih" chatbot lewat isi Otak yang mereka upload.

### 3.7 AI Offline

- Fitur dari proyek sebelumnya (kandidat: Gemma 2B).
- Status: `[TBD]` — belum diputuskan worth it atau tidak untuk versi ini.

---

## 4. Sistem Tier, Kuota & Monetisasi

### 4.1 Tier

| Tier | Kuota dasar | Catatan |
|---|---|---|
| **Free** | 7x tanya (lintas semua fitur — lihat `[TBD]` di bagian 7) | Setelah habis, bisa tonton iklan reward untuk +2 kuota tambahan |
| **Premium** | `[TBD]` — belum detail | — |
| **Legend** | `[TBD]` — belum detail | Bebas dari iklan wajib harian |

- Kuota gabungan dalam **1 pool**, bukan reset ketat harian saja — bisa nambah dari sumber lain (streak, referral, dst), tapi basis reset utama tetap harian. **Kecuali Chatbot Winatra** yang resetnya mingguan (lihat 3.6).
- Sebelumnya diimplementasikan dengan **Firebase** (free tier) untuk auth & data tier user.

### 4.2 Device Binding

- **1 akun = 1 HP.**
- Jika user mau pindah HP: **wajib logout dulu di device lama** sebelum bisa login di device baru. Tidak perlu verifikasi admin manual — cukup mekanisme logout-then-login biasa.

### 4.3 Sistem Iklan (2 jenis, jangan digabung logikanya)

**A. Iklan Wajib Harian** (untuk menutup biaya API DeepSeek)
- Tayang **1x per hari**, waktu **acak** (tidak harus pas pertama buka app).
- Syarat tayang: app sedang **di foreground** (dibuka), TAPI **bukan** saat user sedang aktif menggunakan suatu fitur (misal sedang mengetik jawaban) — supaya tidak mengganggu.
- **5 menit sebelum tayang**, muncul notifikasi/toast kecil peringatan: "Iklan akan muncul sebentar lagi."
- Tidak memberi tambahan kuota — murni untuk pendapatan platform.
- **Wajib untuk tier Free & Premium. Legend bebas dari iklan ini.**
- **Tidak boleh pakai AdMob** (dianggap ribet, harus daftar, dll) — cari ad network alternatif yang free-tier friendly.

**B. Iklan Reward** (on-demand, menambah kuota)
- Muncul saat user Free kena limit kuota (misal habis 7x).
- User pilih nonton → dapat **+2 kuota**.
- Tidak dijadwalkan — murni permintaan user.
- **Di setiap kesempatan iklan/upsell, selalu tawarkan opsi upgrade ke tier lebih tinggi** — tawarkan terus (dalam batas wajar UX) sampai user menolak/berhenti.

**Catatan ekonomi iklan** (referensi untuk estimasi revenue, bukan janji pasti):
- Dihitung per eCPM (revenue per 1000 tayangan yang completed), bukan per-tonton individual.
- Rewarded video eCPM di negara tier-1 bisa $15-30, tapi rata-rata global $8-18.
- Indonesia (tier-2/3 market) realistisnya sekitar **$3-10 per 1000 tayangan** → kira-kira **Rp50-150 per tayangan selesai** (kasar, tergantung fill rate & network yang dipilih).
- Implikasi: revenue signifikan butuh volume user besar, bukan dari sedikit user. Retensi lebih penting daripada eCPM jangka pendek — jangan monetisasi terlalu agresif.

### 4.4 Gamifikasi & Retensi

**Streak**
- Interaksi harian bertujuan belajar (bukan sekadar buka app) menambah streak, ditampilkan di Home (misal "🔥 5 hari beruntun").
- Skip sehari → streak reset ke 0.
- Logic murni lokal (cek timestamp interaksi terakhir), tidak makan API.
- **Reward streak: bonus kuota** (bukan cuma badge visual) di milestone tertentu (7 hari, 30 hari, dst) — pakai pattern gamifikasi standar yang sudah terbukti (ala Duolingo), tidak reinvent.
- Saat kuota habis padahal streak tinggi, tampilkan pesan upsell yang lebih personal/menyentuh dibanding upsell generik (misal: "Streak 12 hari kamu kepotong nih kalau berhenti sekarang, upgrade dong").

**Mode Ujian** — lihat 3.1.

**Referral**
- Minimal **mengundang 3 orang** (harus berhasil daftar) untuk dapat reward.
- **Yang mengundang**: dapat bonus **10 kuota**.
- **Yang diundang** (user baru): dapat bonus **5 kuota** (starting bonus).

**Trial Premium**
- **3 hari full-access**, sekali seumur akun.

### 4.5 Infrastruktur Hemat Biaya

- **Prompt caching** di sisi backend: kalau soal yang sama sering ditanya banyak user (misal soal ujian nasional standar), simpan jawaban di Firestore agar tidak perlu panggil API DeepSeek berulang untuk pertanyaan identik/mirip.
- **Rate-limit per-device fingerprint**, bukan hanya per-akun — mencegah user membuat akun baru untuk reset kuota gratis.

---

## 5. Prinsip Teknis Wajib

1. **Budget Rp0** — semua layanan pihak ketiga harus gratis/free-tier, kecuali biaya API DeepSeek.
2. **Hybrid logic**: prioritaskan logic native/Python untuk tugas yang tidak butuh reasoning AI (misal: cek streak, jadwal notifikasi, deteksi app aktif) — panggil API DeepSeek hanya saat benar-benar perlu, untuk menghemat token/biaya.
3. **No AdMob** — pilih ad network alternatif.
4. **Firebase** dipakai untuk auth, data user/tier, device-binding (proven dari proyek sebelumnya, free-tier).
5. Keyboard harus benar-benar berfungsi sebagai keyboard sistem, bukan overlay — riset implementasi open-source dari GitHub sebelum membangun dari nol.
6. Semua fitur baru mengikuti tema visual electric blue + neon.

---

## 6. Flow Aplikasi (End-to-End)

1. **Splash screen** singkat, logo berkilau, teks "Dikembangkan oleh Tim Winatra".
2. Cek status login:
   - Belum login → wajib login dulu.
   - Baru install → wajib setuju **Terms of Service** dulu.
3. Setelah login (baik Free/Premium/Legend) → muncul **pengumuman harian** (bisa diatur dari sisi developer/backend — semacam news feed wajib dilihat, dipakai juga untuk info error/fitur baru).
4. Masuk Home:
   - User bisa atur mode aktif (Pelajar/Daily/Ujian), logout, dsb.
5. Selama pemakaian app:
   - **Fitur Otak** aktif sebagai basis pengetahuan lintas fitur (keyboard, notifikasi, chatbot semua bisa akses).
   - **AI Popup** aktif secara kontekstual sesuai app yang dibuka user (termasuk saat di luar app Winatra).
   - Notifikasi mengambang aktif sesuai mode yang dipilih.
   - Keyboard Winatra tersedia sebagai keyboard default (jika diaktifkan user di setting Android — app harus mengarahkan user agar tidak bingung saat setting).

---

## 7. Keputusan Terbuka `[TBD]` — Harus Dikonfirmasi ke User, Jangan Diasumsikan AI Agent

- [ ] Detail kuota & benefit lengkap tier **Premium** dan **Legend** (baru "bebas iklan wajib" untuk Legend yang fix; sisanya belum).
- [ ] Apakah kuota 7x di tier Free berlaku **lintas semua fitur** (dibagi rata) atau **per-fitur** (masing-masing fitur punya kuota sendiri).
- [ ] Detail penuh arsitektur & scope **Winatra Asisten** (accessibility service) — sesi pendalaman terpisah belum dilakukan.
- [ ] Nama final untuk "Mode Pelajar" dan "Mode Daily" (saat ini masih placeholder).
- [ ] Keputusan final soal **AI Offline** (Gemma 2B) — worth it atau tidak untuk versi ini.
- [ ] Pilihan ad network pengganti AdMob yang free-tier friendly.
- [ ] Detail stack teknis (bahasa, framework Android — native/Flutter/dll, struktur backend) — belum dibahas di sesi spec ini.

---

## 8. Changelog Dokumen

- **v1.0** — Blueprint awal disusun dari sesi brainstorming pertama, mencakup branding, 4 fitur inti + Otak/Chatbot/AI Offline, sistem tier & monetisasi, gamifikasi, dan flow aplikasi dasar.
