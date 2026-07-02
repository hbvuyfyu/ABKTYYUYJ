import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  // Create admin user
  const adminPassword = await bcrypt.hash('Admin@123456', 10);
  const admin = await prisma.user.upsert({
    where: { email: 'charlegilmore75@gmail.com' },
    update: {},
    create: {
      email: 'charlegilmore75@gmail.com',
      password: adminPassword,
      name: 'Admin',
      role: 'ADMIN',
    },
  });
  console.log('Admin created:', admin.email);

  // Create plans
  const plans = [
    {
      name: 'Daily',
      nameAr: 'اليومية',
      durationDays: 1,
      dailyOperations: 5,
      price: 5.0,
    },
    {
      name: 'Weekly',
      nameAr: 'الأسبوعية',
      durationDays: 7,
      dailyOperations: 10,
      price: 10.0,
    },
    {
      name: 'Monthly',
      nameAr: 'الشهرية',
      durationDays: 30,
      dailyOperations: 15,
      price: 20.0,
    },
  ];

  for (const plan of plans) {
    await prisma.plan.upsert({
      where: { id: plan.name.toLowerCase() },
      update: plan,
      create: { id: plan.name.toLowerCase(), ...plan },
    });
  }
  console.log('Plans created');

  // Create default settings
  const defaultSettings = [
    { key: 'app_name', value: 'GAME EVENT', group: 'general' },
    { key: 'app_name_ar', value: 'جيم إيفنت', group: 'general' },
    { key: 'sham_cash_address', value: '0900000000', group: 'payment' },
    { key: 'syriatel_cash_address', value: '0930000000', group: 'payment' },
    { key: 'usdt_bep20_address', value: 'TRx...USDT_ADDRESS_HERE', group: 'payment' },
    { key: 'sham_cash_instructions', value: 'قم بإرسال المبلغ إلى رقم Sham Cash المذكور ثم ارفع صورة الإيصال', group: 'payment' },
    { key: 'syriatel_cash_instructions', value: 'قم بإرسال المبلغ إلى رقم Syriatel Cash المذكور ثم ارفع صورة الإيصال', group: 'payment' },
    { key: 'usdt_instructions', value: 'قم بإرسال المبلغ بالـ USDT على شبكة BEP20 ثم أدخل رقم المعاملة TXID', group: 'payment' },
    { key: 'cloudinary_cloud_name', value: '', group: 'cloudinary' },
    { key: 'cloudinary_api_key', value: '', group: 'cloudinary' },
    { key: 'cloudinary_api_secret', value: '', group: 'cloudinary' },
    { key: 'bscscan_api_key', value: '', group: 'blockchain' },
    { key: 'usdt_contract_address', value: '0x55d398326f99059fF775485246999027B3197955', group: 'blockchain' },
    { key: 'min_usdt_confirmations', value: '1', group: 'blockchain' },
  ];

  for (const setting of defaultSettings) {
    await prisma.settings.upsert({
      where: { key: setting.key },
      update: { value: setting.value, group: setting.group },
      create: setting,
    });
  }
  console.log('Settings created');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
