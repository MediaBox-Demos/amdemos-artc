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
- Choose the "ARTCExample" target, connect your iOS device, and build the project.
- Run the application to explore and test the API Example.