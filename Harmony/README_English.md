[中文](README.md)

# ARTC SDK API Example Harmony (ArkTS)
ARTC SDK Example Harmony (ArkTS) API Demo

## Introduction

ARTC SDK API Example Demo, demonstrating the main API calling methods of ARTC SDK on the HarmonyOS ArkTS platform, as well as interface combination examples for common business scenarios (calls, screen sharing, recording, picture-in-picture, custom capture/rendering, etc.).

## Source Code Description

### Source Code Download

Download address:  
https://github.com/MediaBox-Demos/amdemos-artc/tree/main

### Source Code Structure (Harmony Part)

```text
├── Harmony                           // HarmonyOS platform project root directory
│   ├── ARTCExample                   // Harmony API Example project
│   │   ├── entry                     // Demo entry project (ArkTS)
│   │   │   ├── src/main/ets
│   │   │   │   ├── common            // Common components & utilities
│   │   │   │   │   ├── components    // Common UI components (title bar, etc.)
│   │   │   │   │   ├── keycenter     // KeyCenter, encapsulating AppId/AppKey/Token generation
│   │   │   │   │   │   ├── ARTCTokenHelper.ets    // Token utility class (configure AppId/AppKey)
│   │   │   │   │   │   └── GlobalConfig.ets        // Global configuration singleton
│   │   │   │   │   ├── utils         // Permissions, sandbox file management, etc.
│   │   │   │   │   └── ConstantsData.ets / Constants.ets  // Constants definition
│   │   │   │   ├── entryability      // Application entry Ability
│   │   │   │   ├── manager           // Page stack management, navigation management
│   │   │   │   │   └── PageStackCenter.ets         // Navigation stack center
│   │   │   │   ├── model             // Home page module configuration
│   │   │   │   │   ├── ModuleInfo.ets              // Module information data model
│   │   │   │   │   ├── ModuleManager.ets           // Module manager (singleton)
│   │   │   │   │   └── ModuleRegistry.ets          // Module registration center (control which features are displayed on home page)
│   │   │   │   └── pages             // Business pages
│   │   │   │       ├── Index.ets                    // Home page (module entry aggregation)
│   │   │   │       ├── SettingsDialog.ets          // Settings dialog (configure AppId/AppKey/UserId)
│   │   │   │       ├── quickstart/                 // Quick start examples
│   │   │   │       │   ├── TokenGenerate.ets       // Token generation and joining channel
│   │   │   │       │   ├── VideoCall.ets           // Video call
│   │   │   │       │   └── VoiceChat.ets           // Voice chat room
│   │   │   │       ├── basicusage/                 // Basic feature examples
│   │   │   │       │   ├── VideoBasicUsage.ets     // Video basic usage
│   │   │   │       │   ├── AudioBasicUsage.ets     // Audio basic usage
│   │   │   │       │   ├── CameraPage.ets          // Camera control
│   │   │   │       │   ├── ScreenSharePage.ets     // Screen sharing
│   │   │   │       │   ├── SEIPage.ets             // SEI signaling
│   │   │   │       │   ├── DataChannelMessagePage.ets  // Data channel messaging
│   │   │   │       │   ├── PlayAudioFilesPage.ets  // Play audio files
│   │   │   │       │   ├── StreamMonitoringPage.ets // Remote stream monitoring
│   │   │   │       │   └── VoiceChangePage.ets     // Voice changing/audio effects
│   │   │   │       └── advancedusage/              // Advanced feature examples
│   │   │   │           ├── RecordingPage.ets       // Local recording
│   │   │   │           ├── PictureInPicturePage.ets // Picture-in-picture
│   │   │   │           ├── PreJoinChannelTestPage.ets // Pre-join channel test
│   │   │   │           ├── CustomAudioCapturePage.ets // Custom audio capture
│   │   │   │           ├── CustomAudioRenderPage.ets  // Custom audio playback
│   │   │   │           ├── CustomVideoCapturePage.ets // Custom video capture
│   │   │   │           ├── CustomVideoRenderPage.ets  // Custom video rendering
│   │   │   │           ├── ProcessAudioRawDataPage.ets // Get raw audio data
│   │   │   │           ├── ProcessVideoRawDataPage.ets // Get raw video data
│   │   │   │           ├── HEVCPage.ets             // H.265 codec
│   │   │   │           ├── PublishLiveStreamPage.ets // Push stream to CDN live
│   │   │   │           ├── LiveLinkMicPage.ets      // Live co-hosting
│   │   │   │           ├── OriginAudioDataWrap.ets  // Raw audio data NAPI example
│   │   │   │           ├── OriginVideoDataWrap.ets  // Raw video data NAPI example
│   │   │   │           └── pipManager/              // Picture-in-picture manager
│   │   │   ├── src/main/cpp          // Native C++ module (NAPI)
│   │   │   │   ├── CMakeLists.txt                   // NAPI build configuration
│   │   │   │   ├── napi_init.cpp                    // NAPI export entry
│   │   │   │   ├── origin_audio_data.cpp/.h         // Raw audio data NAPI interface implementation
│   │   │   │   ├── origin_video_data.cpp/.h         // Raw video data NAPI interface implementation
│   │   │   │   └── types/                           // Structure definitions used by NAPI
│   │   │   ├── src/main/resources    // Resource files (images, strings, etc.)
│   │   │   └── module.json5          // Entry module configuration
│   │   ├── key                        // Signing certificate
│   │   ├── hvigor/                    // Build configuration
│   │   ├── oh-package.json5           // Project dependency declaration
│   │   └── ...

```


