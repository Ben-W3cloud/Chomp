const GITHUB_API = 'https://api.github.com';

export async function exchangeCodeForToken(code) {
  const res = await fetch('https://github.com/login/oauth/access_token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
    body: JSON.stringify({
      client_id: process.env.GITHUB_CLIENT_ID,
      client_secret: process.env.GITHUB_CLIENT_SECRET,
      code,
    }),
  });
  const data = await res.json();
  if (!data.access_token) {
    throw new Error(`GitHub token exchange failed: ${JSON.stringify(data)}`);
  }
  return data.access_token;
}

export async function fetchGitHubUser(accessToken) {
  const res = await fetch(`${GITHUB_API}/user`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github+json' },
  });
  if (!res.ok) throw new Error(`GitHub /user failed: ${res.status}`);
  return res.json();
}

export async function fetchRepos(accessToken) {
  const res = await fetch(`${GITHUB_API}/user/repos?sort=pushed&per_page=100`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github+json' },
  });
  if (!res.ok) throw new Error(`GitHub /user/repos failed: ${res.status}`);
  return res.json();
}

export async function fetchReadme(accessToken, fullName) {
  const res = await fetch(`${GITHUB_API}/repos/${fullName}/readme`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github.raw+json' },
  });
  if (!res.ok) return null; // repo may have no README — caller handles it
  return res.text();
}

export async function fetchRepoTree(accessToken, fullName, branch) {
  const res = await fetch(`${GITHUB_API}/repos/${fullName}/git/trees/${branch}?recursive=1`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github+json' },
  });
  if (!res.ok) return [];
  const data = await res.json();
  return data.tree ?? [];
}

export async function fetchFileContent(accessToken, fullName, path) {
  const res = await fetch(`${GITHUB_API}/repos/${fullName}/contents/${path}`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github.raw+json' },
  });
  if (!res.ok) return null;
  return res.text();
}

export async function fetchCommits(accessToken, fullName, since) {
  const url = new URL(`${GITHUB_API}/repos/${fullName}/commits`);
  if (since) url.searchParams.set('since', since);
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github+json' },
  });
  if (!res.ok) return [];
  return res.json();
}