import express from 'express';
import 'dotenv/config';
import { authRouter } from './routes/auth.js';
import { reposRouter } from './routes/repos.js';
import { scanRouter } from './routes/scan.js';
import { feedRouter } from './routes/feed.js';
import { notificationsRouter } from './routes/notifications.js';
import { internalCronRouter } from './routes/internalCron.js';

const app = express();
app.use(express.json());

app.use(authRouter);
app.use(reposRouter);
app.use(scanRouter);
app.use(feedRouter);
app.use(notificationsRouter);
app.use(internalCronRouter);

app.get('/health', (req, res) => res.json({ ok: true }));

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Chomp server listening on :${port}`));