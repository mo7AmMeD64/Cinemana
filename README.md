# سينمانا 🎬

تطبيق Flutter لمشاهدة الأفلام والمسلسلات من منصة Cinemana Shabakaty.

## المميزات

- 🏠 **الرئيسية** — مجموعات المحتوى (أحدث، الأعلى تقييماً...)
- 🔍 **البحث** — بحث فوري بالاسم
- 📂 **الأقسام** — تصفح حسب النوع مع infinite scroll
- ⭐ **المفضلة** — محفوظة محلياً
- 🎬 **التفاصيل** — بوستر، معلومات، مواسم، حلقات، روابط جودات

## البناء المحلي

```bash
flutter pub get
flutter build apk --release
```

## البناء عبر GitHub Actions

### 1. رفع المشروع على GitHub

```bash
cd cinemana_app
git init
git add .
git commit -m "initial commit"
git remote add origin https://github.com/USERNAME/cinemana-app.git
git push -u origin main
```

### 2. إضافة Secrets للـ Keystore (اختياري للتوقيع)

اذهب إلى: **Settings → Secrets and variables → Actions → New repository secret**

| Secret | القيمة |
|--------|--------|
| `KEY_STORE` | محتوى ملف `.jks` مشفّر بـ base64 |
| `KEY_STORE_PASSWORD` | كلمة مرور الـ keystore |
| `KEY_ALIAS` | اسم الـ alias |
| `KEY_PASSWORD` | كلمة مرور الـ key |

### تشفير الـ Keystore:

```bash
# في Termux
base64 -w 0 my-keystore.jks
# انسخ الناتج والصقه في SECRET: KEY_STORE
```

### 3. تشغيل الـ Action

- كل push على `main` → بناء تلقائي
- لإنشاء Release: `git tag v1.0.0 && git push --tags`

## الـ API

يعتمد التطبيق على Android API الخاص بـ Cinemana:

```
Base URL: https://cinemana.shabakaty.com/api/android/v2/
```

## المتطلبات

- Flutter 3.22+
- Android minSdk 21 (Android 5.0+)
