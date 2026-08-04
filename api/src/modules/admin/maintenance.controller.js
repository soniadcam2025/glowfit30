import { logAdminAction } from '../../utils/adminLog.js';
import { sendError, sendSuccess } from '../../utils/response.js';
import * as svc from './maintenance.service.js';

/** The exact phrase the client must echo back, per reset scope. */
const CONFIRM_PHRASES = {
  workouts: 'DELETE ALL WORKOUTS',
  diet: 'DELETE ALL DIET PLANS',
  'glow-reads': 'DELETE ALL GLOW READS',
  'workout-library': 'DELETE WORKOUT LIBRARY',
  'glow-content': 'DELETE ALL GLOW CONTENT',
};

const RESET_HANDLERS = {
  workouts: (opts) => svc.resetWorkouts(opts),
  diet: (opts) => svc.resetDietPlans(opts),
  'glow-reads': (opts) => svc.resetGlowReads(opts),
  'workout-library': (opts) => svc.resetWorkoutLibrary(opts),
  'glow-content': (opts) => svc.resetGlowContent(opts),
};

export async function counts(req, res, next) {
  try {
    return sendSuccess(
      res,
      { ...(await svc.tableCounts()), tables: svc.BACKUP_TABLES },
      'OK',
    );
  } catch (e) {
    next(e);
  }
}

export async function storage(req, res, next) {
  try {
    return sendSuccess(res, svc.storageConfig(), 'OK');
  } catch (e) {
    next(e);
  }
}

export async function backup(req, res, next) {
  try {
    // `?tables=a,b,c` selects a subset; omitting it exports everything.
    const requested = String(req.query.tables ?? '')
      .split(',')
      .map((t) => t.trim())
      .filter(Boolean)
      .filter((t) => svc.BACKUP_TABLES.includes(t));

    const wb = await svc.buildBackupWorkbook(requested);
    const stamp = new Date().toISOString().slice(0, 10);

    res.setHeader(
      'Content-Type',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    res.setHeader(
      'Content-Disposition',
      `attachment; filename="glowfit-backup-${stamp}.xlsx"`,
    );
    // Lets the browser read the filename when the API is on another origin.
    res.setHeader('Access-Control-Expose-Headers', 'Content-Disposition');

    await logAdminAction(req.user.id, 'maintenance.backup.export', {
      tables: requested.length ? requested : 'all',
    });
    await wb.xlsx.write(res);
    return res.end();
  } catch (e) {
    next(e);
  }
}

/**
 * Irreversible bulk delete.
 *
 * Requires the caller to echo an exact scope-specific phrase, so a stray POST
 * — or a UI bug — cannot wipe a table. Every attempt is written to the admin
 * log, including refusals, since a rejected reset attempt is worth seeing.
 */
export async function reset(req, res, next) {
  try {
    const { scope } = req.params;
    const expected = CONFIRM_PHRASES[scope];
    if (!expected) return sendError(res, 'Unknown reset scope', 400);

    if (req.body?.confirm !== expected) {
      await logAdminAction(req.user.id, 'maintenance.reset.refused', { scope });
      return sendError(res, `Confirmation phrase must be exactly "${expected}"`, 400);
    }

    // Media removal defaults on: leaving orphaned objects in the bucket costs
    // storage forever with nothing referencing them.
    const opts = { deleteMedia: req.body?.deleteMedia !== false };

    const result = await RESET_HANDLERS[scope](opts);

    await logAdminAction(req.user.id, 'maintenance.reset', { scope, ...result });
    return sendSuccess(res, result, 'Reset complete');
  } catch (e) {
    next(e);
  }
}
