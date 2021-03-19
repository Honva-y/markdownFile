#### Hashmap介绍

JDK 8中Hashmap由链表+数组+红黑树（时间复杂度为 O(logn)）数据结构 实现，默认初始容量是16，负载因子0.75，允许key、value为Null，属于线程不安全的集合，链表长度超过8会进行树化，当元素数量超过12时会自动扩容，扩容后的大小是扩容前的2倍。



#### 红黑树优缺点？为什么不用其他数据结构，比如AVL树

AVL树，和红黑树都是BBST，AVL是属于早先提出的结构，红黑树是在AVL基础上做出了些许改动。AVL是严格平衡树（要求每个节点的左右子树高度最多差1），因此在增删节点的时候会旋转的次数比红黑树要多。

红黑是用非严格的平衡来换取增删节点时候旋转次数的降低，任何不平衡都会在三次旋转之内解决



#### 红黑树的特点有什么？

1. 节点非黑即红
2. 节点是红的话，子节点一定是黑的（反之不一定）
3. 根节点到叶子节点的的路径上黑色节点数量相同
4. 叶子节点都是黑色



#### Java中哪里用到了红黑树

TreeMap,Hashmap



#### 树的旋转过程是怎么样的？（细节，不究）

旋转的目的是为了减少树高。AVL树种保存着一个旋转因子的参数，旋转分为了左旋和右旋



#### Hashmap如何定位下标

1. 先对存入的key进行hash运算，获取到一个32位整形的hash值
2. 第一步获取到的hash值再和其本身的高16位进行异或运算，得到较为平均的hash值
3. 第二步的hash值再和map的大小进行&运算，保证元素的分散性

