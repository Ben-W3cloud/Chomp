# Chomp - Application Overview

A mobile-first Flutter application that monitors GitHub repositories using AI-powered analysis, delivering security and code quality insights directly to users' phones.

---

## 📋 Executive Summary

**Chomp** is a **GitHub analytics platform** that watches user repositories and provides **AI-driven health scores** for security, code quality, documentation, and test coverage. The app combines a **Flutter mobile client** with a **Node.js backend** to create a seamless experience where users can monitor their most important repositories without leaving their phone.

---

## 🏗️ Architecture Overview

### Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Mobile Client** | Flutter (Dart) | Cross-platform iOS/Android app |
| **State Management** | Riverpod 2.5 | Reactive state with providers |
| **Backend Server** | Node.js + Express | REST API + SSE endpoints |
| **Database** | PostgreSQL (Neon.tech) | Persistent data storage |
| **Authentication** | GitHub OAuth 2.0 + JWT | Secure user access |
| **AI/ML Services** | NVIDIA API + Groq API | Code analysis & scoring |
| **Push Notifications** | Firebase Cloud Messaging | Real-time alerts |
| **Deployment** | Serverless-ready | Works with cron triggers |

---

## 🗃️ Data Model & Database Schema

The PostgreSQL database uses the following schema (from `server/schema.sql`):

### Core Tables

| Table | Purpose | Key Fields |
|-------|---------|------------|
| **`users`** | User accounts | `id`, `github_id`, `github_username`, `access_token_encrypted` |
| **`repos`** | GitHub repositories | `id`, `user_id`, `github_repo_id`, `name`, `full_name`, `language`, `is_auto_watched`, `is_manually_watched` |
| **`scan_results`** | AI analysis results | `id`, `repo_id`, `security_score`, `code_quality_score`, `docs_rating`, `tests_rating`, `findings` (JSONB) |
| **`alerts`** | Security/quality alerts | `id`, `repo_id`, `scan_result_id`, `message`, `severity`, `resolved` |
| **`feed_items`** | User activity feed | `id`, `user_id`, `repo_id`, `type`, `title`, `github_url` |
| **`device_tokens`** | FCM device tokens | `id`, `user_id`, `fcm_token` |

### Indexes
- `idx_repos_user_id` - Optimizes repo queries by user
- `idx_scan_results_repo_id` - Optimizes scan history queries
- `idx_feed_items_user_id` - Optimizes feed queries

### Security Features
- **Token Encryption**: GitHub access tokens are encrypted using `pgcrypto` before storage
- **JWT Sessions**: 30-day expiring session tokens for authentication
- **No Client-Side Secrets**: Raw GitHub tokens and AI API keys never touch the mobile client

---

## 🔄 Application Flow

### 1. Authentication Flow
```
User → GitHub OAuth → Flutter Web Auth 2 → Backend Token Exchange → JWT Session → Chomp App
```
- User signs in via GitHub OAuth in system browser
- Backend exchanges code for GitHub token, stores encrypted token
- Returns Chomp JWT for subsequent authenticated requests

### 2. Repository Sync Flow
```
App Start → Load Cached Repos → Sync with GitHub → Backend Fetches from GitHub API → Upserts into DB → Returns to Client
```

### 3. AI Scanning Flow
```
Trigger (Manual or Hourly) → Fetch from GitHub → AI Analysis → Store Results → Create Alerts → Push Notifications
```

### 4. Notification Flow
```
Scan Complete → New Findings or Score Drop → Alert Created → FCM Push → User Device
```

---

## 📱 Mobile App Structure

### Directory Structure
```
lib/
├── core/           # Constants, theme, environment
├── models/         # Data models
├── providers/      # Riverpod state management
├── services/       # Business logic & API clients
├── widgets/        # Reusable UI components
└── screens/        # App screens
```

### Screens
- **Splash**: Initial loading
- **Home**: 3-tab layout (Repos, Feed, Profile)
- **Repo Detail**: Detailed view of repo scans and scores
- **Feed**: Activity feed
- **Profile**: User settings
- **Onboarding**: GitHub OAuth flow

### Key Widgets
- `RepoCard`: Repository list item
- `RadialGauge`: Animated score display
- `RatingBadge`: Qualitative ratings
- `HeatmapStrip`: Commit activity
- `AlertTile`: Alert display
- `ScanLogView`: Live scan progress

### Services
- `AuthService`: GitHub OAuth flow
- `GitHubService`: Repository synchronization
- `ApiClient`: HTTP client with session management
- `ChompDataService`: Data access from backend
- `ScanEngine`: Manual scan orchestration via SSE
- `FcmService`: Firebase Cloud Messaging setup

---

## 🖥️ Backend Server Structure

### Directory Structure
```
server/
├── index.js              # Main Express server
├── db.js                 # PostgreSQL connection
├── routes/               # API route handlers
│   ├── auth.js           # GitHub OAuth
│   ├── repos.js          # Repository management
│   ├── scan.js           # Manual scans (SSE)
│   ├── feed.js           # Activity feed
│   └── notifications.js  # Device tokens
├── lib/                  # Shared utilities
│   ├── constants.js      # Configuration
│   ├── crypto.js         # Token encryption
│   ├── githubClient.js   # GitHub API
│   ├── nvidiaClient.js   # NVIDIA AI analysis
│   ├── groqClient.js    # Groq AI analysis
│   ├── scanRepo.js       # Scan orchestration
│   ├── hourlyScan.js     # Batch scanning
│   └── fcm.js            # Push notifications
└── cron/                 # Scheduled jobs
    └── standalone.js     # Cron worker
```

### API Endpoints
- `POST /github/oauth/exchange` - Authenticate with GitHub
- `POST /github/sync-repos` - Sync repositories
- `GET /repos` - List repositories
- `POST /repos/:id/watch` - Add to watchlist
- `POST /repos/:id/unwatch` - Remove from watchlist
- `GET /repos/:id/scans` - Get scan history
- `GET /repos/:id/alerts` - Get alerts
- `POST /scan/:repoId` - Start manual scan (SSE)
- `GET /feed` - Get activity feed
- `POST /notifications/register-device` - Register FCM token
- `POST /internal/hourly-scan` - Trigger hourly scan (cron)
- `GET /health` - Health check

---

## 🤖 AI & Automation

### AI Models
- **NVIDIA API**: Security score (0-100), Code quality score (0-100), Findings
- **Groq API**: Documentation rating, Test coverage rating (qualitative)

### Automated Features
- Hourly scans of all watched repos
- Manual scans with live SSE progress
- Alerts for new findings and score drops
- Push notifications via Firebase

---

## 🎯 Features

### Core Features
✅ GitHub OAuth authentication
✅ Automatic repository synchronization
✅ AI-powered code analysis (NVIDIA)
✅ AI-powered documentation & test evaluation (Groq)
✅ Security and code quality scoring
✅ Manual scan triggers with live progress
✅ Hourly automated scans
✅ Push notifications for alerts
✅ Activity feed for scan history
✅ Watchlist management (auto + manual)
✅ Cross-platform mobile app (iOS/Android)
✅ Dark mode support

### Planned Features
📋 GitHub webhook integration (for real-time commits/PRs/issues)
📋 Enhanced feed with GitHub activity
📋 Additional AI analysis capabilities
