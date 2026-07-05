const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const ffmpegPath = require("@ffmpeg-installer/ffmpeg").path;
const ffmpeg = require("fluent-ffmpeg");
const os = require("os");
const path = require("path");
const fs = require("fs");

ffmpeg.setFfmpegPath(ffmpegPath);
admin.initializeApp();

/**
 * Extracts a thumbnail frame from every video uploaded under `videos/`
 * and writes it to `thumbnails/{videoId}.jpg`, then records that path on
 * the video's catalog doc. Runs server-side specifically because no
 * client-side approach is reliable here: Flutter Web renders
 * `video_player` as a real HTML `<video>` element composited outside
 * Flutter's own canvas, so `RepaintBoundary.toImage()` can never capture
 * an actual frame from it — confirmed empirically (captures came back as
 * ~250-byte blank PNGs regardless of timing). This sidesteps that
 * entirely and scales the same whether there are 3 videos or a million,
 * since the admin UI never has to do any of this work itself.
 */
exports.generateVideoThumbnail = onObjectFinalized(
  { region: "us-central1", memory: "1GiB", timeoutSeconds: 180 },
  async (event) => {
    const object = event.data;
    const filePath = object.name || "";
    const contentType = object.contentType || "";

    if (!filePath.startsWith("videos/") || !contentType.startsWith("video/")) {
      return;
    }

    const fileName = path.basename(filePath);
    const videoId = fileName.includes(".") ? fileName.slice(0, fileName.lastIndexOf(".")) : fileName;

    const bucket = admin.storage().bucket(object.bucket);
    const tempVideoPath = path.join(os.tmpdir(), fileName);
    const thumbnailFileName = `${videoId}.jpg`;
    const tempThumbnailPath = path.join(os.tmpdir(), thumbnailFileName);
    const thumbnailStoragePath = `thumbnails/${thumbnailFileName}`;

    try {
      logger.info(`[${videoId}] downloading video for thumbnail extraction`);
      await bucket.file(filePath).download({ destination: tempVideoPath });

      await new Promise((resolve, reject) => {
        ffmpeg(tempVideoPath)
          // 1 second in rather than frame 0: many encoders' very first
          // frame is a mostly-black keyframe warm-up artifact.
          .screenshots({
            timestamps: ["1"],
            filename: thumbnailFileName,
            folder: os.tmpdir(),
            size: "480x?",
          })
          .on("end", resolve)
          .on("error", reject);
      });

      logger.info(`[${videoId}] uploading thumbnail`);
      await bucket.upload(tempThumbnailPath, {
        destination: thumbnailStoragePath,
        metadata: { contentType: "image/jpeg" },
      });

      // `set(..., {merge: true})`, not `update()`: the client creates the
      // Storage object before the Firestore catalog doc, so this trigger
      // can legitimately fire before that doc exists yet.
      await admin.firestore().collection("videos").doc(videoId).set(
        { thumbnailPath: thumbnailStoragePath },
        { merge: true },
      );

      logger.info(`[${videoId}] thumbnail ready at ${thumbnailStoragePath}`);
    } catch (error) {
      logger.error(`[${videoId}] thumbnail generation failed`, error);
    } finally {
      for (const p of [tempVideoPath, tempThumbnailPath]) {
        fs.promises.unlink(p).catch(() => {});
      }
    }
  },
);
