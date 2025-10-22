# Loo - Bathroom Finder iOS App

A beautiful, skeuomorphic iOS application for finding nearby bathrooms, inspired by classic Jony Ive Apple design.

## Features

- **Skeuomorphic Design**: Classic iOS 6-era design with realistic textures, gradients, and shadows
- **Dark Mode Support**: Full dark mode with toggle switch
- **OpenStreetMap Integration**: Free, open-source bathroom location data via Overpass API
- **Comprehensive Information**:
  - Bathroom locations as amenities
  - Business type and name
  - Opening hours
  - Parking difficulty assessment
  - Distance from current location
- **High Performance**: Built entirely in Swift for blazing-fast native performance
- **Map & List Views**: Toggle between map markers and detailed list view
- **Real-time Location**: Automatic location updates and bathroom search

## Technical Stack

- **Language**: Swift (compiled, high-performance)
- **Framework**: SwiftUI for declarative UI
- **Location Services**: CoreLocation
- **Mapping**: MapKit
- **API**: OpenStreetMap Overpass API (completely free)

## Project Structure

```
Loo/
├── Loo/
│   ├── LooApp.swift                 # Main app entry point
│   ├── ContentView.swift            # Main UI with skeuomorphic design
│   ├── Models/
│   │   └── Bathroom.swift           # Data models
│   ├── Services/
│   │   ├── LocationManager.swift    # Location services
│   │   └── BathroomService.swift    # OSM API integration
│   └── Info.plist                   # App configuration
└── README.md
```

## API Details

### OpenStreetMap Overpass API

The app uses the free Overpass API to query OpenStreetMap data:

**Endpoint**: `https://overpass-api.de/api/interpreter`

**Query Logic**:
- Searches for nodes and ways tagged with `amenity=toilets`
- Searches for facilities with `toilets=yes`
- 5km radius from user location
- Returns location, tags, and metadata

**Data Extracted**:
- Coordinates (latitude/longitude)
- Business name (from `name`, `operator`, or `brand` tags)
- Business type (from `amenity`, `shop`, `tourism`, or `leisure` tags)
- Opening hours (from `opening_hours` tag)
- Parking information (from `parking` related tags)

## Design Philosophy

### Skeuomorphism

The app embraces skeuomorphic design principles:
- **Realistic Materials**: Gradients simulate depth and lighting
- **Shadows & Highlights**: Multi-layer shadows create 3D effect
- **Embossed Text**: Subtle shadows give text depth
- **Physical Buttons**: Buttons that look pressable with tactile feedback
- **Rich Textures**: Layered gradients simulate real materials

### Dark Mode

Dark mode maintains the skeuomorphic aesthetic:
- Darker gradients with similar depth perception
- Adjusted shadow intensities
- Maintained material realism
- Smooth transitions

## How to Build

1. Open Xcode (version 14.0 or later)
2. Create a new iOS App project named "Loo"
3. Replace the generated files with the files from this repository
4. Set the bundle identifier to your preferred identifier
5. Build and run on simulator or device

**Requirements**:
- iOS 15.0+
- Xcode 14.0+
- Swift 5.7+

## Permissions

The app requires location permissions to function:
- **When In Use**: Required for finding nearby bathrooms
- The app will request permission on first launch

## Performance

Built entirely in Swift with native iOS frameworks for maximum performance:
- **Instant UI**: SwiftUI's compiled nature ensures smooth 60fps
- **Efficient API**: Async/await for non-blocking network requests
- **Smart Caching**: Location updates throttled to 50m intervals
- **Optimized Rendering**: Lazy loading for list views

## Future Enhancements

Potential improvements:
- User reviews and ratings
- Accessibility information
- Offline mode with cached data
- Navigation integration
- Custom bathroom additions
- Filtering options (public vs. private, accessibility features)

## License

This project is open source and available for modification and distribution.

## Credits

- Design inspired by Jony Ive's iOS 6 era skeuomorphic design language
- Location data from OpenStreetMap contributors
- Built with Swift and SwiftUI
