# gp1

Hệ thống quản trị doanh nghiệp GP1


## Mục lục
1. [Thiết lập Firebase & FlutterFire](#1-thiết-lập-firebase--flutterfire)
2. [Code Generation](#2-code-generation)
3. [Chạy ứng dụng](#3-chạy-ứng-dụng)
---

## 1. Thiết lập Firebase & FlutterFire

Cài đặt các công cụ dòng lệnh cần thiết để làm việc với Firebase và FlutterFire CLI.

```bash
npm install -g firebase-tools # Require Node.js
dart pub global activate flutterfire_cli

firebase login
flutterfire configure
```

## 2. Code Generation

Generate api clients and models from backend swagger docs:
```bash
dart run swagger_parser --schema_url <url-to-backend-swagger-docs>
```
or
```bash
make gen-api
```
with SWAGGER_URL config in `.env/make.env`

----
Generate models:
```bash
dart run build_runner build
```

```bash
dart run build_runner watch
```
or
```bash
make build
```
```bash
make rebuild
```

## 3. Chạy ứng dụng

```bash
flutter run [--release] --flavor <FLAVOR> --dart-define-from-file=.env/<ENV>.json
```

**Chú thích:**
* `<FLAVOR>`: Các flavor khả dụng như `development`, `production`.
* `<ENV>`: Tên file môi trường trong thư mục `.env/` (ví dụ: `local`, `dev`, `prod`).

*Ví dụ chạy dev:*

`flutter run --flavor development --dart-define-from-file=.env/dev.json`
