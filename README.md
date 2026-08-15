# Chomp

GitHub analytics, watched by AI, on your phone.

Chomp is a Flutter mobile app that connects to your GitHub account and uses AI (NVIDIA + Groq) to analyze your repositories for security, code quality, documentation, and test coverage. Repos are automatically rescanned hourly, and you get a clean feed of findings and score changes.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Mobile** | Flutter 3.3+, Dart 3.x |
| **State** | Riverpod (StateNotifier + FutureProvider) |
| **Auth** | GitHub OAuth (FlutterWebAuth2) |
| **Backend** | Node.js, Express |
| **Database** | Neon Postgres (serverless PostgreSQL) |
| **AI** | NVIDIA (code quality + security scoring), Groq (docs + tests evaluation) |
| **Push** | Firebase Cloud Messaging |
| **Deployment** | Render (Node server), Flutter (Android/iOS) |

## Project Structure

```
dev_watch/
├── lib/                          # Flutter client
│   ├── core/                     # Theme, env, constants
│   ├── models/                   # Data models (User, Repo, ScanResult, etc.)
│   ├── providers/                # Riverpod state management
│   ├── screens/                  # UI screens
│   │   ├── feed/                 # Activity feed
│   │   ├── home/                 # Main tab shell + repo list
│   │   ├── onboarding/           # Welcome + GitHub connect
│   │   ├── profile/              # Profile, settings, watchlist manager
│   │   ├── repo_detail/          # Repo detail with scan results
│   │   └── splash/               # Cold-start splash
│   ├── services/                 # API client, auth, data fetching
│   ├── utils/                    # Utility helpers
│   └── widgets/                  # Reusable UI components
├── server/                       # Node.js backend
│   ├── lib/                      # Crypto, scan engine, AI clients
│   ├── middleware/                # Auth middleware, rate limiting
│   └── routes/                   # API route handlers
└── web/                          # Flutter web build artifacts
```

## Setup

### Prerequisites

- Flutter SDK 3.3+
- Node.js 18+
- A Neon Postgres database (or any PostgreSQL instance)
- GitHub OAuth App credentials
- NVIDIA API key
- Groq API key
- Firebase project (for push notifications)

### Client Setup (.env)

Create `dev_watch/.env`:

```env
CHOMP_API_BASE_URL=https://your-backend-domain.com
GITHUB_CLIENT_ID=your_github_oauth_client_id
GITHUB_CALLBACK_SCHEME=chomp
```

### Server Setup (.env)

Create `dev_watch/server/.env`:

```env
PORT=3000
NEON_DATABASE_URL=postgres://user:pass@ep-xxx.us-east-2.aws.neon.tech/db
NEON_DATA_API_URL=https://console.neon.tech/api/v2/...

GITHUB_CLIENT_ID=your_github_oauth_client_id
GITHUB_CLIENT_SECRET=your_github_oauth_client_secret

SESSION_JWT_SECRET=a-random-256-bit-jwt-secret
TOKEN_ENCRYPTION_KEY=a-random-256-bit-key
CRYPTO_SECRET=a-random-256-bit-crypto-secret
CRON_SECRET=a-random-cron-secret
GITHUB_WEBHOOK_SECRET=a-random-webhook-secret

NVIDIA_API_KEY=your_nvidia_api_key
NVIDIA_BASE_URL=https://integrate.api.nvidia.com/v1
NVIDIA_MODEL=meta/llama-3.1-8b-instruct

GROQ_API_KEY=your_groq_api_key
GROQ_BASE_URL=https://api.groq.com/openai/v1
GROQ_MODEL=llama-3.1-8b-instant

FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
```

### Running

**Server:**
```bash
cd dev_watch/server
npm install
npm start
```

**Client (Flutter):**
```bash
cd dev_watch
flutter pub get
flutter run
```

## Features

### Authentication
- GitHub OAuth flow via system browser (FlutterWebAuth2)
- Session tokens (JWT, 30-day expiry) stored in FlutterSecureStorage
- User profile persisted across app restarts via GET /me endpoint
- Disconnect clears session and redirects to welcome screen

