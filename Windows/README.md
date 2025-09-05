[English](README_English.md)

# ARTC SDK API Example for Windows
阿里云 · ARTC SDK Demo

## 介绍
ARTC SDK Window平台的API示例Demo，展示ARTC SDK 的API调用示例，核心场景的接口调用参考

## 源码说明

### 源码下载
下载地址[请参见](https://github.com/MediaBox-Demos/amdemos-artc/tree/main/Windows)

### 源码结构
```
├── Windows                                // Windoes平台工程结构根目录
│   ├── ARTCExample                    // API Example源码目录
│       ├── ARTCExampleDefine.h        // 设置AppId/AppKey等信息
│       ├── ...                        // 工程其他文件
│   ├── ARTCExample.sln                // Demo的sln文件

```

### 环境要求
- Microsoft Visual Studio 2015 及以上版本，推荐使用Microsoft Visual Studio 2015
- 准备 Widows 10 及以上版本的Windows电脑

### 前提条件
到阿里云视频直播控制台左侧导航栏，选择直播+ > 实时音视频 > 应用管理，在应用管理页面，单击创建应用，申请AppID，AppKey等信息。


## 跑通ARTC API Example源码


- 源码下载后，打开Windoes目录
- [下载SDK](https://help.aliyun.com/zh/live/artc-download-the-sdk?spm=a2c4g.11186623.0.0.56ac3f352de4ES#dd9acb7bda986)，解压后
  - 把解压缩包里的x64/Release下的AliRTCSdk.lib拷贝到Demo里的lib/x64目录里
  - 把解压缩包里的x64/Release目录下的alivcffmpeg.dll、AliRTCSdk.dll拷贝到Demo里的x64下的Release和Debug目录下
- 使用Microsoft Visual Studio打开ARTCExample.sln 
- 配置实时音视频AppID和AppKey
进入`Windows/ARTCExample/ARTCExampleDefine.h`将控制台申请的AppID和AppKey填入
```h
// ARTCExampleDefine.h

#define ARTC_APP_ID		"<实时音视频AppID>"
#define ARTC_APP_KEY	"<实时音视频AppKey>"

```
- 选择 x64/x86 debug/release 进行开发和调试；