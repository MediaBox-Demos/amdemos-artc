#include "origin_audio_data.h"
#include <hilog/log.h>

#ifndef DECLARE_NAPI_FUNCTION
#define DECLARE_NAPI_FUNCTION(name, func) { name, 0, func, 0, 0, 0, napi_default, 0 }
#endif

#define TAG "OriginAudioData_ARTC"
#define AG_INFO(...) OH_LOG_Print(LogType::LOG_APP, LogLevel::LOG_INFO, 0x1, TAG, __VA_ARGS__)

 OriginAudioData::OriginAudioData(uintptr_t rtcEngineHandler) {
    AG_INFO("OriginAudioData constructor called");
    rtcEngine_ = reinterpret_cast<AliRTCSdk::AliRtcEngine *>(rtcEngineHandler);
    env_ = nullptr;
    wrapper_ = nullptr;
}

OriginAudioData::~OriginAudioData() {
    AG_INFO("OriginAudioData destructor called");
    
    if (rtcEngine_ != nullptr) {
        rtcEngine_->EnableAudioFrameObserver(false, AliRTCSdk::AliRtcAudioSourceCaptured, {});
        rtcEngine_->RegisterAudioFrameListener(nullptr);
    }
    
    if (env_ != nullptr && wrapper_ != nullptr) {
        napi_delete_reference(env_, wrapper_);
    }
}

bool OriginAudioData::OnCapturedAudioFrame(AliRTCSdk::AliRtcAudioRawData &audioRawData) {
    AG_INFO("OriginAudioData::OnCapturedAudioFrame called");
    AG_INFO("Samples: %d, Channels: %d, SampleRate: %d, BytesPerSample: %d",
            audioRawData.numOfSamples, audioRawData.numOfChannels, 
            audioRawData.samplesPerSec, audioRawData.bytesPerSample);
    
    if (audioRawData.dataPtr != nullptr && audioRawData.bytesPerSample == 2) {
        int16_t *audioData = reinterpret_cast<int16_t *>(audioRawData.dataPtr);
        int sampleCount = audioRawData.numOfSamples * audioRawData.numOfChannels;
        int printCount = sampleCount > 10 ? 10 : sampleCount;
        
        AG_INFO("First %d audio samples:", printCount);
        for (int i = 0; i < printCount; i++) {
            AG_INFO("  Sample[%d]: %d", i, audioData[i]);
        }
    }
    return true;
}

void OriginAudioData::Destructor(napi_env env, void *nativeObject, void *finalize_hint) {
    AG_INFO("OriginAudioData::Destructor called");
    reinterpret_cast<OriginAudioData *>(nativeObject)->~OriginAudioData();
}

napi_value OriginAudioData::Init(napi_env env, napi_value exports) {
    AG_INFO("OriginAudioData::Init called");
    
    napi_property_descriptor properties[] = {
        {"enable", 0, Enable, 0, 0, 0, napi_default, 0},
    };

    napi_value constructor;
    napi_status status = napi_define_class(
        env, 
        "OriginAudioData", 
        NAPI_AUTO_LENGTH, 
        New, 
        nullptr, 
        sizeof(properties) / sizeof(properties[0]), 
        properties, 
        &constructor
    );
    
    if (status != napi_ok) {
        AG_INFO("Failed to define class: %d", status);
        return nullptr;
    }

    status = napi_create_reference(env, constructor, 1, &g_origin_audio_data_ref);
    if (status != napi_ok) {
        AG_INFO("Failed to create reference: %d", status);
        return nullptr;
    }

    status = napi_set_named_property(env, exports, "OriginAudioData", constructor);
    if (status != napi_ok) {
        AG_INFO("Failed to set named property: %d", status);
        return nullptr;
    }

    AG_INFO("OriginAudioData initialized successfully");
    return exports;
}

