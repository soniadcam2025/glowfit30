import { Router } from 'express';
import multer from 'multer';
import { verifyToken, requireRole } from '../../middleware/auth.js';
import { sendError } from '../../utils/response.js';
import * as ctrl from './uploads.controller.js';

function handleMulterErrors(err, _req, res, next) {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return sendError(res, 'File is too large', 400);
    }
    return sendError(res, err.message, 400);
  }
  if (err) {
    return sendError(res, err.message || 'Upload failed', 400);
  }
  next();
}

const uploadImage = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter(_req, file, cb) {
    if (!file.mimetype.startsWith('image/')) {
      return cb(new Error('Only image files are allowed'));
    }
    cb(null, true);
  },
});

const uploadVideo = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 100 * 1024 * 1024 },
  fileFilter(_req, file, cb) {
    if (file.mimetype !== 'video/mp4') {
      return cb(new Error('Only MP4 video files are allowed'));
    }
    cb(null, true);
  },
});

const router = Router();

router.use(verifyToken, requireRole('admin', 'super_admin'));

router.post('/', uploadImage.single('file'), handleMulterErrors, ctrl.upload);
router.post('/video', uploadVideo.single('file'), handleMulterErrors, ctrl.uploadVideo);

export default router;
