import { Request, Response } from 'express';
import prisma from '../utils/prisma';

export const getPublicSettings = async (_req: Request, res: Response): Promise<void> => {
  try {
    const settings = await prisma.settings.findMany({ where: { group: 'payment' } });
    const result: Record<string, string> = {};
    settings.forEach(s => { result[s.key] = s.value; });
    res.json({ success: true, data: result });
  } catch {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

export const getAllSettings = async (_req: any, res: Response): Promise<void> => {
  try {
    const settings = await prisma.settings.findMany({ orderBy: { group: 'asc' } });
    res.json({ success: true, data: settings });
  } catch {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

export const updateSetting = async (req: any, res: Response): Promise<void> => {
  try {
    const { key } = req.params;
    const { value } = req.body;
    const setting = await prisma.settings.upsert({
      where: { key },
      update: { value },
      create: { key, value, group: req.body.group || 'general' },
    });
    res.json({ success: true, data: setting });
  } catch {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

export const updateMultipleSettings = async (req: any, res: Response): Promise<void> => {
  try {
    const { settings } = req.body;
    if (!Array.isArray(settings)) {
      res.status(400).json({ success: false, message: 'settings must be an array' });
      return;
    }
    for (const s of settings) {
      await prisma.settings.upsert({
        where: { key: s.key },
        update: { value: s.value },
        create: { key: s.key, value: s.value, group: s.group || 'general' },
      });
    }
    res.json({ success: true, message: 'Settings updated' });
  } catch {
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
