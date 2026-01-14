#!/bin/bash
set -e

# Get current directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Setup ANGLE if needed
if [ ! -d "angle" ]; then
    source ./setup-angle-mac.sh
else
    # Add depot_tools to PATH
    export PATH="$PATH:$SCRIPT_DIR/depot_tools"
fi


# Go to ANGLE directory
cd angle

# Common GN args for all android builds
COMMON_ARGS='
    is_debug=false
    is_component_build=false
    angle_standalone=true
    angle_build_tests=false

    # Enable official build optimizations
    is_official_build=true
    chrome_pgo_phase=0

    # Disable unused backends
    angle_enable_d3d9=false
    angle_enable_d3d11=false
    angle_enable_gl=true
    angle_enable_null=false
    angle_enable_vulkan=true
    angle_enable_wgpu=false

    # Language settings
    angle_enable_essl=false
    angle_enable_glsl=true

    # Optimize for size
    symbol_level=0
    strip_debug_info=true
    angle_enable_trace=false
'

# Build for macOS ARM64
echo "Building ANGLE for Android ARM64..."
gn gen out/android-arm64 --args="
    target_os=\"android\"
    target_cpu=\"arm64\"
    $COMMON_ARGS
"

ninja -C out/Android libEGL libGLESv2 libGLESv1_CM

# Create new directory structure
rm -rf ../build/android/arm64/lib
mkdir -p ../build/android/arm64/lib
cp -R out/android-arm64/*.so ../build/android/arm64/lib/

# Build for Android ARM
echo "Building ANGLE for Android ARM..."
gn gen out/android-arm --args="
    target_os=\"mac\"
    target_cpu=\"x64\"
    $COMMON_ARGS
"
ninja -C out/android-arm libEGL libGLESv2 libGLESv1_CM

# Create new directory structure
rm -rf ../build/android/arm/lib
mkdir -p ../build/android/arm/lib
cp -R out/android-arm/*.so ../build/android/arm/lib/

# Create header directories for each architecture
mkdir -p build/android/arm64/include/{EGL,GLES,GLES2,GLES3,KHR}
mkdir -p build/android/arm/include/{EGL,GLES,GLES2,GLES3,KHR}

# Copy headers to each architecture directory
cp -R angle/include/EGL/*.h build/android/arm64/include/EGL/
cp -R angle/include/GLES/*.h build/android/arm64/include/GLES/
cp -R angle/include/GLES2/*.h build/android/arm64/include/GLES2/
cp -R angle/include/GLES3/*.h build/android/arm64/include/GLES3/
cp -R angle/include/KHR/*.h build/android/arm64/include/KHR/

cp -R angle/include/EGL/*.h build/android/arm/include/EGL/
cp -R angle/include/GLES/*.h build/android/arm/include/GLES/
cp -R angle/include/GLES2/*.h build/android/arm/include/GLES2/
cp -R angle/include/GLES3/*.h build/android/arm/include/GLES3/
cp -R angle/include/KHR/*.h build/android/arm/include/KHR/

echo "Android builds complete! Libraries are available in:"
echo "  - build/android/arm64/lib (for arm64)"
echo "  - build/mac/arm/lib (for arm)"
echo "Headers are included in the include directory within each build folder."
