//
//  AlivcLivePusher.h
//  AlivcLiveCaptureLib
//
//  Created by TripleL on 17/7/13.
//  Copyright © 2017年 Alibaba. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>
#import <ReplayKit/ReplayKit.h>
#import "AlivcLivePushConfig.h"
#import <Cocoa/Cocoa.h>
/// @note 阿里云直播推流SDK从4.4.2版本开始增加license管理，老版本升级到4.4.2及以后版本需要参照阿里云官网获取推流SDK license
///  其SDK接入流程变化：
///  1. 在Info.plist中配置licenseKey和licenseFile
///  2.调用[AlivcLiveBase registerSDK]注册推流SDK
///  3.监听onLicenceCheck回调，确保license校验通过
///  4.创建推流对象，开始直播推流
///  其相关文档参考https://help.aliyun.com/document_detail/431730.html、
///  https://help.aliyun.com/document_detail/94821.html、https://help.aliyun.com/document_detail/94828.html
/**
 * @brief 设备传输类型
*/
typedef NS_ENUM(NSInteger, AlivcLiveDeviceTransportType) {
  AlivcLiveDeviceTransportTypeUnknown      = 0,
  AlivcLiveDeviceTransportTypeBuiltIn      = 1,
  AlivcLiveDeviceTransportTypeBluetooth    = 2,
  AlivcLiveDeviceTransportTypeUSB          = 3,
  AlivcLiveDeviceTransportTypeAggregate    = 4,
  AlivcLiveDeviceTransportTypeVirtual      = 5,
  AlivcLiveDeviceTransportTypePCI          = 6,
  AlivcLiveDeviceTransportTypeFireWire     = 7,
  AlivcLiveDeviceTransportTypeBluetoothLE  = 8,
  AlivcLiveDeviceTransportTypeHDMI         = 9,
  AlivcLiveDeviceTransportTypeDisplayPort  = 10,
  AlivcLiveDeviceTransportTypeAirPlay      = 11,
  AlivcLiveDeviceTransportTypeAVB          = 12,
  AlivcLiveDeviceTransportTypeThunderbolt  = 13
};

/**
 * @brief 设备信息
 */
@interface AlivcLiveDeviceInfo : NSObject

@property (nonatomic, copy) NSString * _Nullable deviceName;   // 设备名称
@property (nonatomic, copy) NSString * _Nullable deviceID;     // 设备ID
@property (nonatomic, assign) AlivcLiveDeviceTransportType deviceTransportType; // 设备传输类型

@end


/**
 推流类
 */
@interface AlivcLivePusher : NSObject

/**
 init

 @param config 推流配置
 @return self:success  nil:failure
 */
- (instancetype)initWithConfig:(AlivcLivePushConfig *)config;
- (void)destroy;

/**
 开始预览 同步接口

 @param previewView 预览view
 @return 0:success  非0:failure
 */
- (int)startPreview:(NSView *)previewView;


/**
 停止预览

 @return 0:success  非0:failure
 */
- (int)stopPreview;

- (int)startCamera;
- (void)stopCamera;

/**
 开始推流 同步接口

 @param pushURL 推流URL
 @return 0:success  非0:failure
 */
- (int)startPushWithURL:(NSString *)pushURL;


/**
 停止推流
 
 @return 0:success  非0:failure
 */
- (int)stopPush;

/**
 * @brief 获取摄像头列表
 * @return 找到的系统中摄像头名称列表
 */
- (NSArray<AlivcLiveDeviceInfo *> *_Nullable)getCameraList;

/**
 * @brief 获取当前使用的摄像头名称
 */
- (NSString *_Nullable)getCurrentCamera;

/**
 * @brief 获取当前使用的摄像头ID
 */
- (NSString *_Nullable)getCurrentCameraID;

/**
 * @brief 选择摄像头(Name)
 * @param camera   摄像头名称
 */
- (void)setCurrentCamera:(NSString *_Nonnull)camera;

/**
 * @brief 选择摄像头(ID)
 * @param cameraID   摄像头ID
 */
- (void)setCurrentCameraWithID:(NSString *_Nonnull)cameraID;

/**
 * @brief 获取系统中的录音设备列表
 */
- (NSArray<AlivcLiveDeviceInfo *> *_Nullable)getAudioCaptures;

/**
 * @brief 获取使用的录音设备名称
 */
- (NSString *_Nullable)getCurrentAudioCapture;

/**
 * @brief 获取使用的录音设备ID
 */
- (NSString *_Nullable)getCurrentAudioCaptureID;

/**
 * @brief 选择录音设备(Name)
 * @param capture  音频采集设备名称
 */
- (void)setCurrentAudioCapture:(NSString *_Nonnull)capture;

/**
 * @brief 选择录音设备(ID)
 * @param captureID  音频采集设备Id
 */
- (void)setCurrentAudioCaptureWithID:(NSString *_Nonnull)captureID;



/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//      美颜相关api，在v4.2.0版本已删除，推流SDK不再提供内置美颜功能，请使用阿里云Queen提供的美颜服务
//      详见：https://help.aliyun.com/document_detail/211047.html?spm=a2c4g.11174283.6.736.79c5454ek41M8B
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@end
