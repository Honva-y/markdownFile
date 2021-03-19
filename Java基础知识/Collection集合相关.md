### Collection集合

Collection定义了单列集合所有共性的方法，集合只能存放对象，而不能存储基本的数据类型，架构图如下

![](https://sz-note-md.oss-cn-beijing.aliyuncs.com/img常用Collection框架图.png)

#### List接口特点

1. 有序集合（存储和取出元素顺序相同）
2. 允许重复元素，可以存入多个null
3. 有索引，可以通过for循坏遍历

#### Set接口特点

1. 不允许重复元素，只能存入一个null，保证元素唯一性
2. 没有索引
3. 无序集合（存储和取出的元素顺序可能会不同），LinkedHashSet除外，维持它自己的内部排序，所以随机访问没有任何意义。

#### Collection集合的基本方法

add,remove,size,isEmpty,contains,toArray



####  ArrayList和 LinkedList和Vector的区别（扩展）

共同点：都实现了List接口

ArrayList  ： 是一个可变大小的数组，初始值容量10,不能保证线程安全,（Hashmap初始大小16，size>8，会树化）,扩容每次为oldCap+oldCap*0.5,也就是1.5倍

LinkedList ：双向连表，添加和删除方面性能较ArrayList好，get性能比较差

Vector :和ArrayList一样一个可变大小的数组，区别在于vector是线程安全的，因此在添加上效率性能也较低，加锁方式是在方法层面上做的

Collections.SynchronizedList，collections类静态内部类中的方法，将list转换成线程安全的list，也是方法级别加入同步锁，效率也不高

CopyOnWriteArrayList，写操作加锁，读时不加锁，提高了效率，**同步锁使用reentrantlock而不是synchronize**（扩展：CpoyOnWriteSet）



#### HashSet、TreeSet、LinkedHashSet区别

HashSet：底层由Hashmap实现，所以不会出现重复元素，但是可以添加null，添加删除操作时间复杂度都是O（1）

TreeSet：底层由TreeMap红黑树实现，实现了SortSet接口，根据key排序，添加删除操作时间复杂度都是O（1）

LinkedHashSet：底层由双向链表实现



#### Arrays和Collections是什么

Arrays是数组工具类，Collections是集合工具类，两个工具类的方法都是静态方法，不需要创建对象，使用类名调用即可

集合和数组之间相互转换，Arrays.asList，.toArray（）

#### 集合删除

因为List底层是数组，删除元素会改变原数组的下表，所以需要使用iterator.next()判断元素是否存在，然后再iterator.remove()方法删除



### Map接口

![](https://sz-note-md.oss-cn-beijing.aliyuncs.com/imgmap框架图.png)



##### 线程安全集合可以分为三类

- 遗留的线程安全集合：hashtable，vecotor，每个方法都加上了synchronize关键字
- 使用Collections工具类的装饰线程安全集合，方法内加上synchronize（）对象锁
  - synchronizedCollection
  - synchronizedList
  - synchronizedSet
  - synchronizedMap
- java.util.concurrent并发包下的类,比如
  - CopyOnWriteArrayList
  - CopyOnWriteArraySet
  - ConcurrentHashMap



#### 集合基本方法区别

add(),remove():无法加入会抛出异常 ，IllegalStateException，NoSuchElementException

push(),take():会等待队列直到可以加入

offer(),poll():返回false,返回null