import { Router } from 'express';
import jwt from 'jsonwebtoken';
import { query } from '../db.js';
import { encryptToken } from '../lib/crypto.js';
import { exchangeCodeForToken, fetchGitHubUser } from '../lib/githubClient.js';

export const authRouter = Router();

authRouter.post('/github/oauth/exchange', async (req, res) => {
  const { code } = req.body;
  if (!code) return res.status(400).json({ error: 'Missing code' });

  try {
    const accessToken = await exchangeCodeForToken(code);
    const githubUser = await fetchGitHubUser(accessToken);

    const existing = await query('select * from users where github_id = $1', [githubUser.id]);
    let userRow;
    if (existing.rows.length > 0) {
      userRow = (
        await query(
          'update users set access_token_encrypted = $1, github_username = $2 where github_id = $3 returning *',
          [encryptToken(accessToken), githubUser.login, githubUser.id],
        )
      ).rows[0];
    } else {
      userRow = (
        await query(
          'insert into users (github_id, github_username, access_token_encrypted) values ($1, $2, $3) returning *',
          [githubUser.id, githubUser.login, encryptToken(accessToken)],
        )
      ).rows[0];
    }

    const sessionToken = jwt.sign({ sub: userRow.id }, process.env.SESSION_JWT_SECRET, { expiresIn: '30d' });

    res.json({
      session_token: sessionToken,
      user: {
        id: userRow.id,
        github_id: userRow.github_id,
        github_username: userRow.github_username,
        avatar_url: githubUser.avatar_url,
        created_at: userRow.created_at,
      },
    });
  } catch (err) {
    console.error('OAuth exchange failed', err);
    res.status(500).json({ error: 'GitHub OAuth exchange failed' });
  }
});