![](https://sz-note-md.oss-cn-beijing.aliyuncs.com/imgmap获取下标过程.png)



#### 为什么要取hash值要和高区16位做异或运算？

因为在最后定位下标的时候会和数组的槽位做与运算，而数组的大小普遍不会超过8位（377个），所以在做与运算的时候会对高区特征忽略，产生hash碰撞的几率就会增加，散列性不是最佳的，所以在获取hash值的时候让其高位16位和低16位做异或运算，保留一定的高区特征。（1111=15（十进制），1111 1111=255（十进制），1111 1111 1111=4095（十进制），1111 1111 1111 1111 =65535（十进制））

#### 为什么槽位必须是2的倍数

1. 降低hash碰撞概率。（下标定位的代码中体现）比如数组槽位是17，那么n-1=16  二进制就是 1 0000，hash的值和1 0000做与运算就会产生更多的hash碰撞

![](https://sz-note-md.oss-cn-beijing.aliyuncs.com/imghashmap槽位是2的倍数原因.png)

2. 高效运算，提交效率（下标定位的代码中体现）。在扩容方法中，通过位运算 if ((p = tab[i = (n - 1) & hash]) == null) 来计算元素在新数组的位置，a % (2^n) 等价于 a & (2^n - 1) ，位运算的运算效率高于算术运算，原因是算术运算还是会被转化为位运算

   比如1010 1101（173）,槽位假设是16，那么173%16 等价于173&15，求出的值都是13



#### 为什么不一开始就是用红黑树，而是用链表

因为TreeNode节点的大小差不多是普通Node节点的2倍，所以一开始不宜直接使用红黑树存储。



#### Hashmap 什么时候会树化？

链表长度>8,且数组槽位超过64的时候。如果数组槽位不超过64，先扩容然后重hash复制数组



#### 为什么Hashmap是**链表长度**超过8，数组长度超过64会树化，为什么树的大小为6又转换成链表？

1. 概率问题
2. 防止用户自己实现不好的hash算法导致性能下降

源码中说大数据统计，hashmap存放链表数量大于8的概率是0.00000006(亿分之六)，概率很小很小，但是也会存在发生的可能，并且hashcode()的方法是可以被重写了，为了防止用户自己实现一些散列性不佳的hashcode()方法，从而导致查询效率下降，所以hashmap的树化操作是保底手段。

权衡时间和空间，TreeNode大小是普通Node大小的两倍



#### 转化的阈值8和6阈值为什么不一样

为了避免频繁来回转化



#### 为什么负载因子是0.75

负载因子起到的作用是控制hashmap的**数据密集度**，当负载因子越大，hash碰撞的几率就会更大，链表的长度就会越长，性能会有所下降。当负载因子越小，就会越容易触发扩容，数据密集度会下降，但是相对而言会比较浪费内存。官方经过多方面参考所以选择了0.75这个数



#### 两个键的hashcode相同，如何获取对象

获取对象的流程：先判断hashcode，hashcode相同则判断key值，key值相同则判断key对应的内容是否相同（当key为null的时候？）



#### hashMap重载了哪些方法，修改了什么？

- equals()方法，从原本判断两个对象的内存地址改为仅判断对象的内容。
- hashcode()方法，将存入对象的key和value做Object方法的hash再做  **^** 运算



#### Hashmap 什么时候进行扩容，扩容的过程是怎么样的

1. 初始化时
2. 当元素数量超过阈值时

先判断Hashmap内的元素数量是否是0，如果是则进行初始化操作，如果不是则创建一个新的数组是原来的2倍，然后对数据进行重新下表位置计算和复制（JDK 8不做重hash）



#### hashmap 在JDK 8、JDK7 优化

1. 引入红黑树
2. 扩容优化，JDK7扩容时对原数组重新进行了hash定位，而JDK 8中，扩容后复制元素少了一次重hash的方法，使用e.hash & oldCap,算出结果是0在原位置，如果是1则原位置+oldCap,因为定位下标的时候用的是e.hash & (length-1)也就是1111，而原来的是0001 0000
3. 解决resize时多线程死循环问题，JDK7中，链表中的数据是尾插（链表元素会倒置），在扩容时采用的是头插法，在并发情况下如果两个相邻的接口扩容后仍然是相邻的，那就有可能导致两个节点相互指向导致死循环
4. 节点类型，JDK 7 中使用Entity，JDK 8 中使用Node节点
5. 插入顺序，JDK 7 先判断是否扩容再插入，JDK 8 中先插入再判断是否扩容.



#### Node，TreeNode节点存放了什么数据？

Node : int hash, K key,V value,Node node

TreeNode : TreeNode<K,V> parent,left,right,prev;  Boolean red;



#### Hashmap的put操作过程

1. 判断数组是否为空，为空进行初始化扩容
2. 根据key的最终hash值和数组槽位做与运算获取下标
3. 判断index是否存在，不存在插入，存在则判断key内容是否一样，一样覆盖旧值
4. 如果不一样，判断是否是树结构，是的话插入树节点
5. 如果不是树结构，创建普通节点，判断链表长度是否大于8且数组大于64，(<64，先扩容，不树化),树化 后插入数据
6. 插入完成后判断当前数组数量是否大于阈值，如果是则进行扩容

获取hash与数组槽位做&运算，定位下标，有的话就取出，没有的话用equals比较链表或者树的key值



#### Hash冲突解决办法（细节）

1. 链表法（Separate chaining）
2. 开放寻址法（Open addressing,线性探索，二次探索，伪随机探索）
3. 重hash法



#### HashMap，LinkedHashMap，TreeMap 有什么区别？

- LinkedHashMap 保存了记录的插入顺序，在用 Iterator 遍历时，先取到的记录肯定是先插入的
- TreeMap 实现 SortMap 接口，能够把它保存的记录根据键排序（默认按键值升序排序，也可以指定排序的比较器）



#### Hashmap、LinkedHashMap 、TreeMap区别，使用场景？

hashmap适用于插入，查找的场景，TreeMap则适用于需要对元素的key进行有序遍历的场景

LinkedHashMap ：适合对取数据按添加顺序加入的业务场景



#### 解决Hashmap线程不安全的代替方案有哪些？

1. Hashtable，直接在方法上加synchronize关键之，锁力度大，高并发差
2. Collections.synchronizedMap(),使用Collections工具类的静态方法，将map作为参数传入，方法内通过对象锁实现
3. ConcurrentHashMap,JDK 7 中使用的是分段锁，降低锁力度，加大并发度,JDK 8中使用CAS(compare and swap 无锁机制)+synchronize的方法实现线程安全



#### ConcurrentHashMap

JDK 7 使用Segment+分段锁实现线程安全，构造函数中有3个参数，初始化大小，加载因子，并发等级。默认情况下，initialCapacity等于16，loadFactor等于0.75，concurrencyLevel等于16。

JDK 8 中因为引入红黑树，所以将分段锁技术改成CAS+synchronize实现，免除了最大并发数的限制

JDK 7 :Reentrantlock+HashEntity+Segment

JDK 8 :synchronize+CAS+Node



#### ConcurrentHashMap 、Hashmap区别

1. Node节点，ConcurrentHashMap的Node类中value和Node<K,V>添加了volatile关键字，保证线程之间可见
2. 添加Null元素不同，ConcurrentHashmap不允许key或者value为null，而HashMap可以
3. 元素下标确认，ConcurrentHashmap使用（length-1) & (h ^ (h >>> 16)) & HASH_BITS);，hashmap确定下标（length-1) & (h ^ (h >>> 16))



