# MyAnimeList - Project Overview

**Last Updated:** 2025-10-28  
**Created by:** AI Assistant

## Project Purpose

MyAnimeList is a native iOS/macOS anime library management application that allows users to track and organize their anime viewing. The app integrates with The Movie Database (TMDb) API to fetch detailed information about anime titles including movies, TV series, and individual seasons.

## Tech Stack

### Platforms & Languages
- **Swift 6.1+** - Primary programming language
- **iOS 18+** - Minimum iOS version
- **macOS 15+** - Minimum macOS version
- **Xcode** - Development environment

### Frameworks & Libraries
- **SwiftUI** - UI framework for building views
- **SwiftData** - Apple's modern data persistence framework (replacing Core Data)
- **Combine** - Reactive programming for handling async events
- **Kingfisher** - Image downloading and caching
- **TMDb SDK** - The Movie Database API client integration

### Build Tools
- **Xcode Build System** - Primary build system
- **Swift Package Manager (SPM)** - Dependency management
- **xcode-build-server** - BSP (Build Server Protocol) support for editor integration
- **swift-format** - Code formatting and linting

## Project Structure

```
MyAnimeList/
├── MyAnimeList/                    # Main iOS/macOS app
│   ├── Sources/
│   │   ├── App/                    # App entry point
│   │   │   └── MyAnimeListApp.swift
│   │   ├── Models/                 # Data models
│   │   │   └── BasicInfo.swift     # Anime basic info structure
│   │   ├── ViewModels/             # Business logic layer
│   │   │   ├── LibraryStore.swift  # Main library state management
│   │   │   ├── ToastCenter.swift   # Toast notification system
│   │   │   ├── ScrollState.swift   # Scroll state management
│   │   │   └── Search/             # Search-related view models
│   │   ├── Views/                  # SwiftUI views
│   │   │   ├── Library/            # Library viewing UI (grid, list, gallery)
│   │   │   ├── SearchPage/         # Search interface
│   │   │   └── Gadgets/            # Reusable UI components
│   │   ├── Network/                # Networking layer
│   │   │   ├── InfoFetcher.swift   # TMDb API wrapper
│   │   │   └── RedirectingHTTPClient.swift
│   │   ├── Utils/                  # Utility classes
│   │   │   ├── BackupManager.swift # Data backup/restore
│   │   │   └── TMDbAPIKeyStorage.swift
│   │   └── Extensions/             # Swift extensions
│   ├── Resources/                  # Assets and resources
│   └── Tests/                      # Unit tests
│
├── DataProvider/                   # SwiftData persistence layer (SPM package)
│   ├── Package.swift
│   └── Sources/
│       └── DataProvider/
│           ├── DataProvider.swift  # Main data provider class
│           ├── Models/             # SwiftData models with versioning
│           │   ├── V1/             # Schema version 1
│           │   ├── V2/             # Schema version 2 (current)
│           │   └── Other/          # Shared types (AnimeType, etc.)
│           └── Tests/
│
├── MyAnimeList.xcodeproj/          # Xcode project configuration
├── Makefile                        # Build automation commands
├── buildServer.json                # Build server configuration
├── .swift-format                   # Swift format configuration
└── LICENSE                         # Apache 2.0 License
```

## Key Architecture Components

### Data Layer
- **DataProvider** (SPM package): Encapsulates SwiftData model container and data operations
- **Schema Versioning**: Uses versioned schemas (V1, V2) for data migration support
- **AnimeEntry**: The core SwiftData model representing an anime entry in the library
- **AnimeType**: Enum distinguishing between movies, series, and individual seasons

### Business Logic Layer
- **LibraryStore**: Observable class managing library state, filtering, and sorting
- **InfoFetcher**: Handles fetching anime metadata from TMDb API
- **BackupManager**: Manages export/import of library data

