import { Router } from 'express';
import { getPlans, getAllPlans, updatePlan } from '../controllers/plan.controller';
import { authenticate, isAdmin } from '../middleware/auth.middleware';

const router = Router();
router.get('/', getPlans);
router.get('/all', authenticate, isAdmin, getAllPlans);
router.put('/:id', authenticate, isAdmin, updatePlan);
export default router;
