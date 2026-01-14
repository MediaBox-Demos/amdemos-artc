//
// Created on 2025/12/29.
//
// Node APIs are not fully supported. To solve the compilation error of the interface cannot be found,
// please include "napi/native_api.h".

#include "origin_video_data.h"
#include <hilog/log.h>
#include <cstdio>
#include <cstring>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>

#ifndef DECLARE_NAPI_FUNCTION
#define DECLARE_NAPI_FUNCTION(name, func) { name, 0, func, 0, 0, 0, napi_default, 0 }
#endif

#define TAG "OriginVideoData_ARTC"
#define AG_INFO(...) OH_LOG_Print(LogType::LOG_APP, LogLevel::LOG_INFO, 0x1, TAG, __VA_ARGS__)
#define AG_ERROR(...) OH_LOG_Print(LogType::LOG_APP, LogLevel::LOG_ERROR, 0x1, TAG, __VA_ARGS__)
#define AG_WARNING(...) OH_LOG_Print(LogType::LOG_APP, LogLevel::LOG_WARN, 0x1, TAG, __VA_ARGS__)

#define SAVE_FILE_PATH "/data/app/el2/100/base/com.example.artcexample/cache/capture.i420"

static bool CreateDirectoryIfNotExists(const char* path) {
    struct stat st;
    if (stat(path, &st) != 0) {
        char tmp[256];
        char* p = nullptr;
        size_t len = strlen(path);

        if (len > sizeof(tmp) - 1) {
            return false;
        }
        
        strcpy(tmp, path);
        
        for (p = tmp + 1; *p; p++) {
            if (*p == '/') {
                *p = 0;
                if (access(tmp, F_OK) != 0) {
                    if (mkdir(tmp, 0755) != 0) {
                        AG_ERROR("Create dir failed: %s, errno=%d, msg=%s", tmp, errno, strerror(errno));
                        return false;
                    }
                }
                *p = '/';
            }
        }
        
        if (access(tmp, F_OK) != 0) {
            if (mkdir(tmp, 0755) != 0) {
                AG_ERROR("Create final dir failed: %s, errno=%d, msg=%s", tmp, errno, strerror(errno));
                return false;
            }
        }
    }
    return true;
}

OriginVideoData::OriginVideoData(uintptr_t rtcEngineHandler) {
    AG_INFO("OriginVideoData constructor called");
    rtcEngine_ = reinterpret_cast<AliRTCSdk::AliRtcEngine *>(rtcEngineHandler);
    env_ = nullptr;
    wrapper_ = nullptr;
    takeSnapshot_ = false;
    enabled_ = false;
}

OriginVideoData::~OriginVideoData() {
    AG_INFO("OriginVideoData destructor called");
    
    if (rtcEngine_ != nullptr && enabled_) {
        rtcEngine_->RegisterVideoFrameListener(nullptr);
        enabled_ = false;
    }
    
    if (env_ != nullptr && wrapper_ != nullptr) {
        napi_delete_reference(env_, wrapper_);
    }
}

void OriginVideoData::SaveI420Buffer(const uint8_t *buf, int width, int height, const std::string &filename) {
    AG_INFO("OriginVideoData::SaveI420Buffer -- width=%d, height=%d, filename=%s", 
            width, height, filename.c_str());

    if (buf == nullptr) {
        AG_ERROR("Buffer pointer is null!");
        return;
    }
    if (width <= 0 || height <= 0) {
        AG_ERROR("Invalid dimensions: width=%d, height=%d", width, height);
        return;
    }

    int ySize = width * height;
    int uvSize = (width / 2) * (height / 2);
    int totalSize = ySize + uvSize * 2;

    size_t lastSlash = filename.find_last_of('/');
    if (lastSlash != std::string::npos) {
        std::string dirPath = filename.substr(0, lastSlash);
        if (!CreateDirectoryIfNotExists(dirPath.c_str())) {
            AG_ERROR("Failed to create directory: %s", dirPath.c_str());
            // 降级到临时目录
            if (!CreateDirectoryIfNotExists("/data/local/tmp")) {
                return;
            }
        }
    }

    FILE *file = fopen(filename.c_str(), "wb+");
    if (!file) {
        AG_ERROR("Failed to open file for writing: %s, errno=%d, msg=%s", 
                filename.c_str(), errno, strerror(errno));
        return;
    }

    size_t written = fwrite(buf, 1, totalSize, file);
    if (written != static_cast<size_t>(totalSize)) {
        AG_ERROR("Failed to write all data: written=%zu, expected=%d", 
                written, totalSize);
    } else {
        AG_INFO("Successfully saved I420 buffer to: %s", filename.c_str());
        AG_INFO("File size: %d bytes, dimensions: %dx%d", totalSize, width, height);
    }

    fclose(file);
}

uint32_t OriginVideoData::GetObservedFramePosition() {
    return static_cast<uint32_t>(AliRTCSdk::AliRtcPositionPostCapture);
}

