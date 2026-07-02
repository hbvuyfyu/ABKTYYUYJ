import { Router } from 'express';
import { authenticate } from '../middleware/auth.middleware';
import {
  detectGame, sendEvent, getDailyUsage, listGames,
  adminListGames, adminCreateGame, adminUpdateGame, adminDeleteGame,
  adminAddGameEvent, adminDeleteGameEvent,
} from '../controllers/games.controller';

const router = Router();

// Public
router.get('/detect', detectGame);
router.get('/list', listGames);

// Requires auth
router.post('/send-event', authenticate, sendEvent);
router.get('/daily-usage', authenticate, getDailyUsage);

// Admin game CRUD (handled via admin.routes to keep admin auth in one place)
// These routes are also exported so admin.routes can import them
export {
  adminListGames, adminCreateGame, adminUpdateGame, adminDeleteGame,
  adminAddGameEvent, adminDeleteGameEvent,
};

export default router;
