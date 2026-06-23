# Plan: Revisi setup-project + README

## 1. Push commit ✅ (done: `fa3155e`)

## 2. Revisi `setup-project` command

**Current behavior**: `py -m farewell_assistant.cli setup-project <url>` → clone ke TEMP/ → detect → register

**Target behavior**: `py -m farewell_assistant.cli setup-project <path>` → detect existing project dari path → register

### File changes needed:

### a) `farewell_assistant/helpers.py`
- Add function `setup_project_from_path(path)` — skip clone, langsung detect + register
- Mark `is_local: True` di registry (untuk membedakan local vs cloned)

### b) `farewell_assistant/cli.py`
- `cmd_setup_project` → panggil `setup_project_from_path(path)` bukan `setup_project_from_url(url)`
- Argparser: `url` → `path`, help text diupdate

## 3. Revisi README.md

**Hapus** section yang terlalu detail tentang model:
- "Available Models" (semua model list table)
- "Config — How NVIDIA Combo Works"
- "Model Routing" table
- "Available Models" local models table

**Keep** yang informatif tentang project:
- Deskripsi project
- Prerequisites
- Installation
- Quick Start / Daily Routines
- Architecture diagram
- Commands table
- Work Mode
- Intent Pipeline (ringkas)
- File Structure
- Tech Stack
- Cost
- License

## 4. Commit

```
git add farewell_assistant/cli.py farewell_assistant/helpers.py README.md
git commit -m "refactor: setup-project terima path lokal, not clone; rapikan README"
```