bool OriginVideoData::onLocalVideoSample(AliRTCSdk::AliRtcVideoSource videoSourceType, 
                                        AliRTCSdk::AliRtcVideoRawData &videoRawData) {
    if (!enabled_ || videoSourceType != AliRTCSdk::AliRtcVideoSourceCamera) {
        return false;
    }
    
    AG_INFO("Video format: %d, width: %d, height: %d, stride: %d, dataLength: %d",
            videoRawData.format, videoRawData.width, videoRawData.height, 
            videoRawData.stride, videoRawData.dataLength);
    
    if (takeSnapshot_) {
        if (videoRawData.format == AliRTCSdk::AliRtcVideoFormatI420) {
            AG_INFO("Processing I420 format video frame");
            
            if (videoRawData.dataPtr != nullptr) {
                SaveI420Buffer(static_cast<const uint8_t*>(videoRawData.dataPtr), 
                             videoRawData.width, videoRawData.height, SAVE_FILE_PATH);
                takeSnapshot_ = false;
                AG_INFO("Snapshot saved successfully");
            } else {
                AG_ERROR("I420 dataPtr is null");
            }
        } else {
            // 非I420格式，打印警告信息
            AG_WARNING("Ignoring non-I420 video format: %d. Only AliRtcVideoFormatI420 (1) is supported.", 
                      videoRawData.format);
            
            // 打印支持的格式信息
            AG_WARNING("Expected format: AliRtcVideoFormatI420 = 1");
            AG_WARNING("Current format: %d", videoRawData.format);
            
            takeSnapshot_ = false;
            AG_ERROR("Failed to take snapshot: unsupported video format");
            
            return false;
        }
    }
    
    return false; // 只读模式，不写回SDK
}

bool OriginVideoData::OnPreEncodeVideoSample(AliRTCSdk::AliRtcVideoSource videoSourceType, 
                                           AliRTCSdk::AliRtcVideoRawData &videoRawData) {
    return false;
}

bool OriginVideoData::OnRemoteVideoSample(const char *uid, 
                                        AliRTCSdk::AliRtcVideoSource videoSourceType, 
                                        AliRTCSdk::AliRtcVideoRawData &videoRawData) {
    return false;
}

AliRTCSdk::AliRtcVideoObserAlignment OriginVideoData::GetVideoAlignment() {
    return AliRTCSdk::AliRtcAlignmentDefault;
}

bool OriginVideoData::GetObserverDataMirrorApplied() {
    return false;
}

void OriginVideoData::Destructor(napi_env env, void *nativeObject, void *finalize_hint) {
    AG_INFO("OriginVideoData::Destructor called");
    reinterpret_cast<OriginVideoData *>(nativeObject)->~OriginVideoData();
}

napi_value OriginVideoData::Init(napi_env env, napi_value exports) {
    AG_INFO("OriginVideoData::Init called");
    
    napi_property_descriptor properties[] = {
        DECLARE_NAPI_FUNCTION("enable", Enable),
        DECLARE_NAPI_FUNCTION("takeSnapshot", TakeSnapshot),
    };

    napi_value constructor;
    napi_status status = napi_define_class(
        env, 
        "OriginVideoData", 
        NAPI_AUTO_LENGTH, 
        New, 
        nullptr, 
        sizeof(properties) / sizeof(properties[0]), 
        properties, 
        &constructor
    );
    
    if (status != napi_ok) {
        AG_ERROR("Failed to define class: %d", status);
        return nullptr;
    }

    status = napi_create_reference(env, constructor, 1, &g_origin_video_data_ref);
    if (status != napi_ok) {
        AG_ERROR("Failed to create reference: %d", status);
        return nullptr;
    }

    status = napi_set_named_property(env, exports, "OriginVideoData", constructor);
    if (status != napi_ok) {
        AG_ERROR("Failed to set named property: %d", status);
        return nullptr;
    }

    AG_INFO("OriginVideoData initialized successfully");
    return exports;
}

napi_value OriginVideoData::New(napi_env env, napi_callback_info info) {
    AG_INFO("OriginVideoData::New called");

    napi_value newTarget;
    napi_status status = napi_get_new_target(env, info, &newTarget);
    if (status != napi_ok) {
        AG_ERROR("Failed to get new target: %d", status);
        return nullptr;
    }

    if (newTarget != nullptr) {
        // 使用 `new OriginVideoData(...)` 调用
        size_t argc = 1;
        napi_value args[1];
        napi_value jsThis;
        
        status = napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
        if (status != napi_ok) {
            AG_ERROR("Failed to get callback info: %d", status);
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
                    AG_ERROR("Failed to get int64 value: %d", status);
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
                    AG_ERROR("Failed to get bigint value: %d", status);
                    engineHandle = 0;
                }
            } else {
                AG_INFO("Unsupported argument type: %d", valuetype);
            }
        }

        AG_INFO("Creating OriginVideoData with engineHandle: %lu (0x%lx)", 
                engineHandle, engineHandle);
        
        OriginVideoData *obj = new OriginVideoData(engineHandle);
        obj->env_ = env;

        status = napi_wrap(env, jsThis, reinterpret_cast<void *>(obj), 
                          OriginVideoData::Destructor, nullptr, &obj->wrapper_);
        if (status != napi_ok) {
            AG_ERROR("Failed to wrap object: %d", status);
            delete obj;
            return nullptr;
        }

        return jsThis;
    } else {
        size_t argc = 1;
        napi_value args[1];
        
        status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
        if (status != napi_ok || argc < 1) {
            AG_ERROR("Invalid arguments");
            return nullptr;
        }

        napi_value constructor;
        status = napi_get_reference_value(env, g_origin_video_data_ref, &constructor);
        if (status != napi_ok) {
            AG_ERROR("Failed to get reference value: %d", status);
            return nullptr;
        }

        napi_value instance;
        status = napi_new_instance(env, constructor, argc, args, &instance);
        if (status != napi_ok) {
            AG_ERROR("Failed to create new instance: %d", status);
            return nullptr;
        }

        return instance;
    }
}

