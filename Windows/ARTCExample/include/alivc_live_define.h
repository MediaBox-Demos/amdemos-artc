#ifndef alivc_live_defined_h
#define alivc_live_defined_h

#ifdef __ANDROID__
#undef ALIVCLIVEEXPORT
#define ALIVCLIVEEXPORT __attribute__((visibility("default")))
#else
#define ALIVCLIVEEXPORT 
#endif

#if defined(_WIN32)
#if defined(ALIRTCSDK_EXPORTS)
#define ALIVC_LIVE_API __declspec(dllexport)
#else
#define ALIVC_LIVE_API __declspec(dllimport)
#endif
#elif defined(__ANDROID__)
#define ALIVC_LIVE_API __attribute__((visibility("default")))
#elif defined(__APPLE__)
#include <TargetConditionals.h>
#define ALIVC_LIVE_API __attribute__((visibility ("default")))
#else
#define ALIVC_LIVE_API
#endif

#endif
