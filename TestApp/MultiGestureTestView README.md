# MultiGestureHandler Test Setup

This test setup provides a comprehensive way to test the `MultiGestureHandler` with a zoomable canvas and interactive elements.

## Files

- **MultiGestureHandler.swift** - The main gesture handling system
- **MultiGestureTestView.swift** - Test view with canvas and interactive elements
- **TestApp.swift** - Simple app to run the test

## Features

### Test Canvas
- **Grid background** for visual reference
- **Zoomable and pannable** canvas
- **Four colored test items** that can be selected and moved
- **Real-time display** of zoom scale and pan offset

### Gesture Testing
The test view supports all gesture types:

1. **Tap** - Select items or clear selection on background
2. **Double Tap** - Logged for individual items
3. **Drag** - Move selected items around the canvas
4. **Right Click/Long Press** - Context actions (logged)
5. **Pinch** - Zoom in and out (0.1x to 5x range)
6. **Two-finger Pan/Scroll** - Pan the canvas view

### Interactive Elements
- **Test Items**: Four colored rectangles you can interact with
- **Selection System**: Visual feedback for selected items
- **Coordinate Spaces**: Proper world-to-screen coordinate conversion
- **Real-time Logging**: View all gesture events in a dedicated log

## Usage

1. **Run the TestApp** - Launch the app to see the test view
2. **Interact with Items** - Tap to select, drag to move
3. **Test Canvas Gestures** - Pinch to zoom, two-finger pan to move the view
4. **View Logs** - Tap the "Log" button to see all gesture events
5. **Reset View** - Use "Reset View" button to return to default zoom/pan

## Controls

- **Tap on item**: Select the item
- **Tap on background**: Clear selection
- **Drag item**: Move it around (only works on selected items)
- **Pinch**: Zoom in/out on the canvas
- **Two-finger scroll/pan**: Move the canvas view
- **Right-click/Long press**: Log context action

## Architecture Tested

This test validates:
- ✅ **Hit Testing** - Proper target selection based on world coordinates
- ✅ **Coordinate Transformation** - Screen-to-world and world-to-screen conversion
- ✅ **Gesture Routing** - Different targets handle different gesture types
- ✅ **State Management** - Proper tracking of drag, pinch, and pan states
- ✅ **Multi-platform Support** - Works on both iOS and macOS
- ✅ **Background Gestures** - Canvas-level zoom and pan
- ✅ **Item Gestures** - Individual item selection and movement

## Customization

You can easily:
- Add more test items by modifying `createTestItems()`
- Change gesture behavior in the target implementations
- Add new gesture types or handling logic
- Modify the visual feedback and styling