napi_value OriginVideoData::Enable(napi_env env, napi_callback_info info) {
    AG_INFO("========== OriginVideoData::Enable called ==========");

    size_t argc = 1;
    napi_value args[1];
    napi_value jsThis;
    
    napi_status status = napi_get_cb_info(env, info, &argc, args, &jsThis, nullptr);
    if (status != napi_ok) {
        AG_ERROR("ERROR: Failed to get callback info: %d", status);
        return nullptr;
    }

    if (argc < 1) {
        AG_ERROR("ERROR: Enable method requires 1 argument");
        napi_throw_error(env, nullptr, "Enable method requires 1 argument (enable: boolean)");
        return nullptr;
    }

    bool enable = false;
    status = napi_get_value_bool(env, args[0], &enable);
    if (status != napi_ok) {
        AG_ERROR("ERROR: Failed to get boolean value: %d", status);
        napi_throw_error(env, nullptr, "First argument must be a boolean");
        return nullptr;
    }

    OriginVideoData *obj;
    status = napi_unwrap(env, jsThis, reinterpret_cast<void **>(&obj));
    if (status != napi_ok) {
        AG_ERROR("ERROR: Failed to unwrap object: %d", status);
        return nullptr;
    }

    AG_INFO("Enable called with enable=%d", enable);
    AG_INFO("Object info: rtcEngine_=%p, env_=%p, wrapper_=%p", 
            obj->rtcEngine_, obj->env_, obj->wrapper_);
    
    int result = -1;
    
    if (obj->rtcEngine_ != nullptr) {
        if (enable && !obj->enabled_) {
            AG_INFO("STEP 1: Enabling video frame observer");
            
            result = obj->rtcEngine_->RegisterVideoFrameListener(obj);
            AG_INFO("STEP 1 Result: RegisterVideoFrameListener returned %d", result);
            
            if (result == 0) {
                obj->enabled_ = true;
                AG_INFO("Video frame observer enabled successfully");
            } else {
                AG_ERROR("Failed to enable video frame observer: %d", result);
            }
        } else if (!enable && obj->enabled_) {
            AG_INFO("Disabling video frame observer");
            
            result = obj->rtcEngine_->RegisterVideoFrameListener(nullptr);
            AG_INFO("RegisterVideoFrameListener (null) result: %d", result);
            
            obj->enabled_ = false;
            AG_INFO("Video frame observer disabled successfully");
            
            result = 0; 
        } else {
            AG_INFO("No change needed (already %s)", enable ? "enabled" : "disabled");
            result = 0; 
        }
    } else {
        AG_ERROR("ERROR: RTC engine is null");
    }

    napi_value returnValue;
    status = napi_create_int32(env, result, &returnValue);
    if (status != napi_ok) {
        AG_ERROR("ERROR: Failed to create int32 value: %d", status);
        return nullptr;
    }

    AG_INFO("========== OriginVideoData::Enable returning %d ==========", result);
    return returnValue;
}

napi_value OriginVideoData::TakeSnapshot(napi_env env, napi_callback_info info) {
    AG_INFO("OriginVideoData::TakeSnapshot called");

    napi_value jsThis;
    napi_status status = napi_get_cb_info(env, info, nullptr, nullptr, &jsThis, nullptr);
    if (status != napi_ok) {
        AG_ERROR("Failed to get callback info: %d", status);
        return nullptr;
    }

    OriginVideoData *obj;
    status = napi_unwrap(env, jsThis, reinterpret_cast<void **>(&obj));
    if (status != napi_ok) {
        AG_ERROR("Failed to unwrap object: %d", status);
        return nullptr;
    }

    if (!obj->enabled_) {
        AG_ERROR("Cannot take snapshot: video frame observer is not enabled");
        napi_value result;
        napi_create_int32(env, -1, &result);
        return result;
    }

    obj->takeSnapshot_ = true;
    AG_INFO("Snapshot flag set to true, next I420 video frame will be saved to: %s", SAVE_FILE_PATH);
    AG_INFO("Note: Only I420 format (AliRtcVideoFormatI420 = 1) will be processed");

    napi_value result;
    napi_create_int32(env, 0, &result);
    return result;
}