## Environment Requirements

- DevEco Studio 5.0.3.900 Release or above
- HarmonyOS NEXT 5.0.0.102 (API Version 12) or above, HarmonyOS device supporting audio and video with "Allow Debugging" enabled
- Registered Huawei developer account with completed real-name authentication

## Prerequisites

1. Log in to Alibaba Cloud Video Live Console  
   Select in the left navigation bar: **Live+ > Real-Time Audio and Video > Application Management**  
2. Create an application on the "Application Management" page to obtain **AppID**, **AppKey** and other information  
3. Configure the obtained AppID/AppKey into the current project

## Configure AppID / AppKey

Open the file:

```text
Harmony/ARTCExample/entry/src/main/ets/common/keycenter/ARTCTokenHelper.ets
```

Fill in the AppID/AppKey obtained from the console in this file, for example:

```ts
// ARTCTokenHelper.ets
// Real-time audio and video AppId
public static AppId: string = "<Real-time audio and video AppID>";
// Real-time audio and video AppKey
public static AppKey: string = "<Real-time audio and video AppKey>";
```

Save and recompile to run.

> **Tips**:  
> - All channel joining logic in the project is unified through `ARTCTokenHelper + GlobalConfig` to generate single-parameter or multi-parameter Token.  
> - If AppId/AppKey is not configured, clicking any feature on the home page will prompt you to go to the upper right corner "Settings" to fill in the parameters.

## Run ARTC API Example

1. Open the project directory using DevEco Studio:

   ```text
   Harmony/ARTCExample/
   ```

2. Configure AppId / AppKey (see previous section)

3. Connect HarmonyOS device (or simulator) and click run

4. The app home page is mainly divided into three modules:

   - **Quick Start**:  
     - Token generation and joining channel  
     - Implement video call  
     - Voice chat room function  
   - **Basic Features**:  
     - Audio and video basic parameter configuration, mute, switch camera, etc.  
   - **Advanced Features**:  
     - Screen sharing, local recording, picture-in-picture  
     - Custom audio capture / playback  
     - Custom video capture / rendering  
     - Get raw audio/video data  
     - Pre-join channel test (network quality, device test), etc.
