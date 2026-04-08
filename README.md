# IPLocate - IP Location Tracking App

A simple SwiftUI app that allows users to track IP addresses and view their geographical locations with MapKit integration.

## Features

- **IP Input View**: Enter an IP address and get detailed location information
- **Location Detail View**: View location details with an interactive map and save locations
- **User Profile View**: View and manage saved locations
- **Core Data Persistence**: Save favorite locations locally
- **Rate Limiting**: Built-in rate limiting for API calls (3 requests/second)


## Usage

1. **Find Location**: Enter an IP address in the "Locate IP" tab
2. **View Details**: See location information and interactive map
3. **Save Location**: Tap the heart icon to save locations
4. **Manage Saved**: View and delete saved locations in the "Saved" tab

## Testing

The architecture supports easy unit testing:
- ViewModels can be tested with mock services
- Services are protocol-based for easy mocking
- Core Data operations are abstracted for testing

```swift
// Example test setup
let mockService = MockLocationService()
let viewModel = IPInputViewModel(locationService: mockService)
```

## Future Enhancements

- Unit tests using Swift Testing framework
- Widget support for quick IP lookups
- Share functionality for locations
- Bulk IP import/export
- Location history tracking
- Dark mode optimizations
