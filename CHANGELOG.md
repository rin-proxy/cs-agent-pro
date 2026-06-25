# Changelog — cs-agent-pro

## 1.3.0 (2026-06-25)
- **Selaras dengan standar skill-template (harness Tier-3):** SKILL.md kini punya peta **4 lever**
  (Context · Tools · Loop · Governance) yang membingkai perilaku CS ke vokabular harness.
- **`scripts/check.sh`** — gate kesiapan otomatis (lever Governance): cek knowledge pack terisi
  (tanpa `{{`), aturan eskalasi/pembayaran/anti-injeksi di operating manual, dan deklarasi hook.
  Mengotomatiskan inti **Checklist Kesiapan** — jalankan sebelum go-live. (Uji red-team tetap manual.)

## 1.2.0 (2026-06-24)
- **Operating manual** — seksi baru **§2b "Konteks: grup vs DM & per-kanal"**: di grup balas hanya saat di-mention/di-reply, jangan bocorkan PII di grup (pindah DM), onboarding hanya di DM; penyesuaian format/tombol per-kanal.
- **Fix §10** — batas tombol jadi per-kanal (Telegram ± ≤8/baris; WhatsApp maks 3 / list ≤10) menggantikan angka universal "4–5" yang salah untuk WhatsApp.
- **platform-recommendations** — bagian baru **setup kanal**: Telegram (privacy mode, `chat.type`, mention, HTML) & WhatsApp (jendela 24 jam + template, batas interaktif, status grup 1:1, Cloud API) + ketergantungan adapter mengirim konteks. Berbasis riset docs resmi (Telegram Bot API & WhatsApp Cloud API, Juni 2026).
- **knowledge-pack C7** diperluas (kanal aktif, mode grup/1:1, jendela WA).

## 1.1.0 (2026-06-23)
- **Operating manual** — tambah **playbook skenario sulit** eksplisit di §6 (penolakan refund/retur, komplain berulang, negosiasi diskon, cara berkata "tidak").
- **Referensi baru `platform-recommendations.md`** — praktik level-engine/infrastruktur (suhu model, RAG/grounding, evaluator faithfulness, supervisor-LLM, guardrail-service NeMo/Llama Guard, validasi tool backend, PII tokenization, rate-limit) untuk tim teknis — menampung temuan riset yang tak bisa hidup di prompt.
- README: hapus bagian "Free vs paid".

## 1.0.0 (2026-06-23)
- Rilis awal sebagai OpenClaw skill (Tier-1 advisory), dibangun dari CS Agent Template v3.0.
- **Operating manual** (engine 12-seksi): grounding anti-halusinasi + skrip fallback, kerangka komplain HEARD/LAST/Feel-Felt-Found, eskalasi *warm-handoff*, guardrail keamanan (identity-lock, anti prompt-injection, PII), kerangka aksi bertingkat + guardrail pembayaran, few-shot good/bad, prioritas final.
- **Knowledge pack** plug-and-play (data wajib + opsional + 9 modul kapabilitas) — satu-satunya bagian yang diisi pemilik; hidup di workspace (aman saat upgrade).
- **Onboarding wizard** + **checklist kesiapan** (termasuk uji red-team) + **roadmap kematangan**.
- **Hook `onboarding-gate`** (event `command:new` + `message:received`): proaktif memicu wizard onboarding bila knowledge pack belum terisi — saat sesi baru maupun pesan pertama (mencakup channel bot WA/TG), **sekali per sesi** (guard `Set` id sesi + throttle 60s fallback). Pola hook sama seperti smart-cache; manifest `openclaw.plugin.json`. Backstop: pointer `AGENTS.md` selalu menginstruksikan onboard-first.
- `install.sh` menyemai knowledge pack ke `memory/cs-agent-pro/`, mengaktifkan hook, + menautkan pointer `AGENTS.md`; `uninstall.sh` menonaktifkan hook.