### Repository Watching
- **Auto-watched**: Top 3 most recently active repos are watched automatically
- **Manual watchlist**: Add up to 4 additional repos
- Watch/unwatch toggles sync with the backend
- Repos synced from GitHub on app open and pull-to-refresh

### AI Scanning
- Triggered manually per repo from the detail screen
- Pipeline: GitHub fetch -> NVIDIA (security + code quality) -> Groq (docs + tests)
- Results shown as radial gauges and rating badges
- Scan log streams in real-time via Server-Sent Events

### Activity Feed
- Chronological log of scan completions
- Pull-to-refresh support
- Empty states guide the user when no activity exists

### Notifications
- Firebase Cloud Messaging integration
- Configurable alert preferences (new issues, score drops)
- Score drop threshold picker (10/20/30 pts)

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/github/oauth/exchange` | No | Exchange GitHub OAuth code for session token |
| GET | `/me` | Yes | Get current authenticated user profile |
| POST | `/github/sync-repos` | Yes | Sync repositories from GitHub |
| GET | `/repos` | Yes | List user's repositories with watch status |
| POST | `/repos/:id/watch` | Yes | Add repo to manual watchlist |
| POST | `/repos/:id/unwatch` | Yes | Remove repo from manual watchlist |
| GET | `/repos/:id/scans` | Yes | Get scan history for a repo |
| GET | `/repos/:id/alerts` | Yes | Get alerts for a repo |
| POST | `/scan/:repoId` | Yes | Trigger a manual scan (SSE stream) |
| GET | `/feed` | Yes | Get activity feed |
| POST | `/notifications/register-device` | Yes | Register FCM device token |
| GET | `/health` | No | Health check |
| POST | `/internal/cron/scan-all` | No | Cron-triggered scan of all watched repos |
| POST | `/webhooks/github` | No | GitHub webhook receiver |

## Database Schema

The schema is defined in `server/schema.sql`. Key tables:
- `users` - GitHub-authenticated users with encrypted access tokens
- `repos` - Repositories with auto/manual watch flags
- `scan_results` - Scan outputs with scores and findings
- `alerts` - Scan-generated alerts per repo
- `feed_items` - Activity feed entries
- `device_tokens` - FCM push notification tokens

## Security

- **GitHub access tokens are never stored in plain text** — encrypted with AES-256-GCM
- **The raw GitHub token never reaches the client** — all API calls go through our backend
- **Session tokens are JWT-based** with 30-day expiry, stored in platform secure storage
- **Rate limiting** (express-rate-limit): 100 req/15min general, 10 req/15min auth, 20 req/hr scan
- **CORS and input validation** should be added in production

## Rate Limiting

Introduced in `server/middleware/rateLimiter.js`:

| Limiter | Window | Max Requests |
|---------|--------|--------------|
| General | 15 minutes | 100 |
| Auth | 15 minutes | 10 |
| Scan | 1 hour | 20 |

These are applied in `server/index.js` and can be tuned per environment.

## Known Issues

1. **Auth persistence**: The GET /me endpoint was added to restore the user profile on app restart. If the token has expired, the user is silently signed out and redirected to the welcome screen.
2. **Disconnect flow**: Disconnecting navigates back to the welcome screen via the auth listener in `HomeScreen`. Ensure the listener is active before triggering disconnect.
3. **Scan errors**: Errors during scanning show a user-friendly message ("Scan failed. Please try again.") with a dismiss button in the repo detail screen.
4. **Watchlist limits**: Auto-watched (3) + manual (4) = 7 total max. Both client and server enforce this.
5. **Settings persistence**: Notification preferences are currently in-memory only. A backend settings endpoint is needed for cross-session persistence.

## Future Improvements

- Settings backend endpoint for persistent preferences across sessions
- GitHub webhook integration for real-time feed updates (commits, PRs, issues)
- Push notification delivery via the cron scanner
- Multi-language support
- Dark/light theme persistence already implemented