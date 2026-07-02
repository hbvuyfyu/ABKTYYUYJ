import { Router } from 'express';
import { getPublicSettings, getAllSettings, updateSetting, updateMultipleSettings } from '../controllers/settings.controller';
import { authenticate, isAdmin } from '../middleware/auth.middleware';

const router = Router();
router.get('/payment', getPublicSettings);
router.get('/', authenticate, isAdmin, getAllSettings);
router.put('/bulk', authenticate, isAdmin, updateMultipleSettings);
router.put('/:key', authenticate, isAdmin, updateSetting);
export default router;
