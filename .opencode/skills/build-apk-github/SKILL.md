---
name: build-apk-github
description: Build APK/AAB của SubTrack bằng GitHub Actions (Gradle trực tiếp, không cần EAS token). Dùng khi user muốn build APK/AAB trên CI, push code lên GitHub, hoặc lấy artifact APK/AAB từ GH Actions. Gồm workflow hiện có, cách trigger, cách lấy APK/AAB, và cách lấy GitHub token an toàn (KHÔNG commit token vào repo).
---

# Build APK/AAB trên GitHub Actions (SubTrack)

## Repo & context

- **Repo**: `https://github.com/hoangsoft90/SubscriptionTracker` (public)
- **Default branch**: `main`
- **Workflow**: `.github/workflows/build-apk.yml` — build **release APK + AAB** bằng
  Gradle trực tiếp (`flutter build apk --release` + `flutter build appbundle --release`),
  KHÔNG dùng EAS, không cần token EAS.
- Flutter pin `3.44.9` stable + JDK 21 (temurin, qua `actions/setup-java`).
- Kết quả: artifact `subtrack-release-apk` (APK tại
  `build/app/outputs/flutter-apk/app-release.apk`) + artifact `subtrack-release-aab`
  (AAB tại `build/app/outputs/bundle/release/app-release.aab`), retention 30 ngày.

## GitHub token (GH_TOKEN) — an toàn, KHÔNG commit secret

Token dùng cho push + gọi GH Actions API. **Tuyệt đối không hardcode token vào
skill/repo** (repo public — GitHub sẽ tự revoke token bị lộ).

- Nơi lưu: file `.env` ở project root (đã có trong `.gitignore`) với key
  `GH_TOKEN`, HOẶC biến môi trường `GH_TOKEN`.
- Đọc khi cần: `set -a; source .env; set +a` (hoặc `export GH_TOKEN=...`).
- Nếu `.env` không tồn tại hoặc token hết hạn: dừng, hỏi user cung cấp token
  mới — KHÔNG tự đoán.

## Các thao tác chuẩn

### 1. Push code lên repo (kích hoạt build)

```bash
# Branch local phải là `main` (khớp default branch remote)
git checkout -B main
git remote add origin https://github.com/hoangsoft90/SubscriptionTracker.git 2>/dev/null || true
# Dùng token 1 lần cho lệnh push (không lưu token vào remote config)
set -a; source .env; set +a
git push https://hoangsoft90:${GH_TOKEN}@github.com/hoangsoft90/SubscriptionTracker.git main
```

Sau push, workflow `Build APK` tự chạy (trigger: push → `main`).

### 2. Trigger thủ công (không cần push)

```bash
set -a; source .env; set +a
curl -X POST \
  -H "Authorization: Bearer ${GH_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/hoangsoft90/SubscriptionTracker/actions/workflows/build-apk.yml/dispatches \
  -d '{"ref":"main"}'
```

### 3. Theo dõi trạng thái run

```bash
set -a; source .env; set +a
# Lấy run mới nhất + status/conclusion
curl -s -H "Authorization: Bearer ${GH_TOKEN}" \
  https://api.github.com/repos/hoangsoft90/SubscriptionTracker/actions/runs | \
  python3 -c "import json,sys; [print(r['id'], r['name'], r['status'], r['conclusion'], r['html_url']) for r in json.load(sys.stdin)['workflow_runs'][:5]]"
```

Poll đến khi `status=completed` (build Flutter APK thường mất 10–15 phút).

### 4. Tải APK/AAB artifacts

```bash
set -a; source .env; set +a
# Lấy artifact của run gần nhất
ART=$(curl -s -H "Authorization: Bearer ${GH_TOKEN}" \
  "https://api.github.com/repos/hoangsoft90/SubscriptionTracker/actions/artifacts?per_page=1" | \
  python3 -c "import json,sys; d=json.load(sys.stdin); print(d['artifacts'][0]['id'] if d['artifacts'] else '')")
if [ -n "$ART" ]; then
  curl -L -H "Authorization: Bearer ${GH_TOKEN}" \
    -o subtrack-release-artifact.zip \
    "https://api.github.com/repos/hoangsoft90/SubscriptionTracker/actions/artifacts/$ART/zip"
  unzip -o subtrack-release-artifact.zip -d dist-artifacts/
fi
```

Artifact mới nhất theo thứ tự là AAB (upload sau APK) — nếu cần APK, dùng
`?per_page=2` và chọn theo `name` (đã có sẵn từ API response). Để lấy riêng
một artifact theo tên:

```bash
set -a; source .env; set +a
# Lấy APK artifact của run gần nhất
curl -s -H "Authorization: Bearer ${GH_TOKEN}" \
  "https://api.github.com/repos/hoangsoft90/SubscriptionTracker/actions/artifacts?per_page=5" | \
  python3 -c "
import json,sys
for a in json.load(sys.stdin)['artifacts']:
    if a['name'] == 'subtrack-release-apk':
        print(a['id']); break
"
```

(Lưu ý: release hiện ký bằng debug signing config trong
`android/app/build.gradle.kts` — APK/AAB tải về để test nội bộ; khi publish
Play Store cần thêm signing config thật.)

## Ghi chú CI

- `android/gradle.properties` KHÔNG hard-code `org.gradle.java.home` nữa —
  JDK chọn qua `JAVA_HOME` (CI: setup-java; local: export trong `.project/ai-rules.md`).
- `google-services.json` nằm ở root và được commit — build CI cần nó (AdMob).
- Workflow build cả APK + AAB trong 1 run (2 step build, 2 artifact upload).
- Nếu build fail: xem log run qua GH web (`html_url` ở bước 3) hoặc API
  `GET /actions/runs/{id}/jobs`.
