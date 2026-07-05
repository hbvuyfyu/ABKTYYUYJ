import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware';
import {
  createSchedGroup,
  listSchedGroups,
  getSchedGroup,
  stopSchedGroup,
  activateSchedGroup,
  deleteSchedGroup,
  parseLevels,
} from '../controllers/schedule.controller';

const router = Router();

router.use(authenticate);

router.post('/parse-levels', parseLevels);
router.post('/create', createSchedGroup);
router.get('/list', listSchedGroups);
router.get('/:id', getSchedGroup);
router.post('/:id/stop', stopSchedGroup);
router.post('/:id/activate', activateSchedGroup);
router.delete('/:id', deleteSchedGroup);

export default router;
