# the minimum version of CMake.
cmake_minimum_required(VERSION 3.5.0)
project(ARTCExample)

set(NATIVERENDER_ROOT_PATH ${CMAKE_CURRENT_SOURCE_DIR})

if(DEFINED PACKAGE_FIND_FILE)
    include(${PACKAGE_FIND_FILE})
endif()

include_directories(
    ${NATIVERENDER_ROOT_PATH}
    ${NATIVERENDER_ROOT_PATH}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../oh_modules/@aliyun_video_cloud/alivcsdk_artc/include
)

set(ARTC_LIB_PATH ${CMAKE_CURRENT_SOURCE_DIR}/../../../oh_modules/@aliyun_video_cloud/alivcsdk_artc/libs)

add_library(alirtcsdk SHARED IMPORTED)
set_target_properties(alirtcsdk PROPERTIES
    IMPORTED_LOCATION ${ARTC_LIB_PATH}/${CMAKE_OHOS_ARCH_ABI}/libalirtcsdk.so
)

add_library(advancedusage SHARED
    napi_init.cpp
    origin_audio_data.cpp
    origin_video_data.cpp
)

target_link_libraries(advancedusage PUBLIC
    alirtcsdk                # 阿里ARTC SDK
    libace_napi.z.so         # ACE NAPI框架
    libc++.so                # C++标准库
    libhilog_ndk.z.so
)
