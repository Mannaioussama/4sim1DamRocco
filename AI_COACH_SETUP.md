# AI Coach Setup Guide

## Overview

The AI Coach feature integrates HealthKit data with Google's Gemini AI to provide personalized fitness recommendations, activity suggestions, and health tips based on your actual health metrics and workout history.

## Features

✅ **HealthKit Integration**
- Steps, calories, heart rate, sleep data
- Workout sessions and duration tracking
- Weekly trends analysis
- VO2 Max and resting heart rate

✅ **Gemini AI Analysis**
- Personalized activity suggestions
- Smart fitness tips based on your data
- Motivational messages
- Recovery recommendations

✅ **Session Tracking**
- Track social workout sessions
- Record cycling, running, basketball with friends
- AI considers recent social activities

## Setup Instructions

### 1. Get Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy your API key

### 2. Configure API Key

**Option A: Environment Variable (Recommended)**
```bash
export GEMINI_API_KEY="your_api_key_here"
```

**Option B: Direct Configuration**
1. Open `NEXO/Services/APIConfiguration.swift`
2. Replace `"YOUR_GEMINI_API_KEY_HERE"` with your actual API key:
```swift
return "your_actual_api_key_here"
```

**Option C: Secure Plist File**
1. Create `APIKeys.plist` in your project (add to .gitignore)
2. Add your key:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GeminiAPIKey</key>
    <string>your_api_key_here</string>
</dict>
</plist>
```

### 3. HealthKit Permissions

The app will automatically request HealthKit permissions when you first use the AI Coach. Grant access to:

- ✅ Steps
- ✅ Active Energy
- ✅ Heart Rate
- ✅ Workouts
- ✅ Sleep Analysis
- ✅ Body Mass
- ✅ VO2 Max

### 4. Test the Integration

1. Build and run the app
2. Navigate to AI Coach
3. The app will:
   - Request HealthKit permissions
   - Load your health data
   - Send data to Gemini AI for analysis
   - Display personalized recommendations

## How It Works

### Data Flow
```
HealthKit Data → AI Coach Service → Gemini AI → Personalized Recommendations
```

### AI Analysis Process
1. **Data Collection**: Gathers your recent health metrics, workouts, and trends
2. **Context Building**: Creates a comprehensive health profile
3. **AI Analysis**: Sends structured prompt to Gemini AI
4. **Response Parsing**: Converts AI response to actionable suggestions
5. **UI Update**: Displays personalized recommendations in the app

### Session Tracking
Record your social workout sessions:
```swift
// Example: Record a cycling session with friends
viewModel.recordUserSession(
    activityType: "Cycling",
    duration: 45,
    participants: 3,
    location: "Central Park"
)
```

## Customization

### User Preferences
Add your fitness preferences to get better recommendations:
```swift
viewModel.addUserPreference("Outdoor Activities")
viewModel.addUserPreference("Group Sports")
viewModel.addUserPreference("Morning Workouts")
```

### AI Prompt Customization
Modify the AI analysis prompt in `GeminiAIService.swift` to:
- Focus on specific fitness goals
- Add sport-specific recommendations
- Include injury prevention tips
- Customize for different fitness levels

## Privacy & Security

- ✅ Health data stays on device until analysis
- ✅ Only aggregated metrics sent to AI (no personal identifiers)
- ✅ API key stored securely
- ✅ User controls all data sharing

## Troubleshooting

### "Missing API Key" Error
- Check that your API key is properly configured
- Verify the key is valid and active
- Ensure no extra spaces or characters

### "No Health Data" Error
- Grant HealthKit permissions in Settings > Privacy & Security > Health
- Add some health data or workouts to your Health app
- Try refreshing the AI Coach page

### AI Analysis Not Working
- Check your internet connection
- Verify API key is valid
- Check Gemini API quotas and limits

## Development Notes

### Mock Data
For development without real health data:
```swift
let mockService = AICoachService.createMockService()
```

### Testing
- Use iOS Simulator's Health app to add test data
- Test with different workout types and frequencies
- Verify AI responses are parsed correctly

## API Costs

Gemini AI has generous free tiers:
- 15 requests per minute
- 1 million tokens per day
- Perfect for personal fitness apps

Monitor usage at [Google AI Studio](https://makersuite.google.com/)

## Next Steps

1. **Enhanced Prompts**: Customize AI prompts for your specific fitness goals
2. **More Data Sources**: Add nutrition, stress, or other health metrics
3. **Social Features**: Share AI recommendations with workout partners
4. **Offline Mode**: Cache recommendations for offline use

---

**Need Help?** Check the code comments in:
- `HealthKitManager.swift` - Health data integration
- `GeminiAIService.swift` - AI analysis logic  
- `AICoachService.swift` - Main coordination service
- `AICoachViewModel.swift` - UI integration
