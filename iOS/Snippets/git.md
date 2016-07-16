# .gitconfig
```
[alias]
 st = status
 ci = commit -m
 co = checkout
 br = branch
 hist = log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short
 type = cat-file -t
 dump = cat-file -p
```

# iOS .gitignore
```
# Xcode
#
# gitignore contributors: remember to update Global/Xcode.gitignore, Objective-C.gitignore & Swift.gitignore
## Build generated
build/
Build/
DerivedData
## Various settings
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata
## Other
*.xccheckout
*.moved-aside
*.xcuserstate
*.xcscmblueprint
.DS_Store
.DS_Store?
## Obj-C/Swift specific
*.hmap
*.ipa
# CocoaPods
#
# We recommend against adding the Pods directory to your .gitignore. However
# you should judge for yourself, the pros and cons are mentioned at:
# http://guides.cocoapods.org/using/using-cocoapods.html#should-i-check-the-pods-directory-into-source-control
#
Podfile.lock
Pods/
*.xcworkspace
# Carthage
#
# Add this line if you want to avoid checking in source code from Carthage dependencies.
# Carthage/Checkouts
Carthage/Build
# fir
fir_build/
# AppCode
.idea/
```