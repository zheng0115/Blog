# 消除PerformSelector警告
```
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [observer performSelector:info->_action withObject:change withObject:object];
#pragma clang diagnostic pop
```

# 在viewDidLoad中调用，可使得view布局不用再考虑导航栏和TabBar高度。IB和手写布局均适合，导航栏是否透明也没有关系。
```
if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
    self.edgesForExtendedLayout = UIRectEdgeNone;
}
```

# UIBarButtonItem如何优雅的调整位置
```
- (NSArray *)rightBarButtonItems {
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    spacer.width = -7;
    UIBarButtonItem *instructionBarButton = [[UIBarButtonItem alloc] initWithCustomView:self.instructionButton];
    return @[spacer, instructionBarButton];
}
- (UIButton *)instructionButton {
    if (!_instructionButton) {
        _instructionButton = ({
            UIButton *b = [UIButton new];
            UIImage *image = [UIImage imageNamed:@"ic_tips"];
            b.frame = CGRectMake(0, 0, image.size.width, image.size.height);
            [b setImage:image forState:UIControlStateNormal];
            [b setImage:[UIImage imageNamed:@"ic_tips_pressed"] forState:UIControlStateHighlighted];
            b;
        });
    }
    return _instructionButton;
}
self.navigationItem.rightBarButtonItems = [self rightBarButtonItems];
```

# 编译
```
// need call super
__attribute((objc_requires_super))

// assume nonnull
NS_ASSUME_NONNULL_BEGIN
NS_ASSUME_NONNULL_END

// 编译时期判断版本信息
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_7_0
  ...
#endif
```

# iOS9 HTTPS
```
<key>NSAppTransportSecurity</key>
<dict>
    <!--Connect to anything (this is probably BAD)-->
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```
