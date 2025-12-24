# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2025-12-22

### Added
- Initial release
- `FirestoreIdentityRepository` implementing `IdentityProvider` port
- Firestore document mapping for Identity aggregates
- `FirestoreIdentityCleanup` for explicit cleanup operations
- Comprehensive unit tests with `fake_cloud_firestore`
- Example usage documentation

### Changed
- Claims normalization to prevent Firestore SDK types from leaking to domain
- Stable lifecycle state tokens instead of enum.name for storage resilience
- Consistent use of `FirestoreMessages` for all error messages
- Simplified `resolveId` to synchronous Future return
