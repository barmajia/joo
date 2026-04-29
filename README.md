# Aurora

A Flutter application featuring theme customization, multi-language support, and location-based services.

## Features

- **Theme Selection**: 10 built-in themes (Modern Light/Dark, Elegant Light/Dark, AMOLED Dark, Cyberpunk, Forest, Ocean, Sunset, Monochrome)
- **Dynamic Colors**: Material You support for personalized color schemes
- **Multi-language**: English and Arabic localization
- **Location Services**: GPS-based features with permission handling
- **Secure Storage**: Encrypted local storage using Vault Storage

## Getting Started

### Prerequisites

- Flutter SDK 3.10+
- Dart 3.10+

### Installation

```bash
flutter pub get
flutter run
```

### Building

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

## Project Structure

```
lib/
├── l10n/           # Localization
├── locale/         # Language provider
├── pages/          # App screens
├── storage/        # Secure storage
├── theme/          # Theme provider & themes
└── main.dart       # App entry point
```

## Dependencies

- `supabase_flutter` - Supabase auth
- `vault_storage` - Secure encrypted storage
- `geolocator` - Location services
- `permission_handler` - Runtime permissions
- `provider` - State management
- `intl` - Internationalization

## License

MIT