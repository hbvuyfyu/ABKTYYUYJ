import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt, { SignOptions } from 'jsonwebtoken';
import prisma, { withDb } from '../utils/prisma';

function makeToken(payload: object): string {
  const secret = process.env.JWT_SECRET || 'secret';
  const opts: SignOptions = { expiresIn: (process.env.JWT_EXPIRES_IN || '30d') as SignOptions['expiresIn'] };
  return jwt.sign(payload, secret, opts);
}

function errMsg(err: unknown): string {
  return err instanceof Error ? err.message : String(err);
}

export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password, name } = req.body;
    if (!email || !password) {
      res.status(400).json({ success: false, message: 'البريد الإلكتروني وكلمة المرور مطلوبان' });
      return;
    }
    if (typeof email !== 'string' || !email.includes('@')) {
      res.status(400).json({ success: false, message: 'صيغة البريد الإلكتروني غير صحيحة' });
      return;
    }
    if (typeof password !== 'string' || password.length < 6) {
      res.status(400).json({ success: false, message: 'كلمة المرور يجب أن تكون 6 أحرف على الأقل' });
      return;
    }

    const existing = await withDb(() => prisma.user.findUnique({ where: { email: email.toLowerCase().trim() } }));
    if (existing) {
      res.status(409).json({ success: false, message: 'البريد الإلكتروني مسجل مسبقاً' });
      return;
    }

    const hashed = await bcrypt.hash(password, 10);
    const user = await withDb(() =>
      prisma.user.create({
        data: { email: email.toLowerCase().trim(), password: hashed, name: name?.trim() || null },
        select: { id: true, email: true, name: true, role: true, createdAt: true },
      })
    );
    const token = makeToken({ id: user.id, email: user.email, role: user.role });
    res.status(201).json({ success: true, data: { user, token } });
  } catch (err) {
    console.error('[register]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر، حاول مرة أخرى' });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      res.status(400).json({ success: false, message: 'البريد الإلكتروني وكلمة المرور مطلوبان' });
      return;
    }

    const user = await withDb(() =>
      prisma.user.findUnique({ where: { email: String(email).toLowerCase().trim() } })
    );

    if (!user) {
      res.status(401).json({ success: false, message: 'البريد الإلكتروني أو كلمة المرور غير صحيحة' });
      return;
    }
    if (!user.isActive) {
      res.status(403).json({ success: false, message: 'الحساب موقوف، تواصل مع الدعم' });
      return;
    }

    const valid = await bcrypt.compare(String(password), user.password);
    if (!valid) {
      res.status(401).json({ success: false, message: 'البريد الإلكتروني أو كلمة المرور غير صحيحة' });
      return;
    }

    const token = makeToken({ id: user.id, email: user.email, role: user.role });
    res.json({
      success: true,
      data: {
        user: { id: user.id, email: user.email, name: user.name, role: user.role },
        token,
      },
    });
  } catch (err) {
    console.error('[login]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر، حاول مرة أخرى' });
  }
};

export const getMe = async (req: any, res: Response): Promise<void> => {
  try {
    const user = await withDb(() =>
      prisma.user.findUnique({
        where: { id: req.user.id },
        select: { id: true, email: true, name: true, role: true, createdAt: true },
      })
    );
    if (!user) {
      res.status(404).json({ success: false, message: 'المستخدم غير موجود' });
      return;
    }
    res.json({ success: true, data: user });
  } catch (err) {
    console.error('[getMe]', errMsg(err));
    res.status(500).json({ success: false, message: 'خطأ في السيرفر' });
  }
};

// One-time endpoint: promote any user to ADMIN using the JWT_SECRET as the setup key
// Usage: POST /api/auth/promote-admin  { "email": "...", "setupKey": "<JWT_SECRET value>" }
export const promoteToAdmin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, setupKey } = req.body;
    const expectedKey = process.env.JWT_SECRET || 'secret';
    if (!setupKey || setupKey !== expectedKey) {
      res.status(403).json({ success: false, message: 'Invalid setup key' });
      return;
    }
    const user = await withDb(() => prisma.user.findUnique({ where: { email } }));
    if (!user) {
      res.status(404).json({ success: false, message: 'User not found' });
      return;
    }
    const updated = await withDb(() =>
      prisma.user.update({
        where: { email },
        data: { role: 'ADMIN' },
        select: { id: true, email: true, name: true, role: true },
      })
    );
    const token = makeToken({ id: updated.id, email: updated.email, role: updated.role });
    res.json({ success: true, data: { user: updated, token, message: 'User promoted to ADMIN. Use the new token.' } });
  } catch (err) {
    console.error('[promoteToAdmin]', errMsg(err));
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
