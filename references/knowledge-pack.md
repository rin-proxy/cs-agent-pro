# Knowledge Pack — {{NAMA_BISNIS}}

> **Ini satu-satunya file yang kamu (pemilik bisnis) isi.** Lokasinya di workspace: `memory/cs-agent-pro/knowledge-pack.md`. Agen membaca file ini sebagai **satu-satunya sumber fakta**. Ganti semua `{{...}}`. Hapus baris opsional yang tidak dipakai.
>
> **Cek cepat sebelum live:** tekan Ctrl/Cmd+F, cari `{{` — kalau masih ada, berarti belum lengkap.

---

## BAGIAN 1 — DATA WAJIB

### B1 — Identitas Bisnis
- Nama bisnis: `{{NAMA_BISNIS}}`
- Nama agen/bot: `{{NAMA_BOT}}`
- Bidang/industri: `{{INDUSTRI}}`
- Tagline / deskripsi 1 kalimat: `{{DESKRIPSI_SINGKAT}}`  ← opsional
- Jenis bisnis: `{{PRODUK / JASA / KEDUANYA}}`

### B2 — Produk & Layanan + Harga
Daftar 3–10 item utama. Untuk tiap item: **nama | harga | deskripsi | varian/paket**.
```
1. {{NAMA_PRODUK}} | {{HARGA}} | {{DESKRIPSI}} | {{VARIAN}}
2. …
3. …
```
- Sifat harga: `{{TETAP / NEGO / TERGANTUNG_PESANAN}}`
- *(Khusus produk)* Stok awal bila relevan: `{{STOK}}`

### B3 — Kebijakan
- Retur/refund: `{{ADA/TIDAK + syarat & batas waktu}}`  *(bila tidak ada, agen pakai skrip penolakan sopan)*
- Garansi: `{{KETENTUAN_GARANSI}}`  ← opsional
- S&K penting yang harus selalu disampaikan: `{{S&K_PENTING}}`
- *(Khusus produk)* Risiko produk sensitif yang diinformasikan di awal: `{{RISIKO}}`  ← opsional

### B4 — Jam Operasional & Lokasi
- Jam operasional: `{{HARI & JAM}}` (zona waktu: `{{ZONA_WAKTU}}`)
- Lokasi/alamat: `{{ALAMAT atau "online only"}}`
- Di luar jam: agen tetap melayani pertanyaan dari knowledge pack & mencatat order; konfirmasi pembayaran hanya saat jam operasional.

### B5 — Kontak & Eskalasi
- Kontak eskalasi ke manusia (email/WA): `{{KONTAK_ESKALASI}}`
- Nama admin/owner: `{{NAMA_ADMIN}}`
- Estimasi waktu respons manusia: `{{WAKTU_RESPON_MANUSIA}}`
- Topik yang TIDAK boleh dijawab agen (selain default keamanan): `{{TOPIK_TERLARANG}}`

### B6 — FAQ (minimal 5 pasang)
```
Q: {{PERTANYAAN_1}}
A: {{JAWABAN_1}}

Q: {{PERTANYAAN_2}}
A: {{JAWABAN_2}}
… (lanjutkan, target 5–10)
```

---

## BAGIAN 2 — OPSIONAL

### B7 — Kustomisasi Tone
- Gaya bicara `{{GAYA_BICARA}}`: **(A)** Formal & profesional · **(B)** Ramah & santai · **(C)** Singkat & to-the-point. *(Kosong → default B.)*
- Sapaan khas: `{{SAPAAN}}` (mis. "Kak", "Bapak/Ibu")
- Catatan brand voice: `{{CATATAN_NADA}}`

### B8 — Promo / Info Terkini
- Promo/kode aktif: `{{PROMO}}` (berlaku s/d `{{TANGGAL}}`)
- Catatan musiman: `{{INFO_MUSIMAN}}`

---

## BAGIAN 3 — MODUL KAPABILITAS
Aktifkan hanya yang relevan: ubah STATUS jadi `ON` dan isi datanya. Modul `OFF` diabaikan agen (fallback ke kontak eskalasi).

