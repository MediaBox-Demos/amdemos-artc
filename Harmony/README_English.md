[中文](README.md)

# ARTC SDK API Example Harmony (ArkTS)
Alibaba Cloud · ARTC SDK Demo

## Introduction
ARTC SDK Harmony (ArkTS) Demo，, demonstrating ARTC SDK API call examples and core scenario interface references

## Source Code Description

### Source Code Download
Download [address](https://github.com/MediaBox-Demos/amdemos-artc/tree/main/Harmony)

### Source Code Structure
```
├── Harmony       		                // Harmony platform project root directory  
│   ├── ARTCExample                     // API Example project directory  
│       ├── entry                       // Demo entry point  
│       ├── Common                      // Common implementation  
│       ├── KeyCenter                   // AppId/AppKey configuration directory  
│           ├── ARTCTokenHelper.ets     // AppId/AppKey configuration  
│       ├── QuickStart                  // Quick development module  
│           ├── TokenGenerate.ets       // Token generation and joining a session  
│           ├── VideoCall.ets           // Quick implementation of audio/video calls  
│           ├── VoiceChat.ets           // Quick implementation of voice chat rooms 

```

### Environment Requirements
- DevEco Studio 5.0.3.900 Release
- Obtain the HarmonyOS NEXT 5.0.0.102 operating system or above with API Version 12, supported audio and video Harmony devices, and have enabled the "Allow Debugging" option.
- Registered Huawei developer account and completed real-name authentication.

### Prerequisites
Go to the Alibaba Cloud Live Streaming console left navigation bar, select Live+ > Real-Time Audio and Video > Application Management. On the Application Management page, click Create Application to apply for an AppID, AppKey, and configure them in the project.


## Running the ARTC API Example Source Code
- After downloading the source code, open the Harmony/ARTCExample/ directory using DevEco Studio

- Configure the Real-Time Audio and Video AppID and AppKey. Navigate to `Harmony/ARTCExample/entry/src/main/ets/pages/Index.ets` and fill in the AppID and AppKey obtained from the console:
```
// ARTCTokenHelper.ets 
// Real-Time Audio and Video AppID  
@Local appId: string = ''; 
// Real-Time Audio and Video AppKey  
@Local appKey: string = '';
```
- Run the app to experience the API Example

