/// GitHub API client.
///
/// Provides functions for interacting with the GitHub REST API.
/// All requests are authenticated with the user's GitHub access token.
///
/// Functions:
/// - exchangeCodeForToken: Exchange OAuth code for access token
/// - fetchGitHubUser: Get authenticated user info
/// - fetchRepos: Get user's repositories
/// - fetchReadme: Get repository README
/// - fetchRepoTree: Get repository file tree
/// - fetchFileContent: Get file contents
/// - fetchCommits: Get recent commits

const GITHUB_API = 'https://api.github.com';

/// Exchange GitHub OAuth authorization code for an access token.
///
/// @param {string} code - Authorization code from GitHub OAuth callback
/// @returns {Promise<string>} GitHub access token
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

/// Fetch the authenticated GitHub user's profile.
///
/// @param {string} accessToken - GitHub access token
/// @returns {Promise<Object>} GitHub user object
export async function fetchGitHubUser(accessToken) {
  const res = await fetch(`${GITHUB_API}/user`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github+json' },
  });
  if (!res.ok) throw new Error(`GitHub /user failed: ${res.status}`);
  return res.json();
}

/// Fetch all repositories for the authenticated user.
///
/// @param {string} accessToken - GitHub access token
/// @returns {Promise<Array>} Array of repository objects
export async function fetchRepos(accessToken) {
  const res = await fetch(`${GITHUB_API}/user/repos?sort=pushed&per_page=100`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github+json' },
  });
  if (!res.ok) throw new Error(`GitHub /user/repos failed: ${res.status}`);
  return res.json();
}

/// Fetch the README file for a repository.
///
/// @param {string} accessToken - GitHub access token
/// @param {string} fullName - Repository full name (owner/repo)
/// @returns {Promise<string|null>} README content or null if not found
export async function fetchReadme(accessToken, fullName) {
  const res = await fetch(`${GITHUB_API}/repos/${fullName}/readme`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github.raw+json' },
  });
  if (!res.ok) return null; // repo may have no README — caller handles it
  return res.text();
}

/// Fetch the file tree for a repository branch.
///
/// @param {string} accessToken - GitHub access token
/// @param {string} fullName - Repository full name (owner/repo)
/// @param {string} branch - Branch name (e.g., 'main')
/// @returns {Promise<Array>} Array of tree entries
export async function fetchRepoTree(accessToken, fullName, branch) {
  const res = await fetch(`${GITHUB_API}/repos/${fullName}/git/trees/${branch}?recursive=1`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github+json' },
  });
  if (!res.ok) return [];
  const data = await res.json();
  return data.tree ?? [];
}

/// Fetch the content of a specific file in a repository.
///
/// @param {string} accessToken - GitHub access token
/// @param {string} fullName - Repository full name (owner/repo)
/// @param {string} path - File path within the repository
/// @returns {Promise<string|null>} File content or null if not found
export async function fetchFileContent(accessToken, fullName, path) {
  const res = await fetch(`${GITHUB_API}/repos/${fullName}/contents/${path}`, {
    headers: { Authorization: `Bearer ${accessToken}`, Accept: 'application/vnd.github.raw+json' },
  });
  if (!res.ok) return null;
  return res.text();
}