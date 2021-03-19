#### 为什么Redis单线程还这么快？

- 纯内存操作
- 单线程省去了锁和线程上下文切换的消耗
- 核心基于非阻塞的IO多路复用



#### Redis和memcached区别

- memcached数据结构单一，操作相对简单。redis能支持多种复杂的数据结构和相对较多的操作
- redis支持原生集群，memcached不支持，只能客户端来实现往集群中写入数据
- redis为单核，memcached为多核，平均每核上redis存储小数据的时候要比memcached快，数据量大于100 k的时候，memcached速度要快



#### Redis的线程模式

redis内存使用了单线程的文件事件处理器，file event handler,所以redis是单线程的模型，采用IO多路复用机制同时监听多个socket，将产生事件的socket压入到 **内存** 队列中，事件分派根据socket上的事件类型选择对应的事件处理器。文件事件处理器的结构包含四个：

- 多个socket
- IO多路复用程序
- 文件事件分派器
- 事件处理器（连接应答处理器，命令请求处理器，命令回复处理器）



#### Redis IO多路复用

> 一个服务端进程可以同时处理多个套接字，多路指的是多个客户端，复用指的是单进程处理多个客户端的请求，解决了上下文切换的耗时操作多路复用 发展（函数）可分为select -> poll(轮询) -> epoll(投票) -> kqueue

select（轮询）：调用select函数后会处于阻塞状态，直到有描述符就绪（可读，可写，或者超时）。扫描全部监听的文件描述符，当select函数返回后可以通过遍历 fd_set 找到就绪的描述符，缺点是监控文件描述符有限，Linux平台最多是1024。

poll（轮询）：改变了文件描述符集合，从select的fd_set改成pollfd_t，使得支持文件描述符限制超过1024

epoll（解决了轮询和数量限制）：遍历一遍所有描述符，未完成任务的告知完成任务和执行什么操作，然后定期检查关键节点（真正发出了事件的流）

- Redis中的IO多路复用

  redis是单进程单线程模式，文件事件是对 **套接字操作的抽象** ，每当一个套接字准备好执行连接应答，写入，读取，关闭等操作时就会产生一个文件事件，因为redis服务器是可以连接多个套接字的，所以会同时存在多个文件事件。**IO多路复用程序就是负责监听多个套接字，向文件事件分派器传送产生了事件的套接字，文件事件分派器根据套接字的事件类型调用相应的文件处理器处理**（accept应答，read读，write写，close关闭）

