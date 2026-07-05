import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware';
import {
  listProxies,
  createProxy,
  updateProxy,
  deleteProxy,
  testProxy,
  selectProxy,
  clearProxySelection,
} from '../controllers/proxy.controller';

const router = Router();
router.use(authenticate);

router.get('/', listProxies);
router.post('/', createProxy);
router.put('/:id', updateProxy);
router.delete('/:id', deleteProxy);
router.post('/:id/test', testProxy);
router.post('/:id/select', selectProxy);
router.post('/clear-selection', clearProxySelection);

export default router;
