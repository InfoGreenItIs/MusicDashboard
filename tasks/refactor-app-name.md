# Refactor: Change App Name from "M-Dash" to "Music Dashboard"

**Status**: Done  
**Priority**: Low  
**Created**: 2025-12-22  
**Updated**: 2025-12-22  
**Assignee**: Dennis van Maren

## Description

Update the app branding from "M-Dash" to "Music Dashboard" throughout the codebase for consistency. The app title in `main.dart` already says "Music Dashboard" but the sidebar logo shows "M-Dash".

## Acceptance Criteria

- [ ] Update sidebar logo text from "M-Dash" to "Music Dashboard"
- [ ] Verify app title remains "Music Dashboard" in MaterialApp
- [ ] Ensure branding is consistent across all screens

## Implementation Notes

### Files to Change

**`lib/main.dart` (Line 204)**
Current:
```dart
Text(
  'M-Dash',
  style: GoogleFonts.outfit(
    fontWeight: FontWeight.bold,
    fontSize: 20,
    letterSpacing: 1,
  ),
),
```

Change to:
```dart
Text(
  'Music Dashboard',
  style: GoogleFonts.outfit(
    fontWeight: FontWeight.bold,
    fontSize: 20,
    letterSpacing: 1,
  ),
),
```

**Note**: The app title at line 25 already correctly says `title: 'Music Dashboard'`, so no change needed there.

### UI Considerations

- The sidebar is 280px wide when expanded, so "Music Dashboard" should fit fine (longer than "M-Dash" but still should fit)
- May want to adjust font size if it looks too cramped
- Consider using "Music\nDashboard" (two lines) if needed for better visual balance

## Related Files

- `lib/main.dart` - Update sidebar logo text (line 204)

## Notes / Updates

### 2025-12-22
- Found single occurrence of "M-Dash" in sidebar logo
- App title already correctly set to "Music Dashboard"
- Simple one-line change needed
- **✅ Completed**: Updated `lib/main.dart` line 204 to show "Music Dashboard"
