/// Chomp Server - Main Entry Point
///
/// Express server that provides the backend API for the Chomp app.
/// Handles:
/// - GitHub OAuth authentication
/// - Repository synchronization
/// - Manual scan triggers via SSE
/// - Feed and alerts retrieval
/// - FCM device token registration
/// - Internal cron endpoint for hourly scans
///
/// Requires Node 18+ (uses global fetch).

import express from 'express';
import 'dotenv/config';
import { authRouter } from './routes/auth.js';
import { reposRouter } from './routes/repos.js';
import { scanRouter } from './routes/scan.js';
import { feedRouter } from './routes/feed.js';
import { notificationsRouter } from './routes/notifications.js';
import { internalCronRouter } from './routes/internalCron.js';

const app = express();

// Parse JSON request bodies
app.use(express.json());

// Mount route handlers
app.use(authRouter);
app.use(reposRouter);
app.use(scanRouter);
app.use(feedRouter);
app.use(notificationsRouter);
app.use(internalCronRouter);

// Health check endpoint
app.get('/health', (req, res) => res.json({ ok: true }));

// Start server
const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Chomp server listening on :${port}`));