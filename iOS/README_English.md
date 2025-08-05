[中文](README.md)

# ARTC SDK API Example iOS (Swift)
Alibaba Cloud · ARTC SDK Demo

## Introduction
ARTC SDK iOS(Swift) Demo，demonstrating ARTC SDK API call examples and core scenario interface references.

## Source Code Description

### Source Code Download
Download [address](https://github.com/MediaBox-Demos/amdemos-artc/tree/main/iOS)

### Source Code Structure
```
├── iOS                                // iOS platform project root directory
│   ├── ARTCExample                    // Source code directory
│       ├── Common                     // Common module
│           ├── ARTCTokenHelper.swift      // AppId/AppKey configuration file
│           ├── ...                        // Ohter files
│       ├── QuickStart                 // Quick start module
│           ├── TokenGenerate              // Token generation and joining a session  
│           ├── VideoCall                  // Quick implementation of audio/video calls  
│           ├── VoiceChat                  // Quick implementation of voice chat rooms 
│       ├── BasicUsage                  // Basic function module
│           ├── AudioBasicUsage            // Common audio operations and configurations
│           ├── VideoBasicUsage            // Common video operations and configurations
│           |—— CameraCommonControl            // Camera common configuration
│           |—— SEIUsage                      // SEI message sending and receiving
            ├── CameraCommonSetting        // Camera common configuration
│           ├── DataChannelMessage         // User-defined message sending and receiving
│           ├── ScreenShare                 // Screen sharing
│       ├── AdvancedUsage                  // Advanced function module
│           ├── ProcessAudioRawData        // Raw audio data
│           ├── ProcessVideoRawData        // Raw video data
│       ├── Setting                    // Setting module
│       ├── ...                        // Other files for the project
│   ├── ARTCExample.xcodeproj          // Demo's project
│   ├── ARTCExample.xcworkspace        // Demo's workspace
│   ├── Podfile                        // Demo's podfile

```

### Environment Requirements
- Xcode 16 or above, the latest official version is recommended
- CocoaPods 1.9.3 or above
- Prepare a real device with iOS 10.0 or above
    - Note: To use the screen sharing feature, please connect a real device running iOS 12.0 or above.

### Prerequisites
Go to the Alibaba Cloud Live Streaming console left navigation bar, select Live+ > Real-Time Audio and Video > Application Management. On the Application Management page, click Create Application to apply for an AppID, AppKey, and configure them in the project.


## Running the ARTC API Example Source Code

- After downloading the source code, navigate to the iOS directory.
- Execute the command "pod install --repo-update" in the Example directory to automatically install the dependent SDKs.
- Open the project file "ARTCExample.xcworkspace".

- Configure the Real-Time Audio and Video AppID and AppKey.
Navigate to`iOS/ARTCExample/Common/ARTCTokenHelper.swift` and fill in the AppID and AppKey obtained from the console
```swift
// ARTCTokenHelper.swift

class ARTCTokenHelper: NSObject {
    
    /**
     * RTC AppId
     */
    public static let AppId = "<RTC AppId>"
    
    /**
     * RTC AppKey
     */
    public static let AppKey = "<RTC AppKey>"
    
    ...
}
```
- Configure the project signing information by navigating to the project settings, selecting "Signing & Capabilities," and enabling "Automatically manage signing."
    - If you do not need to run the screen sharing feature:

        - Remove the App Group.
        - Modify the Bundle IDs of both ARTCExample and ScreenShareExtension.
    - If you need to run the screen sharing feature:

        - In the project settings, update the App Group ID for both the ARTCExample and ScreenShareExtension targets to the one you have registered. If you haven't registered one, create a random identifier for testing (e.g., "group.com.aliyun.artc.example"). Ensure both targets use the same App Group.
        - In the code, update the value of the kAppGroup variable to match the App Group used above. This change applies to the following two files:
            - ARTCExample/BasicUsage/ScreenShare/ScreenShareVC.swift
            - ScreenShareExtension/SampleHandler.swift
- Choose the "ARTCExample" target, connect your iOS device, and build the project.
- Run the application to explore and test the API Example.
