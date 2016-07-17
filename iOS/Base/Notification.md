delegate、notification、KVO、block

# delegate VS block
在网络下载器回调时，一般使用 delegate 和 block 两种方式，很少用 notification 和 KVO 的。

delegate 有个缺点：如果使用多个下载器下载不同数据时，那么就得在 delegate 的回调方法里进行区分。这么写代码会令回调方法变得很长，而且还要把下载器保存为实例变量。
block 把发出请求和回调处理放在了一起，不同业务的处理也可以很好的分开。在多个网络请求有依赖关系的时候，block 也比 delegate 好处理的多。