### Presentation Layer
- **SwiftUI Views**: Declarative UI with support for grid, list, and gallery viewing modes
- **Search**: Dual search functionality (local library + TMDb online search)
- **Toast System**: Global toast notifications for user feedback

### Network Layer
- **TMDb Integration**: Uses TMDb API for fetching anime details, posters, backdrops
- **RedirectingHTTPClient**: Custom HTTP client for API relay
- **Language Support**: Multi-language support for anime titles and descriptions

## Key Features

1. **Anime Library Management**
   - Add/edit/remove anime entries
   - Track viewing status and progress
   - Multiple view modes (grid, list, gallery)
   - Filtering and sorting capabilities

2. **TMDb Integration**
   - Search TMDb database for anime
   - Fetch detailed information (posters, backdrops, logos, overviews)
   - Multi-language support
   - Support for movies, TV series, and individual seasons

3. **Data Persistence**
   - SwiftData-based storage with schema migration
   - Backup and restore functionality
   - iCloud sync capability (via SwiftData)

4. **UI/UX**
   - Native iOS/macOS experience with SwiftUI
   - Responsive design with adaptive layouts
   - Image caching with Kingfisher
   - Toast notifications for user feedback

## Development Workflow

### Build Commands (via Makefile)
- `make clean` - Clean build artifacts
- `make refresh-packages` - Resolve Swift package dependencies
- `make format` - Format code with swift-format
- `make lint` - Lint code with swift-format

### Code Style
- Uses `swift-format` for consistent code formatting
- Configuration in `.swift-format` file

### Testing
- Unit tests located in `MyAnimeList/Tests/` and `DataProvider/Tests/`

## Data Flow

1. **App Launch**: 
   - Initialize DataProvider with SwiftData container
   - Check for TMDb API key, show configurator if needed
   - Load library from persistent storage

2. **Library Display**:
   - LibraryStore fetches entries from DataProvider
   - Applies filters and sorting
   - Views observe LibraryStore and update reactively

3. **Adding Anime**:
   - User searches TMDb via SearchPage
   - Selects anime from results
   - InfoFetcher retrieves full details
   - Creates AnimeEntry and saves to SwiftData
   - LibraryStore automatically refreshes via ModelContext notifications

4. **Data Persistence**:
   - SwiftData handles automatic persistence
   - ModelContext.didSave notifications trigger UI updates
   - BackupManager can export/import for manual backups

## Configuration

- **TMDb API Key**: Stored in UserDefaults via TMDbAPIKeyStorage
- **Language Preference**: Stored in AppStorage
- **Sort Strategy**: Persisted in UserDefaults

## Commit Message Style

This project follows the conventional commit message format recommended by Git:

### Format
```
<type>: <subject line (50 chars max)>

<body (optional, 72 chars per line)>
```

### Guidelines
- **Subject line**: Imperative mood, capitalized, no period at end
  - ✅ "Add Library search functionality to SearchPage"
  - ✅ "Fix bug in backup & restore function"
  - ✅ "Improve UI for consistency"
  - ❌ "Added search feature" (past tense)
  - ❌ "fixes bug" (not capitalized)

- **Body**: Optional, used to explain *what* and *why* vs. *how*
  - Separate from subject with blank line
  - Wrap at 72 characters
  - Examples from commit history:
    ```
    Fix bug in backup & restore function

    Use Schema(versionedSchema: VersionSchema) to ensure version
    correctness; Fix bug in BackupManager schema version checking
    ```

- **Common types observed in this project**:
  - Add, Fix, Remove, Refactor, Improve, Enhance, Bump, Use

### Examples from Project History
```
Add favorited toast for favorite toggle

Trigger a toast to be displayed when using the context menu in
LibraryListView or LibraryGridView
```

```
Refactor Library views to reduce duplicate code
```

```
Enhance season fetching in SeriesResultItem
```

## License

Apache License 2.0

---

*This overview was generated by analyzing the project structure and codebase (~2,252 lines of Swift code across the main app and DataProvider package).*
