[English](README_English.md)

# ARTC SDK API Example Harmony (ArkTS)
ARTC SDK Example Harmony (ArkTS) API 示例 Demo

## 介绍

ARTC SDK API 示例 Demo，用于展示 ARTC SDK 在鸿蒙 ArkTS 平台上的主要 API 调用方式，以及常见业务场景（通话、屏幕共享、录制、画中画、自定义采集 / 渲染等）的接口组合示例。

## 源码说明

### 源码下载

下载地址请参见：  
https://github.com/MediaBox-Demos/amdemos-artc/tree/main

### 源码结构（Harmony 部分）

```text
├── Harmony                           // 鸿蒙平台工程根目录
│   ├── ARTCExample                   // Harmony API Example 工程
│   │   ├── entry                     // Demo 入口工程（ArkTS）
│   │   │   ├── src/main/ets
│   │   │   │   ├── common            // 通用组件 & 工具
│   │   │   │   │   ├── components    // 通用 UI 组件（标题栏等）
│   │   │   │   │   ├── keycenter     // KeyCenter，封装 AppId/AppKey/Token 生成
│   │   │   │   │   │   ├── ARTCTokenHelper.ets    // Token 工具类（配置 AppId/AppKey）
│   │   │   │   │   │   └── GlobalConfig.ets        // 全局配置单例
│   │   │   │   │   ├── utils         // 权限、沙箱文件管理等
│   │   │   │   │   └── ConstantsData.ets / Constants.ets  // 常量定义
│   │   │   │   ├── entryability      // 程序入口 Ability
│   │   │   │   ├── manager           // 页面栈管理、导航管理
│   │   │   │   │   └── PageStackCenter.ets         // 导航栈中心
│   │   │   │   ├── model             // 首页模块配置
│   │   │   │   │   ├── ModuleInfo.ets              // 模块信息数据模型
│   │   │   │   │   ├── ModuleManager.ets           // 模块管理器（单例）
│   │   │   │   │   └── ModuleRegistry.ets          // 模块注册中心（在此控制首页显示哪些功能）
│   │   │   │   └── pages             // 业务页面
│   │   │   │       ├── Index.ets                    // 首页（模块入口聚合）
│   │   │   │       ├── SettingsDialog.ets          // 设置弹窗（配置 AppId/AppKey/UserId）
│   │   │   │       ├── quickstart/                 // 快速开始示例
│   │   │   │       │   ├── TokenGenerate.ets       // Token 生成及入会
│   │   │   │       │   ├── VideoCall.ets           // 视频通话
│   │   │   │       │   └── VoiceChat.ets           // 语聊房
│   │   │   │       ├── basicusage/                 // 基础功能示例
│   │   │   │       │   ├── VideoBasicUsage.ets     // 视频基础用法
│   │   │   │       │   ├── AudioBasicUsage.ets     // 音频基础用法
│   │   │   │       │   ├── CameraPage.ets          // 摄像头控制
│   │   │   │       │   ├── ScreenSharePage.ets     // 屏幕共享
│   │   │   │       │   ├── SEIPage.ets             // SEI 信令
│   │   │   │       │   ├── DataChannelMessagePage.ets  // 数据通道消息
│   │   │   │       │   ├── PlayAudioFilesPage.ets  // 播放音频文件
│   │   │   │       │   ├── StreamMonitoringPage.ets // 远端流监控
│   │   │   │       │   └── VoiceChangePage.ets     // 变声/音效
│   │   │   │       └── advancedusage/              // 进阶功能示例
│   │   │   │           ├── RecordingPage.ets       // 本地录制
│   │   │   │           ├── PictureInPicturePage.ets // 画中画
│   │   │   │           ├── PreJoinChannelTestPage.ets // 入会前测试
│   │   │   │           ├── CustomAudioCapturePage.ets // 自定义音频采集
│   │   │   │           ├── CustomAudioRenderPage.ets  // 自定义音频播放
│   │   │   │           ├── CustomVideoCapturePage.ets // 自定义视频采集
│   │   │   │           ├── CustomVideoRenderPage.ets  // 自定义视频渲染
│   │   │   │           ├── ProcessAudioRawDataPage.ets // 获取原始音频数据
│   │   │   │           ├── ProcessVideoRawDataPage.ets // 获取原始视频数据
│   │   │   │           ├── HEVCPage.ets             // H.265 编解码
│   │   │   │           ├── PublishLiveStreamPage.ets // 推流旁路直播
│   │   │   │           ├── LiveLinkMicPage.ets      // 连麦直播
│   │   │   │           ├── OriginAudioDataWrap.ets  // 原始音频数据 NAPI 示例
│   │   │   │           ├── OriginVideoDataWrap.ets  // 原始视频数据 NAPI 示例
│   │   │   │           └── pipManager/              // 画中画管理器
│   │   │   ├── src/main/cpp          // 原生 C++ 模块（NAPI）
│   │   │   │   ├── CMakeLists.txt                   // NAPI 构建配置
│   │   │   │   ├── napi_init.cpp                    // NAPI 导出入口
│   │   │   │   ├── origin_audio_data.cpp/.h         // 原始音频数据 NAPI 接口实现
│   │   │   │   ├── origin_video_data.cpp/.h         // 原始视频数据 NAPI 接口实现
│   │   │   │   └── types/                           // NAPI 使用的结构体定义
│   │   │   ├── src/main/resources    // 资源文件（图片、字符串等）
│   │   │   └── module.json5          // Entry 模块配置
│   │   ├── key                        // 签名证书
│   │   ├── hvigor/                    // 构建配置
│   │   ├── oh-package.json5           // 工程依赖声明
│   │   └── ...

```


