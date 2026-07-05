const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const ffmpegPath = require("@ffmpeg-installer/ffmpeg").path;
const ffprobePath = require("@ffprobe-installer/ffprobe").path;
const ffmpeg = require("fluent-ffmpeg");
const os = require("os");
const path = require("path");
const fs = require("fs");

ffmpeg.setFfmpegPath(ffmpegPath);
ffmpeg.setFfprobePath(ffprobePath);
admin.initializeApp();

// The signage hardware currently deployed (an Intel Celeron J1800 — a
// 2013-era low-power chip with no real 4K decode capability) has been
// confirmed via on-device gdb/ffprobe diagnosis (2026-07-05) to play
// video smoothly up to roughly this envelope, and to stutter badly —
// or get mistaken for a stalled pipeline by the playback watchdog and
// skipped early — above it. This is a genuine hardware decode-
// throughput ceiling, not a bug: a 3840x2160@60fps High-profile upload
// demands ~5x the pixel throughput of a 2400x1440@30fps Main-profile
// one that plays perfectly. Since this is the only hardware available
// right now, anything uploaded above this envelope gets an additional
// transcoded copy written to `videos_playback/` for the device to play
// — the original under `videos/` is never modified or deleted, so
// full-quality source is preserved permanently even though the device
// itself only ever sees the resized copy.
const MAX_HEIGHT = 1440;
const MAX_FPS = 30;
const MAX_BITRATE = 12_000_000; // 12 Mbps

function parseFrameRate(rFrameRate) {
  if (!rFrameRate) return 0;
  const [num, den] = rFrameRate.split("/").map(Number);
  if (!den) return num || 0;
  return num / den;
}

function probe(filePath) {
  return new Promise((resolve, reject) => {
    ffmpeg.ffprobe(filePath, (err, data) => (err ? reject(err) : resolve(data)));
  });
}

function transcodeToDeviceEnvelope(inputPath, outputPath) {
  return new Promise((resolve, reject) => {
    ffmpeg(inputPath)
      .videoCodec("libx264")
      .outputOptions([
        "-profile:v main",
        "-level 5.0",
        `-vf scale=-2:'min(${MAX_HEIGHT},ih)'`,
        `-r ${MAX_FPS}`,
        "-b:v 10M",
        "-maxrate 10M",
        "-bufsize 20M",
        "-preset veryfast",
      ])
      .audioCodec("aac")
      .save(outputPath)
      .on("end", resolve)
      .on("error", reject);
  });
}

function extractThumbnail(inputPath, thumbnailFileName) {
  return new Promise((resolve, reject) => {
    ffmpeg(inputPath)
      // 1 second in rather than frame 0: many encoders' very first
      // frame is a mostly-black keyframe warm-up artifact.
      .screenshots({ timestamps: ["1"], filename: thumbnailFileName, folder: os.tmpdir(), size: "480x?" })
      .on("end", resolve)
      .on("error", reject);
  });
}

exports.processUploadedVideo = onObjectFinalized(
  // Must match the Storage bucket's own region (europe-southwest1) — a
  // Storage trigger cannot listen cross-region. Transcoding is much
  // heavier than the old thumbnail-only function, hence the larger
  // memory/CPU/timeout budget.
  { region: "europe-southwest1", memory: "2GiB", cpu: 2, timeoutSeconds: 540 },
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
    const tempTranscodedPath = path.join(os.tmpdir(), `playback-${fileName}`);
    const thumbnailFileName = `${videoId}.jpg`;
    const tempThumbnailPath = path.join(os.tmpdir(), thumbnailFileName);
    const thumbnailStoragePath = `thumbnails/${thumbnailFileName}`;
    const playbackStoragePath = `videos_playback/${videoId}.mp4`;

    try {
      logger.info(`[${videoId}] downloading video`);
      await bucket.file(filePath).download({ destination: tempVideoPath });

      const info = await probe(tempVideoPath);
      const videoStream = info.streams.find((s) => s.codec_type === "video");
      const height = videoStream?.height ?? 0;
      const fps = parseFrameRate(videoStream?.r_frame_rate);
      const bitrate = Number(info.format?.bit_rate ?? 0);

      const exceedsDeviceEnvelope = height > MAX_HEIGHT || fps > MAX_FPS + 1 || bitrate > MAX_BITRATE;

      // The original upload is never modified or deleted, regardless of
      // outcome — only an additional, separate copy is written for
      // playback when the source exceeds the device's decode envelope.
      let playablePath = tempVideoPath;
      let playbackPath = null;
      if (exceedsDeviceEnvelope) {
        logger.info(
          `[${videoId}] exceeds device decode envelope (height=${height}, fps=${fps.toFixed(1)}, ` +
            `bitrate=${bitrate}) — writing a device-safe playback copy, original left untouched`,
        );
        await transcodeToDeviceEnvelope(tempVideoPath, tempTranscodedPath);
        playablePath = tempTranscodedPath;
        await bucket.upload(tempTranscodedPath, { destination: playbackStoragePath, metadata: { contentType: "video/mp4" } });
        playbackPath = playbackStoragePath;
        logger.info(`[${videoId}] playback copy written to ${playbackStoragePath}`);
      }

      await extractThumbnail(playablePath, thumbnailFileName);
      await bucket.upload(tempThumbnailPath, { destination: thumbnailStoragePath, metadata: { contentType: "image/jpeg" } });

      // `set(..., {merge: true})`, not `update()`: the client creates the
      // Storage object before the Firestore catalog doc, so this trigger
      // can legitimately fire before that doc exists yet. `playbackPath`
      // is only ever set here, never cleared — if a since-fixed source
      // gets re-uploaded under a new videoId that's a new doc anyway.
      const fields = { thumbnailPath: thumbnailStoragePath };
      if (playbackPath) fields.playbackPath = playbackPath;
      await admin.firestore().collection("videos").doc(videoId).set(fields, { merge: true });

      logger.info(`[${videoId}] processing complete`);
    } catch (error) {
      logger.error(`[${videoId}] processing failed`, error);
    } finally {
      for (const p of [tempVideoPath, tempTranscodedPath, tempThumbnailPath]) {
        fs.promises.unlink(p).catch(() => {});
      }
    }
  },
);