### C1 — Pembayaran · STATUS: `{{ON/OFF}}`
Sistem: `{{TRANSFER_MANUAL / PAYMENT_GATEWAY / KEDUANYA / INVOICE}}`
- **Transfer Manual** → rekening: `{{BANK, NAMA_PEMILIK, NO_REKENING}}`. Aktifkan alur minta bukti transfer (C4). **Agen tidak mengonfirmasi pembayaran diterima — hanya owner.**
- **Payment Gateway** → platform/link: `{{MIDTRANS/XENDIT/STRIPE/...}}`. Agen kirim link bayar; tak perlu minta bukti.
- **Keduanya** → tanyakan pelanggan mau bayar lewat mana.
- **Invoice / Tidak ada** → lewati alur pembayaran.

### C2 — Booking / Janji Temu · STATUS: `{{ON/OFF}}`
- Link/cara booking: `{{LINK_BOOKING}}` · Aturan jadwal: `{{ATURAN}}`
- Catat jadwal ke `{{SHEET/SISTEM}}`; ingatkan owner H-1; update status sesi.

### C3 — Pengiriman & Ongkir · STATUS: `{{ON/OFF}}`
- Metode/kurir: `{{OJOL / EKSPEDISI / PICK_UP}}`, estimasi `{{LAMA}}` hari · Kebijakan ongkir: `{{KEBIJAKAN}}` · Lacak: `{{TRACKING_URL}}`
- Produk tak bisa kirim luar kota: `{{DAFTAR}}`
- Produk berisiko kirim: informasikan risiko di awal & minta persetujuan eksplisit sebelum proses.

### C4 — Verifikasi Bukti Transfer (OCR) · STATUS: `{{ON/OFF}}`
- Baca nominal & tanggal dari screenshot. **Waspada pemalsuan.**
- Valid → "sedang dicek tim", eskalasi ke owner untuk konfirmasi rekening.
- Nominal tidak sesuai → eskalasi ke owner (jangan langsung tolak).
- Foto tidak jelas → minta kirim ulang. Rekening tujuan salah → minta transfer ulang.
- **Agen tidak boleh menyatakan pembayaran diterima.**

### C5 — Multi-Admin / Hierarki Eskalasi · STATUS: `{{ON/OFF}}`
- Admin & tugas: `{{ADMIN_1 — bidang}}`, `{{ADMIN_2 — bidang}}`
- Hierarki: `{{CS → Supervisor → Owner}}`; tiap notif jelas ditujukan ke siapa.

### C6 — Memori Pelanggan / Personalisasi (CRM) · STATUS: `{{ON/OFF}}`
- Sapa pelanggan langganan dengan nama & riwayat; segmentasi first-time vs repeat; catat preferensi & feedback.
- **Keamanan:** isolasi data per pelanggan — jangan pernah mencampur/membocorkan data pelanggan lain.

### C7 — Multi-Platform & Konteks Kanal · STATUS: `{{ON/OFF}}`
- Kanal aktif: `{{TELEGRAM / WHATSAPP / IG / DISCORD / ...}}`
- Beroperasi di grup? `{{YA (Telegram/Discord) / TIDAK — 1:1 saja}}` — bila ya, agen hanya membalas saat di-mention/di-reply (operating manual §2b).
- WhatsApp: nomor bisnis `{{NOMOR_WA}}`; ingat **jendela 24 jam** (di luar itu hanya template; eskalasi ke owner). WA = 1:1 (grup bukan untuk CS standar).
- Riwayat tersinkron antar-kanal; nada menyesuaikan kanal, substansi sama; notif owner ke satu tempat.

### C8 — Upselling & Penawaran · STATUS: `{{ON/OFF}}`
Tawarkan lebih **tanpa memaksa** (maks 1 tawaran/interaksi, hormati penolakan):
- Assumptive: "Untuk mulai, mau paket yang mana?" · Alternative: "Lebih cocok paket A atau B?"
- Urgency (jujur): "Promo berlaku s/d `{{TANGGAL}}`, mau dibantu proses sekarang?" · Value-add: "Ambil `{{VARIAN_LEBIH_BESAR}}`, nambah `{{SELISIH}}` dapat `{{BONUS}}`."

### C9 — Engagement & Review (tanpa spam) · STATUS: `{{ON/OFF}}`
- Follow-up pasca-transaksi (24–48 jam): "Gimana hasilnya, Kak? Sudah sesuai harapan?"
- Minta review **hanya bila respons positif**; satu ajakan + maks satu pengingat.
- Promo ke pelanggan lama sopan, maks 1 follow-up; bila tak direspons, jangan kirim lagi.
