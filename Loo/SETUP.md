# Loo App Setup Guide

## Quick Start

Since Xcode project files (`.xcodeproj`) are binary and complex, here's how to set up the Loo app:

### Option 1: Create New Xcode Project (Recommended)

1. **Open Xcode** (version 14.0 or later)

2. **Create New Project**:
   - File → New → Project
   - Select "iOS" → "App"
   - Click "Next"

3. **Configure Project**:
   - **Product Name**: `Loo`
   - **Team**: Select your development team
   - **Organization Identifier**: `com.yourname` (or your preferred identifier)
   - **Bundle Identifier**: Will be auto-generated as `com.yourname.Loo`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: None (we're not using Core Data)
   - Click "Next"

4. **Choose Location**:
   - Navigate to this repository folder
   - **IMPORTANT**: Uncheck "Create Git repository" (we already have one)
   - Click "Create"

5. **Replace Files**:
   - Delete the auto-generated `ContentView.swift` and `LooApp.swift`
   - Drag all files from the `Loo/Loo/` folder in this repo into your Xcode project
   - Make sure to check "Copy items if needed"
   - Ensure "Loo" target is selected

6. **Add Info.plist entries**:
   - The `Info.plist` is already provided
   - Or manually add in Xcode:
     - Select your project in navigator
     - Select "Loo" target → "Info" tab
     - Add the location usage descriptions (already in provided Info.plist)

7. **Build and Run**:
   - Select a simulator or physical device
   - Press Cmd+R or click the Play button
   - App should build and run!

### Option 2: Manual File Integration

If you already have an Xcode project:

1. Copy all `.swift` files into your project
2. Update `Info.plist` with location permissions
3. Ensure minimum iOS deployment target is 15.0+
4. Build and run

## File Structure in Xcode

Your Xcode project navigator should look like this:

```
Loo
├── Loo (Group)
│   ├── LooApp.swift
│   ├── ContentView.swift
│   ├── Models
│   │   └── Bathroom.swift
│   ├── Services
│   │   ├── LocationManager.swift
│   │   └── BathroomService.swift
│   └── Assets.xcassets
├── Info.plist
└── Preview Content (Group)
    └── Preview Assets.xcassets
```

## Configuration Requirements

### Minimum Deployment Target
- iOS 15.0 or later

### Capabilities Required
- Location Services (automatically included)

### Privacy Permissions
Already configured in `Info.plist`:
- `NSLocationWhenInUseUsageDescription`
- `NSLocationAlwaysAndWhenInUseUsageDescription`

## Testing on Simulator

1. **Grant Location Permission**:
   - When prompted, click "Allow While Using App"
   - Or manually: Features → Location → Custom Location

2. **Set a Test Location**:
   - Features → Location → Apple (Cupertino)
   - Or Features → Location → Custom Location (enter coordinates)

3. **Wait for Data**:
   - App will automatically fetch bathrooms near the location
   - Results appear on map and in list view

## Testing on Physical Device

1. **Developer Account**:
   - Free Apple Developer account is sufficient
   - Sign in via Xcode → Preferences → Accounts

2. **Select Your Team**:
   - Project settings → Signing & Capabilities
   - Select your development team

3. **Connect Device**:
   - Connect iPhone via cable
   - Trust computer if prompted
   - Select device in Xcode
   - Build and run

4. **Location Services**:
   - App will request permission on first launch
   - Grant "While Using App" permission
   - Walk around to test real location updates!

## Troubleshooting

### Build Errors

**"Cannot find type X in scope"**
- Make sure all `.swift` files are added to the Loo target
- Check target membership in File Inspector

**"Info.plist not found"**
- Ensure Info.plist is in the project root
- Check Build Settings → Packaging → Info.plist File path

### Runtime Errors

**No bathrooms appearing**
- Check internet connection (required for OSM API)
- Grant location permissions
- Wait a few seconds for API response
- Check Xcode console for error messages

**Location not updating**
- Grant location permission when prompted
- On simulator: manually set a location
- On device: ensure Location Services are enabled in Settings

### API Issues

**No data from OpenStreetMap**
- OSM Overpass API may be temporarily unavailable
- Check console for error messages
- Try again after a few moments
- Ensure you have an internet connection

## Performance Notes

The app is built for maximum performance:
- Swift compiled code (native speed)
- Async/await for non-blocking operations
- Efficient location updates (50m threshold)
- Lazy loading for list views

You should see instant UI responses and smooth scrolling even with many bathroom results.

## Development Tips

### Customize Search Radius
In `BathroomService.swift`, change:
```swift
private let searchRadiusMeters = 5000 // Change to desired radius
```

### Adjust Location Update Frequency
In `LocationManager.swift`, change:
```swift
locationManager.distanceFilter = 50 // Meters before update
```

### Modify Skeuomorphic Style
All visual styling is in `ContentView.swift`:
- Adjust gradient colors
- Modify shadow parameters
- Change corner radii
- Tweak button sizes

## Next Steps

Once the app is running:
1. Test map view and list view toggle
2. Try dark mode switch
3. Tap refresh to update bathroom locations
4. Check distance calculations
5. Verify business hours display (if available in OSM data)

Enjoy finding bathrooms with Loo!
