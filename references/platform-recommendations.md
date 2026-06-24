# Platform & Engine Recommendations — CS Agent Pro

Operating manual mengatur **perilaku** agen lewat prompt. Tapi sebagian praktik terbaik CS-AI ada
di **level platform/gateway** — tombol yang *tidak bisa* diatur dari prompt. Dokumen ini untuk
**tim teknis/operator** yang menjalankan agen, agar kualitas & keamanan optimal. Skill ini sudah
menangani sisi prompt; bagian di bawah melengkapi di sisi infrastruktur. (Disarankan, bukan wajib.)

## 1. Setelan model
- **Temperature 0.1–0.2** untuk respons CS. Di atas ~0.4, model makin sering berinterpolasi di luar
  knowledge (mengarang). Rendah = lebih patuh ke knowledge pack.
- Batasi max output tokens wajar — respons CS pendek-padat.

## 2. Grounding / RAG (kalau knowledge besar)
- Bila knowledge tumbuh besar, pindah ke **retrieval (RAG)**: pecah dokumen jadi chunk, suntik
  potongan relevan ke context (bukan seluruh knowledge).
- Sertakan **tanggal revisi** di tiap chunk → agen bisa menandai info berpotensi basi (harga/promo).
- **Re-index berkala** (kebijakan harian, spesifikasi produk mingguan).

## 3. Verifikasi kesetiaan (faithfulness) & evaluasi
- **Sampling mingguan** ~100 percakapan (pola Klarna): cek policy-drift, detail mengarang, nada meleset.
- **Evaluator faithfulness**: panggilan LLM kedua / metrik gaya RAGAS — *"apakah jawaban hanya berisi
  klaim yang didukung konteks? YA/TIDAK"*. Skor rendah → arahkan ke review manusia, jangan kirim.
- Target **override-rate < 5%** (berapa persen respons yang akan dikoreksi manusia) sebelum otonomi penuh.

## 4. Supervisor pass (opsional, kuat)
- Jalankan model kecil-cepat (kelas Haiku) sebagai **supervisor** yang mengecek tiap respons
  (grounded? nada? patuh kebijakan?) *sebelum* dikirim. Bila ditandai → regenerasi atau eskalasi.
  (Pola Sierra "Supervisors".)

## 5. Guardrail input (anti-jailbreak/injection sisi platform)
- Pasang **input-rail** sebelum LLM utama: NeMo Guardrails TopicControl, Llama Guard, atau
  JailbreakDetect — menyaring off-topic/jailbreak lebih dini. Operating manual §8 sudah punya
  pertahanan prompt-level; ini lapis kedua di infrastruktur.

## 6. Keamanan aksi/tool di backend
- Default semua tool **read-only**; aksi tulis (refund/cancel/ubah) butuh grant eksplisit + konfirmasi.
- **Validasi parameter tool di kode backend** — perlakukan output LLM sebagai tak-tepercaya (range,
  batas, jumlah record).
- Allowlist egress (tool hanya panggil endpoint terdaftar); auth per-invocation; **audit log** tiap
  pemanggilan; circuit breaker + exponential backoff.
- Tier 2/3 (operating manual §9): konfirmasi eksplisit; Tier 3 hanya dieksekusi manusia.

## 7. PII & isolasi data
- **Mask/tokenize** field sensitif sebelum ke LLM (pola Salesforce Einstein Trust Layer): LLM bernalar
  di atas token, token diselesaikan setelah generasi.
- **Isolasi sesi per pelanggan**; untuk multi-tenant, **namespace vector store per-tenant** — cegah
  data pelanggan lain bocor lewat hasil retrieval.

## 8. Rate limit & anti-abuse
- Batas per-sesi (mis. maks N tool-call/menit, maks N refund-request/sesi); alert pada pola anomali
  (identitas berganti cepat, banjir permintaan refund).

## 9. Multi-bahasa
- Deteksi bahasa di first-pass; balas dalam bahasa pelanggan (operating manual §2/§10 sudah instruksikan).

## 10. Kanal: Telegram & WhatsApp (setup integrasi)
*(Fakta per Juni 2026 — spesifik API berubah; verifikasi ke docs resmi saat deploy.)*

**Ketergantungan inti:** agen hanya bisa berperilaku benar di grup/DM kalau **adapter channel mengirim konteks** — tipe chat (private/group), flag mention/reply, nama kanal, dan untuk WhatsApp status jendela 24 jam. Suntikkan ini ke tiap pesan; tanpa itu agen tak bisa andal tahu dia di grup atau di-mention.

**Telegram** (core.telegram.org/bots):
- **Privacy mode** (BotFather `/setprivacy`): default ON → di grup bot hanya menerima `/cmd@bot`, reply ke pesannya, mention, dan service message. Biarkan ON untuk CS rapi (bot tak "mendengar" semua). Berubah setelah bot di-remove + add ulang.
- `chat.type` = `private` / `group` / `supergroup`. Deteksi mention via `entities` (`bot_command` / `mention`) atau `reply_to_message.from.id == bot`.
- Inline keyboard ± maks 8 tombol/baris, 100 total; `callback_data` ≤ 64 byte. Pakai **HTML parse mode** (escaping MarkdownV2 rawan bikin pesan gagal total).

**WhatsApp** (developers.facebook.com/docs/whatsapp, Cloud API):
- **Jendela layanan 24 jam:** dalam 24 jam sejak pesan terakhir pelanggan → bebas kirim pesan sesi; di luar → wajib **template** yang sudah di-approve (kategori marketing / utility / authentication). Pesan user-initiated gratis; **opt-in wajib** untuk pesan proaktif.
- **Interaktif (batas keras):** reply button **maks 3**; *list* **maks 10 baris** total (≤ 10 section). Judul tombol ≤ 20 char, judul baris list ≤ 24.
- **Format:** `*tebal*` `_miring_` `~coret~` monospace — **bukan** markdown/HTML/heading.
- **Grup:** Cloud API untuk CS pada dasarnya **1:1**. Ada Groups API (sejak Okt 2025, maks 8 peserta, gated via KAM/BSP) untuk sel kecil/VIP — **bukan** untuk CS umum. Perlakukan WhatsApp sebagai 1:1.
- Identitas pelanggan = nomor `from`; field `context` menandai reply ke pesan tertentu.

**Rendering tombol/list = tugas adapter**; agen hanya menyatakan maksud (operating manual §2b/§10).

## Checklist pra-rilis (sisi platform — pelengkap checklist di onboarding-and-checklist §B)
- [ ] Faithfulness sampling: > 95% jawaban grounded
- [ ] Escalation correctness: audit ~20 eskalasi/minggu
- [ ] Tone & brand: 0 respons off-brand
- [ ] Red-team: jailbreak / injection / PII-extraction → 0 lolos
- [ ] Action correctness: 0 aksi Tier-2 tanpa konfirmasi

## Sumber
Anthropic & OpenAI (safety/agents/prompting), OWASP Top-10 for LLM Applications 2025, NVIDIA NeMo
Guardrails, Salesforce Einstein Trust Layer, Sierra, Klarna, RAGAS. (Riset internal cs-agent-pro, Juni 2026.)
