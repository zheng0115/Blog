# 条件
- Cocoapods版本：0.39，不要用beta版本

- 本地已有git账户

# 添加私有库并提交`Spec Repo`中

1. `cd`到想要创建podspec的文件夹下，终端执行`pod lib create XXX`，XXX是你要建的podspec名字，比如AFNetworking。接着会被问到4个问题。1.是否需要一个例子工程，一般是需要的。2.选择一个测试框架，此处可选。3.是否基于View测试，一般不需要。4.类的前缀是什么，这个类似于老版Xcode创建工程时问到的，只对例子工程起作用，比如HY。回答完这四个问题后会自动执行`pod install`命令创建项目并生成依赖关系。

2. 在XXX目录下的`Pod`文件中添加相应的库文件和资源。

3. 在`Example`文件夹下执行`pod update --no-repo-update`，打开`Example`文件夹下的XXX.xcworkspace，就可以看到之前添加的文件都已经在Pods中了。

4. 编辑demo工程，并测试组件。

5. 将XXX目录push到自己的github仓库中，打上版本tag，并记下该git地址。如果不push到远程仓库中，接下来的podspec验证会报错。

6. 验证podspec是否正确。XXX文件夹下执行`pod lib lint`命令。按照错误提示修改即可，不要有警告和错误。

7. 如果没有注册`trunk`，则执行命令`pod trunk register <你的邮箱地址> 'XXX' --description='<此处填写库描述>'`。否则跳转到步骤9。

8. 邮箱中点击验证，并执行`pod trunk me`来查看是否正确显示个人注册信息。

9. 在XXX文件夹下，执行`pod trunk push XXX.podspec`。

10. 更新本地的repo，`pod repo update`，成功后即可搜到你的专属pod了。搜索命令是`pod search XXX`。

# 参考链接

- [http://blog.wtlucky.com/blog/2015/02/26/create-private-podspec/]()

- [http://www.tuicool.com/articles/6FF7fi]()
