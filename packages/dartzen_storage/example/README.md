# dartzen_storage Example

This example demonstrates how to use `dartzen_storage` to read objects from Google Cloud Storage.

## Running the Example

1. Set up Google Cloud credentials:

```bash
gcloud auth application-default login
```

2. Update the example with your GCS project ID and bucket name.

3. Run the example:

```bash
dart run example/main.dart
```

## What This Example Shows

- Configuring a `GcsStorageReader`
- Reading objects from GCS
- Handling missing objects
- Working with object metadata
