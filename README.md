# VIP - تطبيق إدارة الأحداث والاشتراكات

<p align="center">
  <strong>VIP</strong> - تطبيق Android احترافي لإدارة الاشتراكات مع نظام دفع متكامل
</p>

---

## المحتويات

- [المتطلبات](#المتطلبات)
- [هيكل المشروع](#هيكل-المشروع)
- [إعداد قاعدة البيانات](#إعداد-قاعدة-البيانات)
- [تشغيل الـ Backend](#تشغيل-الـ-backend)
- [تشغيل تطبيق Flutter](#تشغيل-تطبيق-flutter)
- [بناء APK](#بناء-apk)
- [بيانات الأدمن](#بيانات-الأدمن)
- [النشر على Railway](#النشر-على-railway)

---

## المتطلبات

### Backend
- Node.js >= 18
- PostgreSQL >= 14
- npm >= 9

### Mobile
- Flutter SDK >= 3.0.0
- Android Studio / VS Code
- Android SDK (minSdk 21)

---

## هيكل المشروع

```
VIP/
├── backend/                    # Node.js + Express + TypeScript
│   ├── prisma/
│   │   ├── schema.prisma       # Prisma schema
│   │   ├── seed.ts             # Seed data
│   │   └── migrations/
│   │       ├── 001_init.sql    # SQL migration
│   │       └── 002_add_games.sql
│   ├── src/
│   │   ├── controllers/        # Business logic
│   │   ├── data/               # Games & events data
│   │   ├── middleware/         # Auth middleware
│   │   ├── routes/             # API routes
│   │   └── index.ts            # Entry point
│   ├── package.json
│   └── .env.example
│
├── mobile/                     # Flutter Android App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── auth/           # Login, Register
│   │   │   ├── home/           # Home screen
│   │   │   ├── subscription/   # Plans
│   │   │   ├── payment/        # Payment screens
│   │   │   ├── engine/         # Engine (Root required)
│   │   │   ├── profile/        # User profile
│   │   │   └── admin/          # Admin panel
│   │   ├── widgets/            # Reusable widgets
│   │   ├── services/           # API service
│   │   ├── providers/          # State management
│   │   ├── models/             # Data models
│   │   ├── theme/              # App theme (Black & White 3D)
│   │   └── router/             # Go Router
│   ├── pubspec.yaml
│   └── android/
│
├── database_schema.sql         # Complete SQL schema (single command)
├── .env.example                # Environment variables template
├── nixpacks.toml               # Railway build config
└── railway.toml                # Railway deploy config
```

---

## إعداد قاعدة البيانات

### الطريقة الأسهل: تنفيذ ملف SQL واحد

```bash
# تنفيذ ملف database_schema.sql في PostgreSQL
psql -U postgres -d vip_db -f database_schema.sql
```

هذا الملف ينشئ جميع الجداول والفهارس والقيود والبيانات الأولية في أمر واحد.

---

## تشغيل الـ Backend

### 1. إعداد المتغيرات البيئية

```bash
cp .env.example .env
# عدّل قيم DATABASE_URL و JWT_SECRET في .env
```

### 2. تثبيت وتشغيل

```bash
cd backend
npm install
npm run prisma:generate
npm run prisma:seed
npm run dev
```

الـ Backend سيعمل على: `http://localhost:3000`

---

## تشغيل تطبيق Flutter

### 1. إعداد عنوان الـ API

في ملف `mobile/lib/services/api_service.dart`:

```dart
// للمحاكي (Emulator)
static const String baseUrl = 'http://10.0.2.2:3000/api';

// للجهاز الحقيقي - ضع IP جهازك
static const String baseUrl = 'http://192.168.1.x:3000/api';
```

### 2. تثبيت وتشغيل

```bash
cd mobile
flutter pub get
flutter run
```

---

## بناء APK

```bash
cd mobile
flutter build apk --release
```

ستجد الـ APK في:
```
mobile/build/app/outputs/flutter-apk/app-release.apk
```

---

## بيانات الأدمن

```
البريد الإلكتروني: admin@vip.app
كلمة المرور: Admin@123456
```

---

## النشر على Railway

1. اربط المستودع بـ Railway
2. أضف المتغيرات من ملف `.env.example`
3. Railway سيقوم ببناء ونشر الـ Backend تلقائياً
4. استخدم `database_schema.sql` لإنشاء الجداول في قاعدة البيانات

---

## الميزات

- تصميم أسود وأبيض عصري ثلاثي الأبعاد
- نظام اشتراكات متكامل (يومي، أسبوعي، شهري)
- طرق دفع متعددة (Sham Cash, Syriatel Cash, USDT BEP20)
- محرك Engine يعمل بصلاحيات Root
- أكثر من 50 لعبة مع 10 أحداث لكل لعبة (540+ حدث)
- لوحة أدمن كاملة
- دعم كامل للغة العربية (RTL)

---

## التقنيات المستخدمة

### Backend
- Node.js + Express + TypeScript
- Prisma ORM + PostgreSQL
- JWT للمصادقة
- bcryptjs لتشفير كلمات المرور
- Cloudinary لرفع الصور

### Mobile (Flutter)
- Provider لإدارة الحالة
- Go Router للتنقل
- Google Fonts (Cairo) للخطوط العربية
- تصميم Black & White 3D احترافي
