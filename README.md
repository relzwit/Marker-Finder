# Marker Finder

A Flutter application for discovering and exploring historical markers on a map.

## Overview

Marker Finder helps users discover historical markers around them or in specific locations. The app displays markers on a map, allows users to explore marker details, and provides tools to search for markers in different regions.

## Features

- **Interactive Map**: View historical markers on an interactive map
- **Location-Based Search**: Find markers near your current location
- **Adjustable Search Radius**: Control how far to search for markers
- **Marker Clustering**: Efficiently display large numbers of markers
- **City Explorer**: Drag and drop to explore markers in specific cities
- **Marker Details**: View detailed information about each marker
- **Multiple Regions**: Switch between different geographical regions

## Getting Started

To run the app:

1. Ensure Flutter is properly installed
2. Clone the repository
3. Navigate to the project root
4. Run `flutter pub get` to install dependencies
5. Run `flutter run` to launch the app

## Project Structure

```
marker_finder/
├── assets/
│   └── CSVs/           # CSV files containing marker data for different regions
├── lib/
│   ├── models/         # Data models
│   ├── pages/          # App screens
│   ├── services/       # Backend services
│   ├── widgets/        # Reusable UI components
│   └── main.dart       # App entry point
```

## Key Components

### Pages

- **MapPage**: Main screen with the interactive map and markers
- **ProfilePage**: User settings and preferences

### Services

- **HMDBScraper**: Fetches marker details from the Historical Marker Database
- **SettingsService**: Manages user preferences like search radius

### Widgets

- **CustomLocationLayer**: Shows the user's location with a radius circle
- **DraggableExplorer**: UI element for exploring markers in specific cities
- **MonumentMarker**: Custom marker for historical monuments

## How It Works

1. **Data Loading**: The app loads marker data from CSV files stored in the assets folder
2. **Location Detection**: Gets the user's current location (or uses a default)
3. **Marker Filtering**: Filters markers based on the search radius from settings
4. **Map Display**: Shows filtered markers on the map with clustering for performance
5. **Marker Interaction**: Allows users to tap markers to see details
6. **City Exploration**: Users can drag the city explorer to any location to see markers there

## Implementation Details

### Map Implementation

The map is implemented using `flutter_map` with multiple layers:
- Base tile layer from OpenStreetMap
- Custom location layer showing user position and search radius
- Marker cluster layer for efficient marker display
- Popup layer for marker information

### Marker Loading

Markers are loaded from CSV files and filtered based on:
- Distance from the current location
- Current search radius setting
- Maximum number of markers for performance

### Performance Optimizations

- Marker clustering to handle large numbers of markers
- Limiting the maximum number of displayed markers
- Loading markers only when explicitly requested (not on every map movement)
- Debouncing map interactions to prevent excessive updates

## Adding New Regions

To add a new region:
1. Add a CSV file to `assets/CSVs/` with the marker data
2. Update the dropdown menu in `map_page.dart` to include the new region

## Future Enhancements

The following features are planned for future development:

- **Rich Media Content**: Displays images scraped from HMDB link in marker popups
- **Gamification**: Implement a points system for visited markers and user levels



## ToDo List

- Supplement CSV files with 2 sentence AI inscription summaries
    - Use the AI summary in the text area on the popups
- Popup picture scraped from the hmdb link
- Gamification in the form of points for each marker adding to a user level
- Add remaining CSVs
- ✅ Marker clustering for improved performance
