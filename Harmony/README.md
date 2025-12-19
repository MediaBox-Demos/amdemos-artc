[English](README_English.md)

# ARTC SDK API Example Harmony (ArkTS)
ARTC SDK Example  Harmony (ArkTS) API 示例Demo

## 介绍
ARTC SDK API 示例Demo，展示ARTC SDK 的API调用示例，核心场景的接口调用参考

## 源码说明

### 源码下载
下载地址[请参见](https://github.com/MediaBox-Demos/amdemos-artc/tree/main/Harmony)

### 源码结构
```
├── Harmony       		                // 鸿蒙平台工程结构跟目录
│   ├── ARTCExample                     // API Example工程目录
│   |   ├── entry                       // Demo入口
│   |   ├── Commmon                     // 实现通用功能
│   |   ├── KeyCenter                   // AppId/AppKey等信息
│   |   |   ├── ARTCTokenHelper.ets     // 设置AppId/AppKey等信息
│   |   ├── QuickStart                  // 快速开始模块
│   |   |   ├── TokenGenerate.ets       // Token生成及入会
│   |   |   ├── VideoCall.ets           // 快速实现音视频通话
│   |   |   ├── VoiceChat.ets           // 快速实现语聊房

```

### 环境要求
- DevEco Studio 5.0.3.900 Release 或以上版本
- 获取配套 API Version 12的 HarmonyOS NEXT 5.0.0.102 操作系统或以上版本，支持音视频的鸿蒙设备，且已开启“允许调试”选项。
- 已注册华为开发者账号并完成实名认证。

### 前提条件
到阿里云视频直播控制台左侧导航栏，选择直播+ > 实时音视频 > 应用管理，在应用管理页面，单击创建应用，申请AppID，AppKey等信息，并配置到工程中。


## 跑通ARTC API Example源码
- 源码下载后，使用DevEco Studio打开Harmony/ARTCExample/目录

- 配置实时音视频AppID和AppKey,进入`Harmony/ARTCExample/entry/src/main/ets/pages/Index.ets`将控制台申请的AppID和AppKey填入
```java
// ARTCTokenHelper.java
// 实时音视频AppID
@Local appKey: string = '<实时音视频AppID>';
// 实时音视频AppKey
@Local appKey: string = "<实时音视频AppKey>";
```
- 运行App，即可体验API Example