napi_value OriginAudioData::New(napi_env env, napi_callback_info info) {
    AG_INFO("OriginAudioData::New called");

    napi_value newTarget;
    napi_status status = napi_get_new_target(env, info, &newTarget);
    if (status != napi_ok) {
        AG_INFO("Failed to get new target: %d", status);
        return nullptr;
    }

    if (newTarget != nullptr) {
        // 使用 `new OriginAudioData(...)` 调用
        size_t argc = 1;
        napi_value args[1];
        napi_value jsThis;
        
        status = napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
        if (status != napi_ok) {
            AG_INFO("Failed to get callback info: %d", status);
            return nullptr;
        }

        uintptr_t engineHandle = 0;
        if (argc >= 1) {
            napi_valuetype valuetype;
            status = napi_typeof(env, args[0], &valuetype);
            AG_INFO("Argument type: %d", valuetype);
            
            if (status != napi_ok || valuetype == napi_undefined) {
                AG_INFO("Invalid argument type");
            } else if (valuetype == napi_number) {
                int64_t intValue = 0;
                status = napi_get_value_int64(env, args[0], &intValue);
                if (status != napi_ok) {
                    AG_INFO("Failed to get int64 value: %d", status);
                    engineHandle = 0;
                } else {
                    engineHandle = static_cast<uintptr_t>(intValue);
                    AG_INFO("Got number value: %lld, converted to uintptr_t: %lu", 
                           intValue, engineHandle);
                }
            } else if (valuetype == napi_bigint) {
                bool loss;
                status = napi_get_value_bigint_uint64(env, args[0], &engineHandle, &loss);
                if (status != napi_ok) {
                    AG_INFO("Failed to get bigint value: %d", status);
                    engineHandle = 0;
                }
            } else {
                AG_INFO("Unsupported argument type: %d", valuetype);
            }
        }

        AG_INFO("Creating OriginAudioData with engineHandle: %lu (0x%lx)", 
                engineHandle, engineHandle);
        
        OriginAudioData *obj = new OriginAudioData(engineHandle);
        obj->env_ = env;

        status = napi_wrap(env, jsThis, reinterpret_cast<void *>(obj), 
                          OriginAudioData::Destructor, nullptr, &obj->wrapper_);
        if (status != napi_ok) {
            AG_INFO("Failed to wrap object: %d", status);
            delete obj;
            return nullptr;
        }

        return jsThis;
    } else {
        size_t argc = 1;
        napi_value args[1];
        
        status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
        if (status != napi_ok || argc < 1) {
            AG_INFO("Invalid arguments");
            return nullptr;
        }

        napi_value constructor;
        status = napi_get_reference_value(env, g_origin_audio_data_ref, &constructor);
        if (status != napi_ok) {
            AG_INFO("Failed to get reference value: %d", status);
            return nullptr;
        }

        napi_value instance;
        status = napi_new_instance(env, constructor, argc, args, &instance);
        if (status != napi_ok) {
            AG_INFO("Failed to create new instance: %d", status);
            return nullptr;
        }

        return instance;
    }
}