## 环境要求

- DevEco Studio 5.0.3.900 Release 或以上版本
- HarmonyOS NEXT 5.0.0.102（API Version 12）或以上版本，支持音视频的鸿蒙设备，并已开启"允许调试"
- 已注册华为开发者账号并完成实名认证

## 前提条件

1. 登录阿里云视频直播控制台  
   在左侧导航栏选择：**直播+ > 实时音视频 > 应用管理**  
2. 在"应用管理"页面创建应用，获取 **AppID**、**AppKey** 等信息  
3. 将获取到的 AppID/AppKey 配置到当前工程中

## 配置 AppID / AppKey

打开文件：

```text
Harmony/ARTCExample/entry/src/main/ets/common/keycenter/ARTCTokenHelper.ets
```

在该文件中填入控制台申请到的 AppID/AppKey，例如：

```ts
// ARTCTokenHelper.ets
// 实时音视频 AppId
public static AppId: string = "<实时音视频 AppID>";
// 实时音视频 AppKey
public static AppKey: string = "<实时音视频 AppKey>";
```

保存后重新编译运行。

> **提示**：  
> - 工程内所有入会逻辑均统一通过 `ARTCTokenHelper + GlobalConfig` 生成单参或多参 Token。  
> - 未配置 AppId/AppKey 时，首页点击任一功能会提示先前往右上角"设置"填写参数。

## 跑通 ARTC API Example

1. 使用 DevEco Studio 打开工程目录：

   ```text
   Harmony/ARTCExample/
   ```

2. 配置 AppId / AppKey（见上一节）

3. 连接鸿蒙设备（或模拟器），点击运行

4. App 首页主要分为三个模块：

   - **快速开始**：  
     - Token 生成及入会  
     - 实现视频通话  
     - 语聊房功能  
   - **基础功能**：  
     - 音视频基础参数配置、静音、切换摄像头等  
   - **进阶功能**：  
     - 屏幕共享、本地录制、画中画  
     - 自定义音频采集 / 播放  
     - 自定义视频采集 / 渲染  
     - 获取原始音频/视频数据  
     - 入会前测试（网络质量、设备测试）等