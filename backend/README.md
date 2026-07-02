# GAME EVENT Backend API

  ## 🗄️ ربط قاعدة بيانات Neon PostgreSQL

  ### الخطوة 1: احصل على رابط قاعدة البيانات
  1. افتح موقع [neon.tech](https://neon.tech)
  2. أنشئ مشروعاً جديداً أو افتح مشروعاً موجوداً
  3. اذهب إلى **Dashboard → Connection Details**
  4. انسخ **Connection string** (يبدأ بـ `postgresql://`)

  ### الخطوة 2: أضف متغيرات البيئة
  أنشئ ملف `.env` في مجلد `backend/` بالمحتوى التالي:

  ```env
  DATABASE_URL="postgresql://user:password@ep-xxxx.us-east-1.aws.neon.tech/dbname?sslmode=require"
  JWT_SECRET="اختر-كلمة-سر-عشوائية-طويلة-هنا"
  JWT_EXPIRES_IN="7d"
  PORT=3000
  NODE_ENV=production
  CLOUDINARY_CLOUD_NAME=""
  CLOUDINARY_API_KEY=""
  CLOUDINARY_API_SECRET=""
  BSCSCAN_API_KEY=""
  USDT_CONTRACT_ADDRESS="0x55d398326f99059fF775485246999027B3197955"
  ```

  > ⚠️ **مهم:** استبدل رابط `postgresql://...` برابطك الحقيقي من Neon.

  ### الخطوة 3: إنشاء جداول قاعدة البيانات

  **الطريقة الأولى (الأسرع) - SQL مباشر:**
  انسخ الـ SQL من ملف `prisma/migrations/001_init.sql` وشغّله مباشرة في Neon SQL Editor.

  **الطريقة الثانية - Prisma Migrate:**
  ```bash
  cd backend
  npm install
  npm run prisma:migrate
  ```

  ### الخطوة 4: تشغيل التطبيق

  ```bash
  cd backend
  npm install
  npm run build
  npm start
  ```

  أو في وضع التطوير:
  ```bash
  npm run dev
  ```

  ### الخطوة 5: إضافة البيانات الأولية (اختياري)

  ```bash
  npm run prisma:seed
  ```

  هذا ينشئ:
  - حساب المدير: `charlegilmore75@gmail.com` / `Admin@123456`
  - خطط الاشتراك الافتراضية (يومي، أسبوعي، شهري)
  - الإعدادات الافتراضية

  ---

  ## 🔌 نقاط النهاية (API Endpoints)

  | المسار | الوصف |
  |--------|-------|
  | POST `/api/auth/register` | تسجيل مستخدم جديد |
  | POST `/api/auth/login` | تسجيل الدخول |
  | GET `/api/plans` | قائمة خطط الاشتراك |
  | GET `/api/payments` | المدفوعات |
  | GET `/api/subscriptions` | الاشتراكات |
  | GET `/api/admin/*` | لوحة الإدارة |
  | GET `/api/health` | فحص حالة الخادم وقاعدة البيانات |

  ---

  ## 📱 ربط تطبيق Flutter بالـ Backend

  في ملف `mobile/lib/services/api_service.dart`، غيّر رابط الـ API إلى رابط خادمك:

  ```dart
  static const String baseUrl = 'https://your-server.com/api';
  ```

  ---

  ## 🚀 النشر على خدمات سحابية

  ### Railway
  1. ارفع المستودع على Railway
  2. اضبط متغير البيئة `DATABASE_URL` من Neon
  3. اضبط `PORT` إذا لزم

  ### Render
  1. أنشئ Web Service جديد
  2. Build Command: `npm install && npm run build`
  3. Start Command: `npm start`
  4. أضف `DATABASE_URL` في Environment Variables
  