napi_value OriginAudioData::Enable(napi_env env, napi_callback_info info) {
    AG_INFO("========== OriginAudioData::Enable called ==========");

    size_t argc = 1;
    napi_value args[1];
    napi_value jsThis;
    
    napi_status status = napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    if (status != napi_ok) {
        AG_INFO("ERROR: Failed to get callback info: %d", status);
        return nullptr;
    }

    if (argc < 1) {
        AG_INFO("ERROR: Enable method requires 1 argument");
        napi_throw_error(env, nullptr, "Enable method requires 1 argument (enable: boolean)");
        return nullptr;
    }

    bool enable = false;
    status = napi_get_value_bool(env, args[0], &enable);
    if (status != napi_ok) {
        AG_INFO("ERROR: Failed to get boolean value: %d", status);
        napi_throw_error(env, nullptr, "First argument must be a boolean");
        return nullptr;
    }

    OriginAudioData *obj;
    status = napi_unwrap(env, jsThis, reinterpret_cast<void **>(&obj));
    if (status != napi_ok) {
        AG_INFO("ERROR: Failed to unwrap object: %d", status);
        return nullptr;
    }

    AG_INFO("Enable called with enable=%d", enable);
    AG_INFO("Object info: rtcEngine_=%p, env_=%p, wrapper_=%p", 
            obj->rtcEngine_, obj->env_, obj->wrapper_);
    
    int result = -1;
    
    if (obj->rtcEngine_ != nullptr) {
        if (enable) {
            AG_INFO("STEP 1: Enabling audio frame observer");
            
            result = obj->rtcEngine_->RegisterAudioFrameListener(obj);
            AG_INFO("STEP 1 Result: RegisterAudioFrameListener returned %d", result);
            
            if (result == 0) {
                AG_INFO("STEP 2: Configuring audio frame observer");
                
                AliRTCSdk::AliRtcAudioFrameObserverConfig config;
                config.sampleRate = AliRTCSdk::AliRtcAudioSampleRate_48000;
                config.channels = AliRTCSdk::AliRtcMonoAudio;
                config.mode = AliRTCSdk::AliRtcAudioFrameObserverOperationModeReadOnly;
                
                AG_INFO("Config details: sampleRate=%d, channels=%d, mode=%d", 
                       config.sampleRate, config.channels, config.mode);
                
                AG_INFO("STEP 3: Calling EnableAudioFrameObserver");
                
                result = obj->rtcEngine_->EnableAudioFrameObserver(
                    true, 
                    AliRTCSdk::AliRtcAudioSourceCaptured, 
                    config
                );
                AG_INFO("STEP 3 Result: EnableAudioFrameObserver returned %d", result);
                
                if (result != 0) {
                    AG_INFO("Trying alternative audio source: AliRtcAudioSourcePlayback");
                    result = obj->rtcEngine_->EnableAudioFrameObserver(
                        true, 
                        AliRTCSdk::AliRtcAudioSourcePlayback, 
                        config
                    );
                    AG_INFO("Alternative source result: %d", result);
                }
            } else {
                AG_INFO("ERROR: RegisterAudioFrameListener failed with %d", result);
                AG_INFO("Trying EnableAudioFrameObserver without RegisterAudioFrameListener");
                
                AliRTCSdk::AliRtcAudioFrameObserverConfig config;
                config.sampleRate = AliRTCSdk::AliRtcAudioSampleRate_48000;
                config.channels = AliRTCSdk::AliRtcMonoAudio;
                config.mode = AliRTCSdk::AliRtcAudioFrameObserverOperationModeReadOnly;
                
                result = obj->rtcEngine_->EnableAudioFrameObserver(
                    true, 
                    AliRTCSdk::AliRtcAudioSourceCaptured, 
                    config
                );
                AG_INFO("Direct EnableAudioFrameObserver result: %d", result);
            }
        } else {
            AG_INFO("Disabling audio frame observer");
            
            result = obj->rtcEngine_->EnableAudioFrameObserver(
                false, 
                AliRTCSdk::AliRtcAudioSourceCaptured, 
                {}
            );
            AG_INFO("EnableAudioFrameObserver (disable) result: %d", result);
            
            int unregResult = obj->rtcEngine_->RegisterAudioFrameListener(nullptr);
            AG_INFO("RegisterAudioFrameListener (null) result: %d", unregResult);
            
            result = 0; 
            AG_INFO("Disable operation completed, returning 0");
        }
    } else {
        AG_INFO("ERROR: RTC engine is null");
    }

    napi_value returnValue;
    status = napi_create_int32(env, result, &returnValue);
    if (status != napi_ok) {
        AG_INFO("ERROR: Failed to create int32 value: %d", status);
        return nullptr;
    }

    AG_INFO("========== OriginAudioData::Enable returning %d ==========", result);
    return returnValue;
}
