# Speed Spike Fix - Summary

## Problem
The app was recording unrealistic speeds (211 km/h) due to GPS errors and position jumps.

## Root Causes Identified

### 1. **Speed Calculated Before Distance Validation** ❌
- Speed was calculated from GPS position changes even when distance was unrealistic
- Distance validation only prevented saving to run, but `currentSpeed` and `topSpeed` were already updated
- Location: `TrackingManager.swift:200` (speed calc) vs `TrackingManager.swift:233` (distance check)

### 2. **GPS Position Jumps**
Found in route data:
- 159-meter jump in 5 seconds = 114 km/h
- 477-meter jump in 63 seconds (chairlift/signal loss)
- 656-meter jump in 73 seconds (chairlift/signal loss)
- Multiple points with identical timestamps but different positions

### 3. **No Maximum Speed Limit**
- No sanity check for realistic skiing/snowboarding speeds
- Professional skiers max at ~130 km/h, world record ~250 km/h
- GPS errors could produce any speed value

### 4. **Duplicate Timestamps**
- GPS points with same timestamp but different positions
- Example: 22:17:15 has two points ~18 meters apart
- When time delta = 0, speed calculation = division by zero or infinity

## Fixes Applied

### ✅ Fix 1: Distance Validation BEFORE Speed Calculation
**File:** `LocationProcessor.swift:227-238`

```swift
// Calculate distance first to validate before speed calculation
let distance = distance3D(from: from.clLocation, to: to.clLocation)

// Validate distance is realistic BEFORE calculating speed
guard isDistanceRealistic(distance) else {
    logger?.warning("GPS jump detected - distance unrealistic")
    return speedHistory.last ?? 0.0
}
```

**Impact:** Prevents unrealistic speeds from GPS jumps

### ✅ Fix 2: Maximum Realistic Speed Check
**File:** `LocationProcessor.swift:256-273`

```swift
// Maximum realistic skiing/snowboarding speed: 150 km/h (41.7 m/s)
let maxRealisticSpeed: Double = speedConfig.maxRealisticSpeed ?? 41.7

guard instantSpeed <= maxRealisticSpeed else {
    logger?.warning("Unrealistic speed detected - exceeds max threshold")
    return speedHistory.last ?? 0.0
}
```

**Impact:** Hard cap on speed prevents any value over 150 km/h

### ✅ Fix 3: Duplicate Timestamp Filtering
**File:** `LocationProcessor.swift:214-227`

```swift
// Filter out duplicate or near-duplicate timestamps
guard dt > 0 else {
    logger?.warning("Duplicate or invalid timestamp detected")
    return speedHistory.last ?? 0.0
}
```

**Impact:** Prevents division by zero and unrealistic speed spikes

### ✅ Fix 4: Prevent Duplicate Route Points
**File:** `RunSessionManager.swift:42-47`

```swift
// Prevent duplicate timestamps - check if last point has same timestamp
if let lastPoint = routePoints.last,
   lastPoint.timestamp == location.timestamp {
    return  // Skip this point
}
```

**Impact:** Ensures clean route data without duplicate timestamps

### ✅ Fix 5: Added Speed Config Parameter
**File:** `TrackingConfiguration.swift:235-240`

```swift
var maxRealisticSpeed: Double?  // m/s - filters GPS errors

static let `default` = SpeedSmoothingConfig(
    windowSize: 5,
    minTimeDelta: 0.1,
    maxRealisticSpeed: 41.7  // 150 km/h
)
```

**Impact:** Configurable maximum speed threshold

## Testing Recommendations

1. **Test with mock GPS data** containing position jumps
2. **Monitor logs** for warnings about filtered speeds:
   - "GPS jump detected - distance unrealistic"
   - "Unrealistic speed detected - exceeds max threshold"
   - "Duplicate or invalid timestamp detected"

3. **Verify maximum speeds** never exceed 150 km/h (41.7 m/s)

4. **Check route points** have unique timestamps in saved runs

5. **Test chairlift scenarios** with long GPS gaps

## Configuration Values

### Default Config (Active)
- `maxDistanceJump: 50.0 meters` - Catches GPS jumps in 1-second intervals
- `maxRealisticSpeed: 41.7 m/s` (150 km/h) - Hard speed limit
- `minTimeDelta: 0.1 seconds` - Minimum time between speed calculations
- `minDistanceChange: 0.5 meters` - Filters GPS noise

### For Stricter Filtering
Use `TrackingConfiguration.highAccuracy`:
- `maxDistanceJump: 30.0 meters`
- `maxHorizontalAccuracy: 20.0 meters`
- `minTimeDelta: 0.05 seconds`

## Expected Behavior Now

✅ GPS jumps → Speed returns last known speed (no spike)
✅ Speeds > 150 km/h → Filtered, returns last known speed
✅ Duplicate timestamps → Point skipped entirely
✅ Unrealistic distances → Not used for speed calculation
✅ Detailed logging → Shows exactly what was filtered and why

## Files Modified

1. `LocationProcessor.swift` - Speed calculation with validation
2. `TrackingConfiguration.swift` - Added maxRealisticSpeed config
3. `RunSessionManager.swift` - Duplicate timestamp filtering

## Date
2025-11-15