![](https://sz-note-md.oss-cn-beijing.aliyuncs.com/imgredis文件事件处理器.png)





####  Redis数据类型

1. String，最简单的ky缓存，保存对象信息会增加序列化和反序列化的内存开销

   基本命令：

   get key

   set key value expire

2. Hashes，hash 散列表的形式存储，然后每次读写缓存，可以操作hash里某个字段，超时时间只能设置在 大 key 上，单个 filed 则不可以设置超时，保存对象信息的时候使用，还可以单独修改单个field

   基本命令：

   **hset** person name honva  # 写入person对象name属性

   **hmset** person age 18 sex man # 批量写入person对象的多个属性

   **hsetnx** person age 17 # 写入person对象age属性，如果存在返回0，不存在返回1

   **hget** person name       # 获取person对象name属性

   **hmget** person name age #批量获取person对象中的多个属性

   **hdel** person name       # 删除person对象的name属性

   **hexists** person name   # 判断person对象是否包含name属性

   **hgetall** person # 返回hash表person对象所有属性

   **hincrby** person age 2 # 给person对象的age属性增加指定数

   **hkeys** person #返回对象的所有key

3. Lists，一种比较灵活的链表数据结构，它可以充当队列或者栈的角色，可以从列表两端进行插入（lpush）和弹出（lpop），元素是有序的，可重复。使用场景：消息队列、文章列表或者数据分页展示

   基本命令：

   lpush,lpushx key value 1 value 2 value 3 # 插入头部,lpush当key不存在时插入，lpushx当key不存在时不插入

   lpop key # 从头部弹出数据

   rpush，rpushx # 从尾部写入数据

   rpop # 从尾部弹出数据

   rpoplpush key 1 key 2 # 移除key 1队尾的数据，然后插入到key 2的头部，原子操作

   lindex key 0 # 查看key的第0个元素

   llen key # 查看list为key的长度

   lrange key start stop # 查看列表指定范围内的元素

   lset key index value # 通过索引设置列表元素的值

4. Sets，无序不允许重复数据，支持多个集合做交集并集操作，
   基本命令：    

   sadd key member1 menber2 #添加指定key的多个value值

   scard key # 获取指定key的元素数量

   sismember key member # 确定给定的member是否在指定的key中

   smembers key #获取指定key的所有成员对象，阻塞

5. Sorted Set，成员唯一，但是分数可以相同，根据时间排序的热点新闻，试试最新数据
   基本命令：    
   zadd key score value # 插入数据

   zscore key value # 查看key对应value的分数

   zscard key # 查看key包含多少个value

   zrange key start end # 查看指定key，从开始位置到结束位置（从小到大）

   zrevrange key start end # 查看指定key，从开始位置到结束位置（从大到小）

   zincrby key score value # 指定的key自增或自减score

   zremrangebyrank key start stop # 按排名删除，从小到大

   zremrangebyscore key min max # 按分数删除

   zrangebyscore key min max limit offset count # 查询范围，并且分页

#### Redis淘汰机制

1. noeviction：默认策略，对写入请求直接拒绝
2. volatile-LRU:设置了过期时间的，leastest recently use，淘汰最近最少使用
3. volatile-TTL：设置了过期时间的，过期时间久的优先淘汰
4. volatile-Random：设置了过期时间的，随机淘汰
5. all-keys-LRU：没有设置过期时间的，淘汰最近最少使用的
6. all-keys-Random：没有设置过期时间的，随机淘汰

获取当前淘汰机制

```
config get maxmemory-policy
```

通过配置文件设置淘汰机制

```
maxmemory-policy allkeys-lru
```

通过命令修改淘汰机制

```
config set maxmemory-policy allkeys-lru
```



#### Sort Set数据结构，多维排序

数据结构是跳跃表实现的。通过自定义函数将多个排序因子转换成对应的result，将result作为sort set中的score。



#### Redis事务

- Redis事务本质就是一组命令集合，支持一次性多条命令，一个事物中所有命令都会被序列化，事务执行的过程中会按照顺序串行执行队列中的命令。其他客户端提交的命令不会插入到事务序列化命令中
- 没有隔离级别概念，在执行Excu命令前会被放到缓存中
- 不保证原子性，单条命令是原子性的，但是事务不保证原子性，执行失败后其余命令还是会执行，没有回滚

事务相关命令：watch key1，multi 事务开始，exec事务执行，discard取消事务，unwatch 取消对key的监视

![](https://sz-note-md.oss-cn-beijing.aliyuncs.com/imgredis事务执行命令.png)

#### Redis高可用方案

没有使用原来的一致性hashcode算法，取而代之的是用hash slots算法

##### 主从

数据复制多个副本保存在不同服务器上，连接在一起，并保证数据是同步的，即使有其中一台服务器宕机，其他服务器依然可以继续提供服务，实现Redis的高可用，同时实现数据冗余备份。主写从读,主从模式实现读写分离，从而实现高并发高可用

##### 哨兵模式

对主从结构中的每台服务器进行监控，当出现故障时通过投票机制选择新的master并将所有slave连接到新的master。当主master宕机，无需人为干预可以快速恢复正常使用

哨兵作用：

	-	监控：检测master，slaver服务是否存活，运行是否正常
	-	通知：当监控服务出现问题，向其他哨兵或者客户端发送通知
	-	故障自动转移：master出现宕机，会从slaver中选出新的master，并告知客户端新服务地址

哨兵也是一台redis服务器，只是不提供数据服务，通常哨兵配置数量是单数（为了选举），缺点在于无法动态扩充master节点

脑裂问题：哨兵仅支持一个master，当出现2个master的时候就被称为脑裂，为了防止脑裂的发生，同意升级为master节点必须是全部节点的n/2+1个节点都同意才能升级。



https://blog.csdn.net/ctwctw/article/details/105243302

##### 官方的cluster（集群）

去中心化，去中间件，每个节点都是平等的关系，保存各自的数据和整个集群的状态。每个节点都和其他所有节点连接，而且这些连接保持活跃，这样就保证了我们只需要连接集群中的任意一个节点，就可以获取到其他节点的数据。Redis 集群没有并使用传统的一致性哈希算法来分配数据，而是采用另外一种叫做**哈希槽** (hash slot)的方式来分配的。具体算法：

redis cluster默认有16384个槽位，当设置一个key的时候，会先对key做CRC16算法和16384取模得到所属的槽位，再将这个key分配到hash槽区间的节点上。

CRC16(key)%16384

redis-cluster的master一般用于读写。而slaver一般用于备份，和其对应的master有相同的slot集合

redis-cluster节点之间采用gossip（八卦）协议通信，不是把数据集中到某个节点，而是相互之间不断通信，保持整个集群所有节点的数据是完整的，优点：降低节点的压力，缺点：延迟性比较高

节点之间的通信端口=服务端口+10000，比如服务端口是8080，则通信端口就是18080

gossip协议包含信息：

- ping：每秒大概10次通信，会选择5个最久没通信的节点
- pong：返回ping和meet，包含自己的节点信息
- meet：新加入节点会收到其他master节点的meet信息，然后加入通信
- fail：失败后，会将次信息扩散

请求客户端重定向：如果计算后的slot不在本redis服务上，会给客户端返回MOVE信息，让客户端重定向到正确的服务器上

用hash tag手动指定slot位置，set key:{hash tag}, set agent:{100}



#### Redis集群如何选择数据库

集群没有办法选择，默认是0



#### Redis分布式锁

1. 单进程单线程模式

   采用队列模式将并发访问变成串行访问，多个客户端链接redis不存在竞争关系，使用 setnx 命令来判断是否获取锁

2. Redis 官方站提出了一种权威的基于 Redis 实现分布式锁的方式名叫 *Redlock*，此种方式比原先的单节点的方法更安全。

   - 安全特性：互斥访问，即永远只有一个 client 能拿到锁
   - 避免死锁：最终 client 都可能拿到锁，不会出现死锁的情况，即使原本锁住某资源的 client crash 了或者出现了网络分区
   - 容错性：只要大部分 Redis 节点存活就可以正常提供服务

https://www.cnblogs.com/jojop/p/14008824.html



#### Redis分布式锁超时问题

Redisson在对key加锁后会启用一个守护线程（watch dog）来为锁续租。当过期时间达到2/3的时候，会自动增长过期时间。根据当前线程的线程id作为依据给锁进行续租



#### Redis的hash一致性算法，一致性hash算法你了解吗？什么时候使用？解决什么问题？

问题：和普通hash算法一样都是使用取模，区别在于普通hash算法是对机器数量取模，当机器数量增、减都会导致这个缓存服务不可能引起缓存雪崩。

过程：一致性hash算法则是对 2^32  取模，使用 **IP或主机名** 进行hash算法得到hash值，再对 2^32 取模，从而定位服务节点的位置，将数据key使用相同的函数Hash计算出哈希值，并确定此数据在环上的位置，从此位置沿环顺时针“行走”，第一台遇到的服务器就是其应该定位到的服务器！

容错性：对于节点的增减都只需重定位环空间中的一小部分数据，具有较好的容错性和可扩展性。

数据倾斜：当节点较少的时候，会出现大部分数据集中在一个节点，另一个节点数量少的问题，简称数据倾斜，解决方案通过引入虚拟节点机制来解决。实现方案就是 每一个服务节点计算多个哈希，每个计算结果位置都放置一个此服务节点，通过名称做hash可以使用 node A#1 ，node A#2,node B#1,node B#2,通常将虚拟节点数设置为32甚至更大

参考文章：https://blog.csdn.net/Dream_Weave/article/details/105221103



#### Redis内部结构







#### Redis持久化有哪些，过程是什么，各自优缺点

##### RDB（Redis Database）

> 基于快照模式，固定的时间间隔内将数据集全量保存到磁盘，以二进制的形式写入，默认文件名为dump.rdb。RDB有三种触发机制，执行save命令，执行bgsave命令，在redis.config配置文件中制定自动化

- save命令：save命令会阻塞redis服务器，在执行期间，redis无法执行其他命令，知道整个RDB过程完成

- bgsave命令：不阻塞业务，一遍持久化一遍响应客户请求。执行期间，fork一个子线程，然后通过子线程处理所有的保存工作。

- redis.config配置：save 300 10，表示300秒内有10次修改操作进行备份，如果想关闭持久化可以使用 save "" ，还可以配置输出的文件名，文件路径，rdbcompression 默认yes，表示将快照文件进行压缩处理

  

  优点：合适容灾恢复；备份文件可以按照用户规定自动备份；不会影响到客户响应；恢复速度要比AOF快

  缺点：在备份期间发生故障，数据丢失；数据量大的时候，fork进程会很耗时，会影响到客户响应

##### AOF(append only-file)

>  AOF日志存储的是Redis服务器上指令序列，AOF只记录对内存进行修改（增删改）的指令记录。先执行指令再存储指令

aof有不同的触发方案，下面简述三种方案

	-	always：每次修改数据都会立即记录到磁盘文件，完整性好但是IO开销大，性能差
	-	everysec：每一秒记录一次到磁盘文件，性能提升，但是如果这一秒内宕机，数据会丢失
	-	no：默认配置，不适用AOF配置

启动方式：在redis.conf配置文件中将appendonly 改成yes，appendsync 改成对应的触发方案即可

AOF重写机制：优化指令，比如incre 1000，就会产生1000条指令，重写后就会变成一条；可以使用命令重写AOF文件（bgrewriteaof），也可以在配置中设置重写方案（no-appendfsync-on-rewrite yes开启重写机制，auto-aof-rewrite-percentage 100比上次文件增长100%就重写，auto-aof-rewrite-min-size 64mb文件超过64MB就重写）

	优点：持久化策略可以保证性能良好，服务宕机丢失数据也是1秒的数据；



服务重启后如何加载

![](https://sz-note-md.oss-cn-beijing.aliyuncs.com/imgredis服务启动加载顺序.png)




#### fork子进程如何做到一遍复制一遍不阻塞进程？

cow机制



#### Redis 6.0后增加了多线程

加入多线程的原因：充分利用多核CPU优势，分摊同步读写IO负载

默认关闭多线程，开启多线程后还需要配置线程数，官方建议4核配置3，8核配置6，不要超过核数，另外线程数超过8将没有意义

多线程开启后，只是针对处理网络数据的读写和协议解析，执行命令还是单线程执行，所以不存在线程安全问题

https://www.cnblogs.com/madashu/p/12832766.html



#### Redis多线程和Memcached的多线程对比有什么区别？





#### Redis 跳跃表 ？？？？



#### Bitmap原理，使用场景

https://www.cnblogs.com/54chensongxia/p/13794391.html



#### Redis实现订单超时30分钟取消付款、延迟队列

使用sort set数据结构，把时间当成score，用命令zrangebyscore min max limit offset count 命令把数据分页拿出来了做具体业务处理

https://blog.csdn.net/ThinkWon/article/details/103522351

#### redis实现异步队列

使用list数据结构，rpush，lpop，blpop（没有元素则阻塞）

#### Redis大批量插入数据

> 使用pipeline批量插入

1. 获取元数据，转换成set key value
2. 将命令转换成Redis protocol协议
3. cat data.txt | redis-cli --pipe
   https://www.cnblogs.com/ivictor/p/5446503.html

#### 假如Redis里面有1亿个key，其中有10w个key是以某个固定的已知的前缀开头的，如果将它们全部找出来？

- keys pattern

> 一次性返回所有匹配的key,所以会阻塞主进程

```
local-redis:0>keys t??
 1)  "two"
local-redis:0>keys t????
 1)  "three"
local-redis:0>keys t*
 1)  "two"
 2)  "three"
```

- scan cursor [MATCH pattern] [COUNT count]

> 当SCAN命令的游标参数（即cursor）被设置为 0 时， 服务器将开始一次新的迭代， 而当服务器向用户返回值为 0 的游标时， 表示迭代已结束。

```
dev-redis:0>scan 0 match *hsy* count 5
 1)  "32"
 2)    1)   "hsy:merchant:sendsms:billdetail:2020-06-17:7005100726"
  2)   "hsy:merchant:sendsms:billdetail:2020-06-17:8905106557"
  3)   "hsy:merchant:sendsms:billdetail:2020-06-17:9205105329"
  4)   "hsy:merchant:sendletter:billdetail:2020-06-17:9010014790"
  5)   "hsy:merchant:sendsms:billdetail:2020-06-17:6304108396"

```

https://www.cnblogs.com/williamjie/p/9502560.html



《Redis深度历险-核心原理与应用实践》