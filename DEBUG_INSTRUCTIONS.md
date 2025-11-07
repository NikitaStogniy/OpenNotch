# Notch App - Debugging Instructions

## Quick Start

1. **Build and Run from Xcode**
   - Open `Notch.xcodeproj` in Xcode
   - Press `⌘R` to build and run
   - Check Xcode console for debug logs

2. **What to Look For**

   ### In Xcode Console:
   ```
   🚀 App launched!
   ✅ Creating floating panel...
   📦 Creating floating panel...
   🎨 Configuring panel appearance...
   🎭 Creating NotchView...
   📍 Positioning at notch...
   📐 Screen frame: ...
   📐 Window frame: ...
   📐 Safe area insets: ...
   ✅ Notch detected! Height: ...
   📍 Final position: ...
   ✅ Window positioned!
   ✅ Panel created and shown!
   👁️ Showing panel...
   ✅ Panel should be visible now at: ...
   ```

   ### In Your Mac:
   - **MenuBar**: Look for a music note icon (♪) in your menubar (top right)
   - **Floating Notch**: Look at the top center of your screen for a small dark rounded rectangle
   - **On Hover**: When you move your mouse to the top center, the notch should expand

## Testing Features

### 1. MenuBar Menu
- Click the music note icon in menubar
- You should see:
  - Show/Hide Notch toggle
  - Recent Files (if any)
  - Settings button
  - About button
  - Quit button

### 2. Floating Notch
- **Collapsed State**: Small 200x40 rounded rectangle at top center
- **Hover**: Move mouse to top center → notch expands to show content
- **Expanded State**: Shows music controls and file storage
- **Settings**: Click gear icon → opens settings panel

### 3. File Management
- **Drag & Drop**: Drag files onto the expanded notch
- **File Icons**: Should show appropriate icons for file types
- **Delete**: Click X button on files to remove them

## Troubleshooting

### Problem: No notch visible at top of screen

**Check:**
1. Look for logs in Xcode console
2. Is the panel being created? Look for "📦 Creating floating panel..."
3. Is the panel being shown? Look for "👁️ Showing panel..."
4. What's the final position? Look for "📍 Final position: ..."

**Possible Issues:**
- Window might be positioned off-screen
- Window level might be wrong (should be `.floating`)
- Window might be hidden behind other windows

**Quick Fix:**
```swift
// In FloatingWindowManager.swift, temporarily change:
panel.level = .floating  // Try .screenSaver or .popUpMenu
panel.backgroundColor = .red  // Make it red to see if it's there
panel.alphaValue = 0.8  // Make it slightly opaque
```

### Problem: Notch not responding to hover

**Check:**
1. Is `acceptsMouseMovedEvents` set to true?
2. Is `ignoresMouseEvents` set to false?
3. Is the NotchView's `onHover` callback firing?

**Debug:**
Add print statement in NotchView.swift:
```swift
.onHover { hovering in
    print("🖱️ Hover: \(hovering)")
    // ...
}
```

### Problem: MenuBar icon not visible

**Check:**
1. Is `NSApp.setActivationPolicy(.accessory)` being called?
2. Is MenuBarExtra properly configured?
3. Check for "🚀 App launched!" in logs

## Console Monitoring

To see real-time logs while app is running:

```bash
# In Terminal:
log stream --predicate 'process == "Notch"' --style compact

# Then launch the app from Xcode
```

## Clean Build

If things are acting weird:

1. In Xcode: Product → Clean Build Folder (⇧⌘K)
2. Quit the app completely
3. Rebuild and run

## Expected Behavior

When everything works correctly:

1. **Launch**: App starts, no Dock icon, menubar icon appears
2. **Floating Window**: Small notch visible at top center of screen
3. **Hover**: Mouse over notch → expands smoothly with animation
4. **Content**: Shows music player and file storage when expanded
5. **Settings/About**: Clicking these buttons shows alert dialogs
6. **Quit**: App quits cleanly when selecting Quit from menu

## Debug Output Example

```
🚀 App launched!
✅ Creating floating panel...
📦 Creating floating panel...
🎨 Configuring panel appearance...
🎭 Creating NotchView...
📍 Positioning at notch...
📐 Screen frame: (0.0, 0.0, 1728.0, 1117.0)
📐 Window frame: (0.0, 0.0, 200.0, 40.0)
📐 Safe area insets: NSEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
ℹ️ No notch detected, positioning at top
📍 Final position: (764.0, 1067.0)
✅ Window positioned!
✅ Panel frame: (764.0, 1067.0, 200.0, 40.0)
✅ Panel level: 3
✅ Floating panel created and shown!
👁️ Showing panel...
✅ Panel should be visible now at: (764.0, 1067.0, 200.0, 40.0)
```

Note: On MacBooks with physical notch, you should see "✅ Notch detected! Height: 32.0pt" (or similar).

## Getting Help

If you're still having issues:

1. Copy all console output
2. Take a screenshot of your menubar
3. Note your macOS version and Mac model
4. Share in the project issues