#### ConcurrentHashMap中查找元素、替换元素和赋值元素都是基于`sun.misc.Unsafe`中**原子操作**实现**多并发的无锁化**操作



#### ConcurrentHashMap get（）方法需要 加锁吗？为什么

不需要，get方法采用unsafe方法保证线程安全



#### 并发包主要有哪些类型？

并发包路径：java.util.concurrent，里面的类都是线程安全的，主要包含

- Blocking：基于锁，并提供阻塞方法
- CopyOnWrite：容器类，修改开销大，
- Concurrent：内部类大部分使用CAS优化保证线程安全，保证吞吐量高。
  - 弱一致性
    - 遍历弱一致性：迭代器遍历发生时，容器发生修改，迭代器不会报错，遍历的是旧值
    - 求大小弱一致性：调用size方法，可能不准确
    - 读取弱一致性：获取到的值可能不是最新的



#### ConcurrentHashmap，HashTable为什么key/value都不能为空？

高并发情况下，无法确认是value为null还是不存在这个元素。HashMap中可以调用containsKey(key)方法来确定是null还是不存在，但是在并发集合中，如果调用containsKey和get方法判断，元素可能发生了改变获取的还是旧值，提高了并发风险



#### ConcurrentHashmap的put方法过程是怎么样的？（细节）

1. 判断key，value是否为null，如果为null抛出异常。获取key对应的hash值，和HashMap不同，高低16位异或运算后再与上一个hash字段编码 **HASH_BITS**
2. table为null或者0，则初始化table，调用initTable()方法（第一次put调用默认参数实现，重要的参数sizeCtl，判断是否有线程正在初始化）
3. 如果已经初始化过，判断槽位是否存在hash冲突，不存在调用casTabAt的CAS操作进行插入
4. 存在hash冲突，并且节点的 f.hash==MOVE==-1  表示正在扩容，则调用helpTransfer()方法帮助扩容
5. 若存在hash冲突，且没有在扩容，使用synchronize关键字对节点加锁，统计链表长度bitCount，遍历链表判断key是否存在，存在就替换旧值并返回旧值，不存在就直接将节点加入到链表末尾
6. 如果节点类型是TreeNode，则将节点加到红黑树中，然后退出加锁模块
7. 检查bitCount大小，如果大于等于8，则对链表进行树化
8. 最后调用addCount方法，统计数量和判断是否需要进行扩容



#### ConcurrentHashmap的put方法如何保证线程安全？

1. 第一次调用put方法，调用initTable（）方法，初始化数组，使用int volatile sizeCtl来判断当前map是都有其他线程在初始化，-1表示正在初始化，如果sizeCtl<0，则放弃初始化操作
2. 初始化成功后将当前容量赋值给sizeCtl
3. 当不存在冲突时，利用casTabAt方法的CAS操作将元素加入到map中
4. 如果存在冲突，先把当前节点使用关键字synchronize加锁，然后使用tabAt（）方法的原子操作判断有没有其他线程对数组修改，然后再做操作



#### ConcurrentHashmap扩容

扩容主要通过transfer()方法，当正在进行扩容时，有其他线程进行put操作，会通过调用helpTransfer()方法来帮助扩容。过程大概就是先计算出每个线程需要处理的桶数，数量/8/CPU核心数，如果结果小于16 那就默认是16