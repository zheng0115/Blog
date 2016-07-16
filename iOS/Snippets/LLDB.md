```
(lldb) p [UIScreen mainScreen].bounds
error: property 'bounds' not found on object of type 'id'
error: 1 errors parsing expression
(lldb) expr @import UIKit
(lldb) p [UIScreen mainScreen].bounds
(CGRect) $0 = (origin = (x = 0, y = 0), size = (width = 320, height = 568))
```
