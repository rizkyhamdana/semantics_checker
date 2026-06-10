# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-06-10

### Added
- Fitur **Smart Filtering** untuk widget kondisional (`ListTile`, `GestureDetector`, `InkWell`, `InkResponse`). Pemeriksaan semantics hanya diwajibkan jika widget mendefinisikan aksi interaktif (parameter callback diawali kata `on` seperti `onTap`, `onLongPress`, dll) dengan nilai tidak null.
- Menambahkan `Switch`, `Checkbox`, dan `InkResponse` ke daftar default target widgets.

## [1.0.0] - 2026-06-09

### Added
- Rilis pertama Semantics Checker dengan pendeteksian AST parsing, integrasi Git incremental, dan custom config yaml.
- Fitur klasifikasi Warning untuk target widget yang memiliki *default semantics identifier* internal (`default_widgets`).
- Fitur klasifikasi Warning untuk nilai semantics identifier default/fallback (`default_identifiers`).
- Generator PDF, HTML, dan Markdown reports dengan pemisah metrik visual (Amber/Yellow untuk warning, Red untuk error).
- Perubahan exit code CLI: mengembalikan `0` (sukses) jika hanya ditemukan Warning dan tidak ada blocking Error.
