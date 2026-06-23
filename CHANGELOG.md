# Changelog — cs-agent-pro

## 1.0.0 (2026-06-23)
- Rilis awal sebagai OpenClaw skill (Tier-1 advisory), dibangun dari CS Agent Template v3.0.
- **Operating manual** (engine 12-seksi): grounding anti-halusinasi + skrip fallback, kerangka komplain HEARD/LAST/Feel-Felt-Found, eskalasi *warm-handoff*, guardrail keamanan (identity-lock, anti prompt-injection, PII), kerangka aksi bertingkat + guardrail pembayaran, few-shot good/bad, prioritas final.
- **Knowledge pack** plug-and-play (data wajib + opsional + 9 modul kapabilitas) — satu-satunya bagian yang diisi pemilik; hidup di workspace (aman saat upgrade).
- **Onboarding wizard** + **checklist kesiapan** (termasuk uji red-team) + **roadmap kematangan**.
- **Hook `onboarding-gate`** (event `command:new` + `message:received`): proaktif memicu wizard onboarding bila knowledge pack belum terisi — saat sesi baru maupun pesan pertama (mencakup channel bot WA/TG), **sekali per sesi** (guard `Set` id sesi + throttle 60s fallback). Pola hook sama seperti smart-cache; manifest `openclaw.plugin.json`. Backstop: pointer `AGENTS.md` selalu menginstruksikan onboard-first.
- `install.sh` menyemai knowledge pack ke `memory/cs-agent-pro/`, mengaktifkan hook, + menautkan pointer `AGENTS.md`; `uninstall.sh` menonaktifkan hook.
