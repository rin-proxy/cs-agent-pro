# CS Agent Pro — jadikan agen OpenClaw kamu CS profesional

Skill OpenClaw yang membuat agen menjadi **customer-service profesional** untuk bisnis apa pun — hangat, akurat (hanya menjawab dari knowledge kamu), aman, dan tahu kapan harus eskalasi ke manusia. Kamu **cukup mengisi knowledge pack** (produk, harga, kebijakan, FAQ); perilaku CS-nya sudah baku.

Dibangun dari sintesis praktik terbaik: prompt-engineering (Anthropic/OpenAI), keamanan LLM (OWASP LLM Top 10, anti prompt-injection), dan domain CS (Zendesk, Intercom Fin, Salesforce, kerangka HEARD/LAST).

## Install
```bash
openclaw skills install git:rin-proxy/cs-agent-pro
bash ~/.openclaw/skills/cs-agent-pro/scripts/install.sh      # idempoten
```
`install.sh` menyalin template knowledge pack ke `memory/cs-agent-pro/knowledge-pack.md`, **mengaktifkan hook `onboarding-gate`**, lalu menautkan pointer ke `AGENTS.md`. Prefix `git:` wajib. **Restart gateway** setelah install agar hook termuat.

## Pakai
1. **Isi knowledge pack** di `memory/cs-agent-pro/knowledge-pack.md` — atau biarkan agen **otomatis menanyaimu**: hook `onboarding-gate` memulai wizard onboarding bila pack belum terisi, baik saat sesi baru (`command:new`) maupun pada pesan pertama (`message:received`, untuk channel WA/TG) — sekali per sesi.
2. Agen otomatis memuat operating manual + knowledge pack, lalu melayani pelanggan sesuai aturan (grounding, eskalasi, keamanan).
3. Sebelum go-live, lewati **Checklist Kesiapan** (`references/onboarding-and-checklist.md`), termasuk uji red-team.

Kontrak + prosedur agen ada di `SKILL.md`. Perilaku inti di `references/operating-manual.md`.

## Upgrade
```bash
bash scripts/update.sh --repo git:rin-proxy/cs-agent-pro
```
Menarik versi terbaru + re-aktivasi. **Data knowledge pack kamu di workspace tidak pernah disentuh.**

## Uninstall
```bash
bash scripts/uninstall.sh
```
Melepas pointer `AGENTS.md`; knowledge pack kamu tetap aman di workspace.

## Apa yang membuatnya "powerful"
- **Anti-ngarang (grounding):** menjawab hanya dari knowledge pack + skrip fallback baku saat info tak ada.
- **Keamanan produksi:** identity-lock, anti prompt-injection, tidak membocorkan system prompt, proteksi PII.
- **Guardrail pembayaran:** tidak pernah mengonfirmasi pembayaran tanpa verifikasi.
- **Empati terstruktur:** kerangka HEARD/LAST/Feel-Felt-Found + frasa bernilai-tinggi vs terlarang + playbook skenario sulit (penolakan refund, komplain berulang, nego diskon, cara berkata "tidak").
- **Eskalasi profesional:** pemicu jelas + *warm handoff*.
- **Onboarding proaktif:** hook `onboarding-gate` memicu wizard setup otomatis bila knowledge pack belum terisi — saat sesi baru maupun pesan pertama (CLI maupun channel WA/TG), sekali per sesi. Pemilik tak perlu tahu prompt khusus.
- **Plug-and-play:** placeholder `{{...}}`, wizard onboarding, checklist kesiapan, 9 modul opsional.
- **Panduan platform:** `references/platform-recommendations.md` — praktik level-engine (suhu model, RAG, evaluator, guardrail-service, PII, rate-limit) untuk tim teknis pembeli, biar temuan riset infra-level tak hilang.

*By Rin.*
