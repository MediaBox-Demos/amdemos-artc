//
// Created on 2025/12/29.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#ifndef ARTCEXAMPLE_ORIGIN_VIDEO_DATA_H
#define ARTCEXAMPLE_ORIGIN_VIDEO_DATA_H

#include "napi/native_api.h"
#include "AliRtcEngine.h"
#include "AliRtcEngineVideoFrameListener.h"
#include <string>

static thread_local napi_ref g_origin_video_data_ref = nullptr;

class OriginVideoData : public AliRTCSdk::IAliRtcEngineVideoFrameListener {
public:
    OriginVideoData(uintptr_t rtcEngineHandler);
    static napi_value Init(napi_env env, napi_value exports);
    static void Destructor(napi_env env, void *nativeObject, void *finalize_hint);

private:
    explicit OriginVideoData();
    ~OriginVideoData();

    void SaveI420Buffer(const uint8_t *buf, int width, int height, const std::string &filename);

    static napi_value New(napi_env env, napi_callback_info info);
    static napi_value Enable(napi_env env, napi_callback_info info);
    static napi_value TakeSnapshot(napi_env env, napi_callback_info info);

    uint32_t GetObservedFramePosition() override;
    bool onLocalVideoSample(AliRTCSdk::AliRtcVideoSource videoSourceType, 
                           AliRTCSdk::AliRtcVideoRawData &videoRawData) override;
    bool OnPreEncodeVideoSample(AliRTCSdk::AliRtcVideoSource videoSourceType, 
                               AliRTCSdk::AliRtcVideoRawData &videoRawData) override;
    bool OnRemoteVideoSample(const char *uid, 
                            AliRTCSdk::AliRtcVideoSource videoSourceType, 
                            AliRTCSdk::AliRtcVideoRawData &videoRawData) override;
    AliRTCSdk::AliRtcVideoObserAlignment GetVideoAlignment() override;
    bool GetObserverDataMirrorApplied() override;

private:
    AliRTCSdk::AliRtcEngine *rtcEngine_ = nullptr;
    napi_env env_ = nullptr;
    napi_ref wrapper_ = nullptr;
    bool takeSnapshot_ = false;
    bool enabled_ = false;
};

#endif // ARTCEXAMPLE_ORIGIN_VIDEO_DATA_H
