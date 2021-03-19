##### 概述

Eureka遵循AP（avaliability，Partition tolerance分区容错）原则，采用C-S服务架构，用于定位服务实现服务发现和故障转移   （CPA理论）



#### CPA理论

一致性，可用性，分区容错性（P）

##### 组件

Eureka Server：提供服务，各个节点启动后会在server注册信息，这样server服务注册表会存储所有可用的服务节点信息

Eureka Client：Java客户端，简化和server的交互，client内置了 负载均衡器（轮询负载算法），启动成功后会向server发送心跳（30秒一次），如果server在3个心跳周期内没有收到某个client节点的信号，就会将这个节点从服务注册表中移除（默认90秒）



##### 保护机制

默认情况下，server在一定时间内没有收到某个微服务实例的心跳，server会注销该实例，但是在网络分区故障发生时，微服务和server之间无法通信，以上行为就会变得危险，因为微服务本身是可用健康的，此时本不应该注销这个微服务。eureka server通过“自我保护”模式来解决这个问题。

当Eureka Server节点在短时间内丢失了过多的客户端,在15分钟内超过15%（100%-85%）的客户端节点都没有正常的心跳，那么Eureka就认为客户端与注册中心出现了网络故障，Eureka Server就会进入自我保护模式，服务注册表中的信息就会被保护不做删除。当收到的心跳数恢复到阈值之上，Eureka Server就会退出保护模式。

Eurake有一个配置参数eureka.server.renewalPercentThreshold，定义了renews 和renews threshold的比值，默认值为0.85。可以修改这个参数

保护机制是对网络异常的一种安全应对措施。

```yaml
# 取消自我保护模式
eureka.server.enable-self-preservation=false
# 实例注销时间
eureka.instance.lease-expiration-duration-in-seconds=100
```



由于客户端30s向服务端发送心跳，1分钟心跳数是2，但是服务器要求心跳数是3，所以低于阈值，自动进入了保护模式。

也就是Renews 过去一分钟收到的心跳数如果小于等于Renews threshold，就会进入保护模式（eureka-server最后一分钟收到的心跳次数小于等于总心跳次数的85%）

![image-20200516103643298](C:\Users\honva\AppData\Roaming\Typora\typora-user-images\image-20200516103643298.png)

Renews threshold（server期待收到的心跳数）：clients*(60/30) * 0.85,相当于clients*1.7,也就是10个客户端的话，一分钟收到的心跳数期待是17，低于这个值就会进入保护机制。15分钟计算一次renew threshold

Renews（上一分钟收到的心跳数）:2*n

```yaml
# renews阈值调整
renewal-percent-threshold: 0.7
```



#### eureka和zookeeper区别

eureka保证的是AP，也就是可用性优先，在集群中master失效后，由于保证了可用性，所以服务列表中可能有服务不是最新的，而zookeeper则保证CP，也就是一致性优先，当master失效后，选举master期间，服务是不可用的



#### eureka服务端、客户端缓存

服务端缓存时间是30秒，通过API获取的服务列表信息可能不是最新的，但是通过web UI查看的服务列表这是最新的。

客户端缓存时间也是30秒，当服务端不可用时，客户端会使用缓存的地址进行请求



#### Eureka 集群

​	server端配置

```yaml
spring.application.name=eureka-server
server.port=8081
# 需要指定域名
eureka.instance.hostname=eureka8081.com
# 关闭自我注册
eureka.client.register-with-eureka=false
# 关闭从eureka拉去服务信息
eureka.client.fetch-registry=false

eureka.client.service-url.defaultZone=http://eureka8082.com:8082/eureka/
```

```yaml
spring.application.name=eureka-server2
server.port=8082
eureka.instance.hostname=eureka8082.com
# 关闭自我注册
eureka.client.register-with-eureka=false
# 关闭从eureka拉去服务信息
eureka.client.fetch-registry=false
eureka.client.service-url.defaultZone=http://eureka8081.com:8081/eureka/
```

​	client端配置

```yaml
spring.application.name=eureka-client
server.port=8090
eureka.client.service-url.defaultZone=http://eureka8081.com:8081/eureka/,http://eureka8082.com:8082/eureka/
```

##### 各种参数

1. 服务端缓存 

   通过API 获取服务注册表信息可能给是不是最新的，因为存在缓存，缓存时间30s，但是通过web UI查看，可以实时看到，因为web UI上没有缓存

```yaml
eureka.server.response-cache-update-interval-ms
```

2. 客户端缓存

   从服务端获取注册表信息，默认是30s,可以在EurekaClientConfigBean中查看

   ```yaml
   eureka.client.registry-fetch-interval-seconds=30
   ```

   客户端心跳间隔参数，默认30s

   ```yaml
   eureka.instance.lease-renewal-interval-in-seconds=30
   ```

3. Ribbon缓存

   如果采用ribbon访问服务，ribbon默认是从eureka client中拿到数据缓存，缓存时间是30s

   ```yaml
   ribbon. ServerListRefreshInterval=30
   ```

4. 默认3个周期内没有收到心跳，T掉服务，一个周期30s

   ```yaml
   eureka.instance.lease-expiration-duration-in-seconds=90
   ```