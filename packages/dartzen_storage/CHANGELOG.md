# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **BREAKING**: `GcsStorageReader.read()` now only returns `null` for 404 Not Found errors
- All other errors (403 Permission Denied, 500 Server Errors, network failures, etc.) now throw exceptions
- This enforces the Fail Fast principle: configuration errors surface immediately rather than being silently converted to null

### Added
- Documentation of in-memory buffering limitation in README
- Enhanced error handling documentation with examples
- Test coverage for different HTTP error codes (403, 404, 500)
- **Warning** in `StorageObject.asString()` documentation that it throws on binary data (not just malformed UTF-8)
- Clarification that in-memory buffering happens per-object, with guidance on object size limits

## [0.0.1] - 2025-12-29

### Added

- `ZenStorageReader` interface for reading objects from storage
- `GcsStorageReader` implementation for Google Cloud Storage
- `StorageObject` data class for storage object metadata
- Complete dartdoc for all public APIs
- Example application demonstrating usage
- Unit tests for core functionality
