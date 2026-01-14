cmake_minimum_required(VERSION 3.18.1)

project("artc_texture_render")

# 设置 C++ 标准
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 使用静态 C++ 运行时，避免与 Queen SDK 的 libc++_shared.so 冲突
set(CMAKE_ANDROID_STL_TYPE c++_static)

# 添加源文件
add_library(
        artc_texture_render
        SHARED
        texture_renderer.cpp
)

# 查找需要的库
find_library(log-lib log)
find_library(android-lib android)
find_library(EGL-lib EGL)
find_library(GLESv2-lib GLESv2)

# 链接库
target_link_libraries(
        artc_texture_render
        ${log-lib}
        ${android-lib}
        ${EGL-lib}
        ${GLESv2-lib}
)
