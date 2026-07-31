import { query } from '../db.js';
import { decryptToken } from './crypto.js';
import { scanRepo } from './scanRepo.js';

export async function runHourlyScan() {
  console.log(`[${new Date().toISOString()}] Starting hourly scan...`);
  const watched = await query(
    `select r.*, u.access_token_encrypted from repos r
     join users u on u.id = r.user_id
     where r.is_auto_watched = true or r.is_manually_watched = true`,
  );

  const results = { scanned: 0, failed: 0 };
  for (const repoRow of watched.rows) {
    try {
      const accessToken = decryptToken(repoRow.access_token_encrypted);
      await scanRepo(repoRow, accessToken);
      results.scanned += 1;
    } catch (err) {
      console.error(`Failed to scan ${repoRow.full_name}`, err);
      results.failed += 1; // one bad repo shouldn't block the batch
    }
  }
  console.log(`[${new Date().toISOString()}] Hourly scan complete.`, results);
  return results;
}