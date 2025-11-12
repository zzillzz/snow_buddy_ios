# Snow Buddy - iOS Snowboarding & Skiing Tracker

## Project Overview

Snow Buddy is an iOS application built with SwiftUI that helps snowboarders and skiers track their runs on the mountain. The app provides automatic run detection, detailed performance analytics, and comprehensive run history management.

## Platform & Technology

- **Platform**: iOS
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Backend**: Supabase
- **Location Services**: CoreLocation
- **Language**: Swift

## Core Features

### Current Features
1. **Automatic Run Detection**: Automatically detects when a run starts and stops using location and motion data
2. **Run Tracking**: Tracks comprehensive run metrics including:
   - Speed (top speed, average speed)
   - Distance traveled
   - Elevation changes (vertical descent, slope)
   - Route path with GPS coordinates
   - Duration and timestamps
3. **Run History**: View all past runs organized by day with detailed statistics
4. **Run Details**: Detailed view for each run showing:
   - Speed charts and elevation charts
   - Route visualization on map
   - Performance metrics
   - Shareable run cards
5. **Dashboard**: Overview of current session with aggregated stats
6. **User Authentication**: Login and profile management

### Planned Features
- Friend system: Add and track friends on the mountain
- Friend groups: Create and manage groups of friends
- Social features: See friends' runs and locations

## Project Structure

```
snow-buddy/
├── Features/                    # Feature modules (MVVM pattern)
│   ├── Home/                   # Home screen
│   │   ├── View/
│   │   └── ViewModel/
│   ├── RunList/                # List of all runs
│   │   ├── View/
│   │   │   ├── RunListView.swift
│   │   │   ├── RunDayCard.swift
│   │   │   └── RunCardView.swift
│   │   └── ViewModel/
│   ├── RunDetails/             # Individual run details
│   │   ├── View/
│   │   │   ├── RunsDetailsSheet.swift
│   │   │   ├── RunDetailsSheetInfoView.swift
│   │   │   └── ShareableRunView.swift
│   │   └── ViewModel/
│   ├── Dashboard/              # Session dashboard
│   │   └── Views/
│   ├── Map/                    # Map visualization
│   │   └── View/
│   │       ├── MapView.swift
│   │       └── RunDetailsMapView.swift
│   ├── Charts/                 # Data visualization
│   │   └── Views/
│   │       ├── RunElevationChart.swift
│   │       └── RunsSpeedChart.swift
│   ├── SpeedTracker/           # Real-time speed tracking
│   │   └── Views/
│   ├── Login/                  # Authentication
│   │   ├── View/
│   │   │   ├── LoginScreen.swift
│   │   │   └── CompleteProfileView.swift
│   │   └── ViewModel/
│   └── Setting/                # App settings
│       └── Views/
├── Services/                    # Business logic & managers
│   ├── RunManager.swift        # Run tracking and management
│   ├── TrackingManager.swift   # Location and motion tracking
│   ├── Supabase.swift          # Backend integration
│   └── Protocol/
│       └── LocationManagerProtocol.swift
├── Model/                       # Data models
│   ├── RunModel.swift          # Core run data model with SwiftData
│   ├── RoutePoint.swift        # GPS coordinate points
│   └── UserModel.swift         # User profile data
├── Shared/                      # Shared components
│   └── Components/
│       ├── CustomBackground.swift
│       ├── ScreenTransitions.swift
│       ├── ShakeEffect.swift
│       ├── StatCard.swift
│       ├── CustomButton.swift
│       └── RunCard.swift
├── Views/                       # Root views
│   └── ContentView.swift
├── Config/                      # Configuration files
│   ├── SupabaseConfig.swift
│   ├── Development.xcconfig
│   ├── Local.xcconfig
│   └── Production.xcconfig
└── snow_buddyApp.swift         # App entry point
```

## Key Data Models

### Run Model
The `Run` model (SwiftData) tracks all run information:
- Unique identifier (UUID)
- Time data: start time, end time, duration
- Speed metrics: top speed, average speed (stored in m/s, convertible to km/h)
- Elevation data: start elevation, end elevation, vertical descent, average slope
- Distance: run distance in meters (convertible to km)
- Route data: array of `RoutePoint` objects with GPS coordinates and timestamps
- Top speed location point

### RoutePoint Model
Stores individual GPS points along the run route with latitude, longitude, altitude, and timestamp.

### UserModel
Manages user profile and authentication data.

## Architecture Pattern

The app follows the **MVVM (Model-View-ViewModel)** architecture:
- **Views**: SwiftUI views for UI presentation
- **ViewModels**: Handle business logic, data transformation, and state management
- **Models**: Data structures using SwiftData for persistence
- **Services**: Managers for location tracking, run detection, and backend communication

## Services & Managers

### TrackingManager
Handles real-time location tracking and motion detection for automatic run start/stop detection.

### RunManager
Manages run data lifecycle including creating, updating, and querying runs from the local database.

### Supabase Service
Handles backend communication for user authentication and data synchronization.

## Development Notes

### Configuration
- The app uses `.xcconfig` files for environment-specific configuration
- Configuration files are gitignored (Development, Local, Production)
- Supabase configuration is stored in `Config/SupabaseConfig.swift`

### Current Git Status
- Working on feature branch: `feature/authentication`
- Recent changes involve run tracking improvements and UI updates to RunDayCard and RunCard components

### Dependencies
- Uses Swift Package Manager for dependency management
- Key dependencies likely include Supabase Swift client and charting libraries

## Common Development Tasks

### Working with Runs
- Run data is persisted locally using SwiftData
- Access run data through `RunManager` service
- Run calculations (speed, distance, slope) are computed properties on the `Run` model

### Location Tracking
- Location services are abstracted through `LocationManagerProtocol`
- `TrackingManager` coordinates location updates and run detection logic
- Ensure proper location permissions are requested

### UI Components
- Reusable components are in `Shared/Components/`
- Custom styling includes background gradients, transitions, and animations
- Charts are built using native Swift Charts framework

### Authentication Flow
- Login handled through Supabase authentication
- Profile completion flow for new users
- User session management integrated with app lifecycle

## Testing
- Unit tests: `snow-buddyTests/`
- UI tests: `snow-buddyUITests/`

## Future Considerations

When implementing social features (friends, groups):
- Consider real-time location sharing privacy and permissions
- Design friend invitation and acceptance flow
- Plan group management and visibility settings
- Think about notification system for friend activities
- Consider offline functionality and data sync strategies
