[中文](README.md)


ARTC SDK API Example Mac (Objective-C++)
Introduction
This is a demo showcasing API usage examples of Alibaba Cloud's ARTC SDK on the Mac platform (using Object C++ language), demonstrating API calls and providing reference for core scenario interfaces.

Source Code Description
Source Code Download
Download link: See here

Source Code Structure
├── Mac                            // Root directory of Mac platform project structure
│   ├── ARTCExample                // API Example source code directory
│       ├── Common                 // Common modules
│       ├── QuickStart             // Rapid development modules
│           ├── TokenGenerate      // Token generation and meeting join
│           ├── VideoCall          // Quick implementation of audio/video calls
│           ├── VoiceChat          // Quick implementation of voice chat rooms
│       ├── BasicUsage             // Basic functionality modules
│           ├── ScreenShare        // Screen sharing
│       ├── ...                    // Other project files
│   ├── ARTCExample.xcodeproj      // Demo Project

Environment Requirements
Xcode 15 or above, recommend using the latest official version
Prepare a real device with MacOS 14 or above
Prerequisites
Go to the Alibaba Cloud Video Live Console left navigation bar, select Live+ > Real-time Audio/Video > Application Management. On the application management page, click Create Application to apply for AppID, AppKey and other information.

Running the ARTC API Example Source Code
After downloading the source code, open the Mac directory
Open the project file ARTCExample.xcodeproj
Configure the real-time audio/video AppID and AppKey in the Common/AppDefine.h file Navigate to Mac/ARTCExample/Common/AppDefine.h and fill in the AppID and AppKey applied from the console

#define ARTC_APP_ID  "<AppID>"
#define ARTC_APP_KEY "<AppKey>"
Configure project signing information, go to project configuration interface, select Signing & Capabilities, check Automatically manage signing
Run the App to experience the API Example
