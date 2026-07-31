/// Standalone cron worker for hourly scans.
///
/// This script runs as a separate process alongside the main server.
/// It uses node-cron to trigger hourly scans of all watched repositories.
///
/// Usage:
///   npm run cron
///
/// This is for deployments where the server runs as a long-lived process
/// (Railway, Render, Fly, VPS, etc.). For serverless deployments, use
/// the HTTP trigger endpoint instead (routes/internalCron.js).

import 'dotenv/config';
import cron from 'node-cron';
import { runHourlyScan } from '../lib/hourlyScan.js';

// Schedule hourly scan to run at the top of every hour
// Cron format: "0 * * * *" = at minute 0 of every hour
cron.schedule('0 * * * *', runHourlyScan);
console.log('Chomp hourly scan cron started (standalone worker mode).');