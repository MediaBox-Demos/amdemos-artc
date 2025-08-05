[English](README_English.md)

# ARTC SDK API Example Android (Java)
阿里云 · ARTC SDK Demo

## 介绍
ARTC SDK Android平台(Java语言)的API示例Demo，展示ARTC SDK 的API调用示例，核心场景的接口调用参考

## 源码说明

### 源码下载
下载地址[请参见](https://github.com/MediaBox-Demos/amdemos-artc/tree/main/Android)

### 源码结构
```
├── Android       		       //Android平台工程结构跟目录
│   ├── ARTCExample            //API Example工程目录
│       ├── app                //Demo入口
│       ├── KeyCenter          //AppId/AppKey等信息
│           ├── keycenter      //设置AppId/AppKey等信息
│       ├── quickstart         //快速开发模块
│           ├── TokenGenerate  //Token生成及入会
│           ├── VideoCall      //快速实现音视频通话
│           ├── VoiceChat      //快速实现语聊房
│       ├── BasicUsage          //基础功能模块
│           ├── AudioBasicUsage  //常用音频操作和配置
│           ├── VideoBasicUsage // 常用视频操作和配置
│           |—— CameraCommonControl //摄像头常规配置
│           |—— SEIUsage         //SEI消息发送和接收
│           |—— ScreenShareUsage  //屏幕共享
│           |—— StreamMonitoring //通话中推拉流质量监测  
        |—— AdvancedUsage //进阶功能模块
            |—— ExternalAudio //外部音频采集和外部音频渲染
            |—— ProcessAudioRawData //原始音频数据
            |—— ProcessVideoRawData //原始视频数据
│       ├── build.gradle  
│       └── settings.gradle

```

### 环境要求
- Android Studio 插件版本4.1.3
- Gradle 8.7
- Android Studio自带 jdk17

### 前提条件
到阿里云视频直播控制台左侧导航栏，选择直播+ > 实时音视频 > 应用管理，在应用管理页面，单击创建应用，申请AppID，AppKey等信息，并配置到工程中。


## 跑通ARTC API Example源码
- 源码下载后，使用Android Studio打开Android/ARTCExample/目录

- 配置实时音视频AppID和AppKey,进入`Android/ARTCExample/KeyCenter/src/main/java/com/aliyun/artc/api/keycenter/ARTCTokenHelper.java`将控制台申请的AppID和AppKey填入
```java
// ARTCTokenHelper.java
// 实时音视频AppID
private static String AppId = "<实时音视频AppID>";
// 实时音视频AppKey
private static String AppKey = "<实时音视频AppKey>";
```
- 运行App，即可体验API Example

