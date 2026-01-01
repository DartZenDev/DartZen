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
| **Terms** | Load HTML content from real filesystem storage |
| **Language** | Switch between English/Polish affects both client and server |

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
- **Real storage**: Terms loaded from `server/storage/legal/terms.html`
- **Real identity**: Uses `FirestoreIdentityRepository` with emulated Firestore
- **Real localization**: Both client and server use `ZenLocalizationService`

### Client Architecture

- **Real authentication**: Firebase Auth with email/password
- **Real API calls**: HTTP and WebSocket connections to server
- **Real state management**: Listenable app state with Firebase auth integration

---

## Environment Variables

The server requires these environment variables (set automatically by `run.sh`):

| Variable | Example | Purpose |
|----------|---------|---------|
| `FIRESTORE_EMULATOR_HOST` | `localhost:8080` | Firestore emulator connection |
| `FIREBASE_AUTH_EMULATOR_HOST` | `localhost:9099` | Auth emulator connection |
| `FIREBASE_STORAGE_EMULATOR_HOST` | `localhost:9199` | Storage emulator connection |
| `PORT` | `8888` | Server port |
| `STORAGE_PATH` | `$(pwd)/storage` | Filesystem storage directory |

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

For quick testing, use these credentials:

- **Email**: `test@example.com`
- **Password**: `password123`

Create this account on first run using the "Create Account" button.

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
│   │       ├── zen_demo_server.dart
│   │       └── l10n/              # Server messages
│   ├── storage/
│   │   └── legal/
│   │       └── terms.html        # Real storage content
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
lsof -i :8080  # Firestore emulator
lsof -i :9099  # Auth emulator
kill -9 <PID>
```

### Emulators won't start

**Error**: Docker connection refused

**Solution**: Ensure Docker Desktop is running:

```bash
docker ps  # Should list containers
docker compose up  # Test emulator startup
```

### Terms won't load

**Error**: `Storage path does not exist`

**Solution**: Ensure you're running from the correct directory:

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

Apache 2.0

---

**Remember**: If something cannot be made real, it must not exist.

Zen Demo represents the breathing minimum. Anything less violates the philosophy.
