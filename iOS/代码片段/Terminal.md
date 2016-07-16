```
# 禁止自动拼写纠正
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Finder 显示状态栏
defaults write com.apple.finder ShowStatusBar -bool true

# Finder 显示地址栏
defaults write com.apple.finder ShowPathbar -bool true

# 禁止在网络驱动器上生成 .DS_Store 文件
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# 关闭开机声音
sudo nvram SystemAudioVolume=" "

# 查看当前文件夹下载进度
du -sh *

# 重置launchpad图标
defaults write com.apple.dock ResetLaunchPad -bool true
killall Dock
defaults write com.apple.dock ResetLaunchPad -bool false

# 删除所有.DS_Store文件，恢复Finder文件布局
sudo find / -name ".DS_Store" -depth -exec rm {} \

# 显示隐藏文件，输完重启Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

# Xcode更新后插件失效解决办法
find ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins -name Info.plist -maxdepth 3 | xargs -I{} defaults write {} DVTPlugInCompatibilityUUIDs -array-add `defaults read /Applications/Xcode.app/Contents/Info DVTPlugInCompatibilityUUID`

```
