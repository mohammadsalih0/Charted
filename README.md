# Charted

Charted is a local-first document scanner for Android and Linux.

It lets you:

- Capture a document with your camera
- Import a document image from your device
- Extract text locally using OCR
- Export the result as a searchable PDF directly to `Downloads/Charted/`
- Preview, share, or delete recent scans instantly
- Benefit from automatic high refresh rate adaptation for buttery-smooth performance on Android
- Use light or dark mode
- Use the Linux graphical interface or command-line interface

No document images or OCR data are uploaded to a remote service.

Repository: <https://github.com/mohammadsalih0/charted>

## Current release

Version: **1.1.0**

Available artifacts:

- Android APK: `build/app/outputs/flutter-apk/Charted-1.1.0.apk`
- Linux AppImage: `dist/Charted-1.1.0.AppImage`

## Supported platforms

- Android
- Linux x86_64

## Key Android Features

- **Local OCR**: Powered by Google ML Kit Text Recognition running entirely on-device.
- **High Refresh Rate Adaptation**: Automatically detects display modes and configures window attributes to run at the highest possible screen refresh rate for fluid scrolling and animations.
- **Public Downloads Integration**: Automatically saves generated PDFs to the public `Downloads/Charted/` directory (`/storage/emulated/0/Download/Charted/`).
- **Recent Scans Management**: Keep track of recent exports with built-in actions to **Preview**, **Share**, or **Delete** (with automatic disk cleanup) scans directly from the app interface.

## OCR

### Android

Android uses Google ML Kit Text Recognition. Recognition runs locally on the device.

### Linux

Linux uses the locally installed Tesseract OCR executable.

Install Tesseract and the English language model on Debian-based systems:

```sh
sudo apt install tesseract-ocr tesseract-ocr-eng
```

## Running from source

Install Flutter, then run:

```sh
flutter pub get
flutter run -d linux
```

To run on an Android device:

```sh
flutter run -d <android-device>
```

Android camera access must be allowed when requested by the operating system.

## Using the Android APK

Install the release APK on an Android device:

```sh
adb install build/app/outputs/flutter-apk/Charted-1.0.0.apk
```

Scanned PDFs are automatically saved to `Downloads/Charted/` on your device.

## Linux graphical application

Build the Linux release:

```sh
flutter build linux --release
```

The graphical executable is generated at:

```text
build/linux/x64/release/bundle/charted-gui
```

The bundled dispatcher can be run without arguments to open the graphical application:

```sh
./build/linux/x64/release/bundle/charted
```

## Linux AppImage

Make the AppImage executable:

```sh
chmod +x dist/Charted-1.0.0.AppImage
```

Launch the graphical application:

```sh
./dist/Charted-1.0.0.AppImage
```

The AppImage includes both the graphical application and the CLI.

## Linux command-line interface

The CLI performs local OCR on an image and creates a searchable PDF.

Using the Linux bundle:

```sh
./build/linux/x64/release/bundle/charted \
  --input /path/to/document.png \
  --output /path/to/document.pdf
```

Using the AppImage:

```sh
./dist/Charted-1.0.0.AppImage \
  --input /path/to/document.png \
  --output /path/to/document.pdf
```

The output path is optional. If omitted, the PDF is written beside the input image.

### CLI options

```text
-i, --input FILE       Image to recognize (required)
-o, --output FILE      PDF destination
-l, --language LANG    Tesseract language(s), default: eng
-h, --help             Show this help
```

Display the CLI help:

```sh
./dist/Charted-1.0.0.AppImage --help
```

The default OCR language is English (`eng`). Other installed Tesseract language models may be selected explicitly with `--language`.

## Building the Android release

```sh
flutter build apk --release
```

The generated APK is located under:

```text
build/app/outputs/flutter-apk/
```

## Building the Linux release

```sh
flutter build linux --release
```

The generated Linux bundle is located under:

```text
build/linux/x64/release/bundle/
```

## Development checks

Run static analysis:

```sh
flutter analyze
```

Run tests:

```sh
flutter test
```

Check Dart formatting:

```sh
dart format --output=none --set-exit-if-changed lib bin test
```

## Privacy

Charted is designed for local processing. The application does not intentionally upload document images or OCR results.

Users should still review any files they choose to distribute, including:

- APK files
- AppImages
- Screenshots
- Exported PDFs
- Logs and crash reports

Do not include private documents, credentials, API keys, signing keys, or personal build artifacts in public releases.

## License

Charted is licensed under the Apache License, Version 2.0. See
[LICENSE](LICENSE) for the full license text.
