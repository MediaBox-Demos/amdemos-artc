#ifndef ARTCEXAMPLE_ORIGIN_AUDIO_DATA_H
#define ARTCEXAMPLE_ORIGIN_AUDIO_DATA_H

#include "napi/native_api.h"
#include "AliRtcEngine.h"
#include "AliRtcEngineAudioFrameListener.h"

static thread_local napi_ref g_origin_audio_data_ref = nullptr;

class OriginAudioData : public AliRTCSdk::IAliRtcEngineAudioFrameListener {
public:
    OriginAudioData(uintptr_t rtcEngineHandler);
    static napi_value Init(napi_env env, napi_value exports);
    static void Destructor(napi_env env, void *nativeObject, void *finalize_hint);

private:
    explicit OriginAudioData();
    ~OriginAudioData();

    static napi_value New(napi_env env, napi_callback_info info);
    static napi_value Enable(napi_env env, napi_callback_info info);

    bool OnCapturedAudioFrame(AliRTCSdk::AliRtcAudioRawData &audioRawData) override;
    bool OnProcessCapturedAudioFrame(AliRTCSdk::AliRtcAudioRawData &audioRawData) override { return true; }
    bool OnPublishAudioFrame(AliRTCSdk::AliRtcAudioRawData &audioRawData) override { return true; }
    bool OnPlaybackAudioFrame(AliRTCSdk::AliRtcAudioRawData &audioRawData) override { return true; }
    bool OnMixedAllAudioFrame(AliRTCSdk::AliRtcAudioRawData &audioRawData) override { return true; }
    bool OnRemoteUserAudioFrame(const char *uid, AliRTCSdk::AliRtcAudioRawData &audioRawData) override { return true; }

private:
    AliRTCSdk::AliRtcEngine *rtcEngine_ = nullptr;
    napi_env env_ = nullptr;
    napi_ref wrapper_ = nullptr;
};

#endif // ARTCEXAMPLE_ORIGIN_AUDIO_DATA_H
