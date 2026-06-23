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

## Checklist pra-rilis (sisi platform — pelengkap checklist di onboarding-and-checklist §B)
- [ ] Faithfulness sampling: > 95% jawaban grounded
- [ ] Escalation correctness: audit ~20 eskalasi/minggu
- [ ] Tone & brand: 0 respons off-brand
- [ ] Red-team: jailbreak / injection / PII-extraction → 0 lolos
- [ ] Action correctness: 0 aksi Tier-2 tanpa konfirmasi

## Sumber
Anthropic & OpenAI (safety/agents/prompting), OWASP Top-10 for LLM Applications 2025, NVIDIA NeMo
Guardrails, Salesforce Einstein Trust Layer, Sierra, Klarna, RAGAS. (Riset internal cs-agent-pro, Juni 2026.)
