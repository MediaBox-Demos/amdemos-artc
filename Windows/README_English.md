[中文](README.md)

# ARTC SDK API Example for Windows
Alibaba Cloud · ARTC SDK Demo

## Introduction
This is an API example demo for the ARTC SDK on the Windows platform, demonstrating API calls and core scenario references for the ARTC SDK.  

## Source Code Description

### Source Code Download
Download [address](https://github.com/MediaBox-Demos/amdemos-artc/tree/main/Windows)

### Source Code Structure
```

├── Windows // Root directory of the Windows project
│   ├── ARTCExample // Directory containing the API example source code
│       ├── ARTCExampleDefine.h // File for setting AppId/AppKey and other information
│       ├── ... // Other files in the project
│   ├── ARTCExample.sln // SLN file for the demo project

```

### Environment Requirements
- Microsoft Visual Studio 2015 or later (Recommended: Microsoft Visual Studio 2015)  
- Windows 10 or later operating system  

### Prerequisites
Go to the Alibaba Cloud Live Streaming console left navigation bar, select Live+ > Real-Time Audio and Video > Application Management. On the Application Management page, click Create Application to apply for an AppID, AppKey, and configure them in the project.


## Running the ARTC API Example Source Code

- **Download the source code** and navigate to the `Windows` directory.  
- [**Download SDK**](https://help.aliyun.com/zh/live/artc-download-the-sdk?spm=a2c4g.11186623.0.0.56ac3f352de4ES#dd9acb7bda986),  and unzip it.
  - Copy the `AliRTCSdk.lib` file to the `lib/x64` directory in the demo.
  - Copy the `alivcffmpeg.dll` and `AliRTCSdk.dll` files from the x64/Release directory to the `x64/Debug` and `x64/Release` directories in the Demo.
- Open the project using **Microsoft Visual Studio** by loading `ARTCExample.sln`.  
- **Configure the AppID and AppKey**:  
  Open `Windows/ARTCExample/ARTCExampleDefine.h` and replace the placeholders with your AppID and AppKey obtained from the console.  
   ```h
   // ARTCExampleDefine.h  

   #define ARTC_APP_ID		"<Real-time Audio & Video AppID>"  
   #define ARTC_APP_KEY	"<Real-time Audio & Video AppKey>"  
- Select x64/x86 and choose Debug/Release mode for development and debugging.