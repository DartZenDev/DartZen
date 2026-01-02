# Zen Demo

**A living demonstration of the DartZen architecture.**

Zen Demo is not a showcase. It is not a prototype. It is the **breathing minimum** of DartZen—a real end-to-end system proving the architecture works.

## What Zen Demo Demonstrates

- ✅ **Real Firebase Authentication** via emulator
- ✅ **Real Firestore** database via emulator
- ✅ **Real file-based storage** (filesystem adapter)
- ✅ **Real localization** shared between client and server
- ✅ **Real identity management** with DartZen patterns
- ✅ **Real WebSocket communication** with echo service
- ✅ **Single command** start/stop workflow

**No mocks. No stubs. No TODOs. No commented-out functionality.**

---

## Quick Start

### Prerequisites

- Dart SDK 3.6.0+
- Flutter SDK
- Docker & Docker Compose

### Run Everything

```bash
cd apps/ZenDemo
./run.sh
```

That's it. One command starts:
1. Firebase emulators (Auth, Firestore, Storage)
2. Dart server
3. Flutter client (opens in browser)

### Stop Everything

```
Ctrl+C
```

One signal stops everything cleanly. No orphan processes. No manual cleanup.

---

## Definition of "Works"

Zen Demo works **only if**, after running `./run.sh`:

| Feature | Expected Behavior |
|---------|------------------|
| **Login** | Create account or sign in via Firebase Auth Emulator |
| **Profile** | Load user identity from Firestore Emulator |
| **Ping** | Server responds with translated message |
| **WebSocket** | Echo messages back and forth |
| **Terms** | Load Markdown content from storage with language support |
| **Language** | Switch between English/Polish affects UI, API messages, and Terms content |

If any of these fail, Zen Demo is broken.

---

## Architecture

```
apps/ZenDemo/
├── client/          # Flutter web app
├── server/          # Dart Shelf server
├── contracts/       # Shared data contracts
├── docker-compose.yml   # Firebase emulators
├── run.sh          # Single-command launcher
└── README.md       # This file
```

### Server Architecture

- **No fallback to production**: Server fails immediately if emulator environment variables are missing
- **Real storage**: Terms loaded from GCS emulator using language-specific files (`legal/terms.{lang}.md`)
- **Real identity**: Uses `FirestoreIdentityRepository` with emulated Firestore
- **Real localization**: Both client and server use `ZenLocalizationService`
- **Seed data**: Pre-configured test users and storage are populated automatically on emulator start

### Client Architecture

- **Real authentication**: Firebase Auth with email/password
- **Real API calls**: HTTP and WebSocket connections to server
- **Real state management**: Listenable app state with Firebase auth integration
- **Markdown rendering**: Terms are rendered using `flutter_markdown` package

### Localization

Zen Demo supports **English** and **Polish** languages across:

1. **UI Messages**: Client-side translations for buttons, labels, and error messages
2. **API Messages**: Server-side translations for API responses (ping, error codes)
3. **Terms Content**: Language-specific Markdown files stored in Firebase Storage
   - English: `legal/terms.en.md`
   - Polish: `legal/terms.pl.md`

**File Naming Convention**: All localized content uses the format `{basename}.{lang}.{ext}`

Language selection is managed via `AppState` and automatically propagates to:
- Client UI rendering
- HTTP requests via `Accept-Language` header
- Terms content retrieval
- Error message translation

---

## Environment Variables

The server requires these environment variables (set automatically by `run.sh`):

| Variable | Example | Purpose |
|----------|---------|---------|
| `FIRESTORE_EMULATOR_HOST` | `localhost:9088` | Firestore emulator connection |
| `FIREBASE_AUTH_EMULATOR_HOST` | `localhost:9099` | Auth emulator connection |
| `FIREBASE_STORAGE_EMULATOR_HOST` | `localhost:9199` | Storage emulator connection |
| `PORT` | `8888` | Server port |
| `STORAGE_BUCKET` | `demo-bucket` | GCS emulator bucket name |

**The server will refuse to start without valid emulator configuration.**

---

## Firebase Emulator UI

While Zen Demo is running, access the Firebase Emulator UI at:

**http://localhost:4000**

Here you can:
- View authentication users
- Inspect Firestore collections
- Monitor storage files
- See real-time logs

---

## Test Credentials

The Firebase Auth emulator is pre-seeded with test accounts:

### Demo User
- **Email**: `demo@example.com`
- **Password**: `password123`

### Admin User
- **Email**: `admin@example.com`
- **Password**: `password123`

These accounts are automatically available when the emulators start.

---

## Development

### Project Structure

```
apps/ZenDemo/
├── client/
│   ├── lib/
│   │   ├── main.dart
│   │   └── src/
│   │       ├── screens/          # UI screens
│   │       ├── l10n/              # Localization
│   │       ├── api_client.dart   # HTTP client
│   │       ├── websocket_client.dart
│   │       └── app_state.dart    # State management
│   └── pubspec.yaml
├── server/
│   ├── bin/
│   │   └── server.dart           # Entry point
│   ├── lib/
│   │   └── src/
│   └── pubspec.yaml
└── contracts/
    ├── lib/
    │   └── src/                  # Shared DTOs
    └── pubspec.yaml
```

### Running Tests

```bash
# All packages
cd ../..
melos run test

# Specific package
cd contracts
dart test

cd ../server
dart test

cd ../client
flutter test
```

### Linting

```bash
cd ../..
melos run analyze
```

All three Zen Demo packages must pass analysis with zero issues.

---

## Philosophy

Zen Demo embodies the DartZen principles:

1. **Explicit over implicit** - All configuration is visible
2. **No hidden state** - Everything flows through explicit parameters
3. **Fail fast in dev** - Server refuses to start without emulators
4. **Safe UX in production** - Clear error messages, no silent failures
5. **GCP-native** - Uses Firebase/Firestore as first-class services
6. **One breath** - Single command to start, single signal to stop

---

## Troubleshooting

### Server won't start

**Error**: `FIRESTORE_EMULATOR_HOST is required`

**Solution**: Don't run the server directly. Always use `./run.sh` which sets up emulators first.

### Port already in use

**Error**: `Address already in use`

**Solution**: Another process is using the ports. Find and stop it:

```bash
lsof -i :8888  # Server port
lsof -i :9088  # Firestore emulator
lsof -i :9099  # Auth emulator
kill -9 <PID>
```

### Emulators won't start

**Error**: Docker connection refused

**Solution**: Ensure Docker Desktop is running:

```bash
docker ps  # Should list containers
docker compoObject not found in GCS` or `404`

**Solution**: Ensure seed data exists:

```bash
open http://localhost:4000/storage/demo-bucket/legal
# Should exist files: terms.en.md, terms.pl.md
```

If missing, the file should be recreated automatically on next emulator start.**Solution**: Ensure you're running from the correct directory:

```bash
cd apps/ZenDemo
./run.sh  # Not from server/ subdirectory
```

---

## What Zen Demo Is NOT

- ❌ Not a production application
- ❌ Not a complete feature showcase
- ❌ Not optimized for scale
- ❌ Not a UI/UX reference

Zen Demo exists to prove one thing: **The DartZen architecture works end-to-end.**

---

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

**Remember**: If something cannot be made real, it must not exist.

Zen Demo represents the breathing minimum. Anything less violates the philosophy.
