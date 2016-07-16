# iOS自动打包并上传至fir

```
#!/bin/sh

# 1. 该脚本需要放在工程根目录下
# 2. 设置Xcode里面的Locations的Derived Data：点击advanced，设置Build Location设置为Custom：Relative to Workspace，Build->build
# 3. 工程中设置的Provision需要与脚本中的名称相同
# 4. 安装fir命令行工具，地址 https://github.com/FIRHQ/fir-cli/blob/master/README.md

# 以下参数需要自定义
# ==============================================================================
Code_Sign_Identity="iPhone Developer: wei huang (8W8QA2NQUP)" # 开发或发布的根证书全名
Mobile_Provision="./bangbangDevep.mobileprovision" # mobile provision
Workspace_Name="HYIM"
Scheme="HYIM_release"
Configuration="Release" # Release，Debug，AdHoc等
Fir_API_Token="957611a49171df34195bec8a1f0b2082"
# ==============================================================================

# 变量
# ==============================================================================
App_Profile_UUID=`/usr/libexec/plistbuddy -c Print:UUID /dev/stdin <<< \ \`security cms -D -i $Mobile_Provision\``
SDK="iphoneos"

# Build文件夹路径
Build_Directory="$PWD/Build"
# Ipa文件夹路径，不存在就创建
IPA_Directory="$PWD/IPA"
if [ ! -d "$IPA_Directory" ]; then
mkdir "$IPA_Directory"
fi

# IPA名称
IPA_Name="${Scheme}_$(date +"%Y-%m-%d-%H-%M")"
# App文件路径
Build_Path="$Build_Directory/Products/$Configuration-iphoneos/$Scheme.app"
# IPA文件路径
IPA_Path="$IPA_Directory/$IPA_Name.ipa"
# ==============================================================================

# CLEAN
# ==============================================================================
xcodebuild clean && \
say "Clean succeeded" && \
# ==============================================================================

# COCOAPODS
# ==============================================================================
rm -rf $Workspace_Name.xcworkspace Pods Podfile.lock && \
pod install --no-repo-update && \
say "Pod succeeded" && \
# ==============================================================================

# BUILD
# ==============================================================================
xcodebuild -workspace $Workspace_Name.xcworkspace \
           -scheme $Scheme \
           -configuration $Configuration \
           -sdk $SDK \
           CODE_SIGN_IDENTITY="$Code_Sign_Identity" \
           APP_PROFILE="$App_Profile_UUID" build && \
say "Build succeeded" && \
# ==============================================================================

# PACKAGE
# ==============================================================================
/usr/bin/xcrun -sdk $SDK PackageApplication \
               -v $Build_Path \
               -o $IPA_Path && \
say "Package succeeded" && \
# ==============================================================================

# UPLOAD
# ==============================================================================
fir publish $IPA_Path -T $Fir_API_Token && \
say "Upload succeeded"
say "All succeed, yeah yeah yeah"
# ==============================================================================
```
