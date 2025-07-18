[中文](README.md)

# ARTC SDK API Example Android (Java)
Alibaba Cloud · ARTC SDK Demo

## Introduction
ARTC SDK Android(Java) Demo，, demonstrating ARTC SDK API call examples and core scenario interface references

## Source Code Description

### Source Code Download
Download [address](https://github.com/MediaBox-Demos/amdemos-artc/tree/main/Android)

### Source Code Structure
```
├── Android       		          // Android platform project root directory  
│   ├── ARTCExample             //API Example project directory  
│       ├── app                 //Demo entry point  
│       ├── KeyCenter           //AppId/AppKey configuration directory  
│           ├── keycenter       //AppId/AppKey configuration  
│       ├── QuickStart          //Quick development module  
│           ├── TokenGenerate     //Token generation and joining a session  
│           ├── VideoCall       //Quick implementation of audio/video calls  
│           ├── VoiceChat   //Quick implementation of voice chat rooms 
│       ├── build.gradle  
│       └── settings.gradle

```

### Environment Requirements
- Android Studio plugin version 4.1.3
- Gradle 8.7
- JDK 17 bundled with Android Studio

### Prerequisites
Go to the Alibaba Cloud Live Streaming console left navigation bar, select Live+ > Real-Time Audio and Video > Application Management. On the Application Management page, click Create Application to apply for an AppID, AppKey, and configure them in the project.


## Running the ARTC API Example Source Code
- After downloading the source code, open the Android/ARTCExample/ directory using Android Studio

- Configure the Real-Time Audio and Video AppID and AppKey. Navigate to Android/ARTCExample/KeyCenter/src/main/java/com/aliyun/artc/api/keycenter/ARTCTokenHelper.java and fill in the AppID and AppKey obtained from the console:
```java
// ARTCTokenHelper.java  
// Real-Time Audio and Video AppID  
private static String AppId = "<Real-Time Audio and Video AppID>";  
// Real-Time Audio and Video AppKey  
private static String AppKey = "<Real-Time Audio and Video AppKey>"; 
```
- Run the app to experience the API Example

