#### Dubbo服务暴露过程

从代码流程可以分为三步

1. 检查配置，没有指定配置使用默认配置，组装成URL
2. 暴露服务，包括本地服务（为了JVM内部服务调用，节省网络IO）和远程服务
3. 注册服务到注册中心

![](C:\software\知识体系图片\dubbo代码角度看服务暴露.jpg)

从对象构建角度分为两步

1. 将服务实现类转换成invoker对象
2. 将invoker对象通过具体协议转换成Exporter

![](C:\software\知识体系图片\dubbo构建角度看服务暴露.jpg)



源码服务暴露的过程图

![](C:\software\知识体系图片\dubbo源码暴露过程.jpg)



#### 为什么要本地暴露

存在同一个JVM多个服务之间相互调用的情况，减少网络IO



#### Dubbo的SPI机制



#### Netty