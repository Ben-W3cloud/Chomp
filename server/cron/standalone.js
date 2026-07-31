import 'dotenv/config';
import cron from 'node-cron';
import { runHourlyScan } from '../lib/hourlyScan.js';

// Use this if the server runs as a long-lived process (Railway, Render,
// Fly, a VPS). Run it as a second process alongside `npm start`:
//   npm run cron
cron.schedule('0 * * * *', runHourlyScan);
console.log('Chomp hourly scan cron started (standalone worker mode).');