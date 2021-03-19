#### 如何开启基于注解的自动装配

配置文件中引入 <context:annotation-config /> 或者直接注册 AutowiredAnnotationBeanPostProcessor类



#### 怎么开启注解装配，有哪些区别是什么？

@Autowired：默认按照类型装配（属于spring注解），默认情况下要求依赖对象必须存在，如果允许为null，需要把required属性设成false，如果想用名称装配，可以配合使用@Qualifier

```
@Autowired(required=false)
@Qualifier("baseDao")
private BaseDao baseDao
```

@Resource：可以按照类型装配，也可以按照name装配。默认按照name装配。但凡使用了name或者type找不到都会报错



#### Spring事务是如何传播的？





#### Spring事务不生效的情况

1. 本身mysql不是innodb类型，加了注解也不会生效

2. 类没有被spring管理，即类上没有添加@service注解

3. 事务的方法不是public的方法，如果非要在不是public方法上加注解，可以使用@AspectJ代理模式

4. 自身调用问题，调该类自己的方法，而没有经过 Spring 的代理类，默认只有在外部调用事务才会生效.解决的办法就是在类中注入自己，然后自己调自己的方法

   ```
   @Service
   public class OrderServiceImpl implements OrderService {
       public void update(Order order) {
           updateOrder(order);
       }
       @Transactional
       public void updateOrder(Order order) {
           // update order
       }
   }
   ```

   或者

```
@Service
public class OrderServiceImpl implements OrderService {
    @Transactional
    public void update(Order order) {
        updateOrder(order);
    }
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void updateOrder(Order order) {
        // update order
    }
}
```

5. 执行异常被捕获内部消化了，事务无法回滚

   ```
   @Service
   public class OrderServiceImpl implements OrderService {
       @Transactional
       public void updateOrder(Order order) {
           try {
               // update order
           } catch {
           }
       }
   }
   ```

6. 抛出的异常错误类型不正确

   ```
   @Service
   public class OrderServiceImpl implements OrderService {
       @Transactional
       public void updateOrder(Order order) {
           try {
               // update order
           } catch {
               throw new Exception("更新错误");
           }
       }
   }
   ```

   默认回滚的异常是RuntimeException，可以指定自己想抛出的异常

   ```
   @Transactional(rollbackFor = Exception.class)
   ```

   

#### @SpringBootApplication组合注解包含哪些注解

- @SpringBootConfiguration
- @EnableAutoConfiguration
- @ComponentScan

#### @SpringCloudApplication组合注解包含哪些注解

- @SpringBootApplication
- @EnableDiscoveryClient
- @EnableCircuitBreaker



#### Spring注册bean的过程

简单版：获取bean的完整定义，实例化bean，依赖注入，初始化，类型转换

详细版：doGetBean（）方法

<img src="https://sz-note-md.oss-cn-beijing.aliyuncs.com/imgSpring注册bean过程.jpg" style="zoom:60%;" />



#### Spring启动容器流程

https://www.cnblogs.com/summerday152/p/13639896.html

https://www.diguage.com/post/spring-startup-process-overview/

简单概要：

1. 创建容器，读取applicationContext.register(Config.class)指定配置
2. 准备BeanFactory(BF),注册容器本身和 BeanFactory 实例，以及注册环境配置信息等
3. 注册BeanDefinition对象，通过BeanDefinitionRegistryPostProcessor#postProcessorBeanDefinitionRegister()方法
4. 



#### 事务的传播机制

1. required:当前事务有就加入，没有就创建
2. not_support：不支持事务，如果当前有事务则挂机
3. required_new：新建一个事务并在这个事务中运行，如果当前存在事务就把事务挂起。新建的事务提交和回滚与挂起的事务无关，不影响挂起事务的操作
4. mandatory：强制当前方法使用事务运行，没有就抛出异常
5. never：当前不能存在事务，存在则报错
6. support：支持当前事务，如果当前事务没有也支持非事务运行
7. nested



####  SpringMVC处理过程

主要有四个组件

1. DispatcherServlet（前端控制器）
2. HandlerMapping（处理器映射器）
3. HandlerAdapter（处理器适配器）
4. ViewResolver（视图解析器）

![](https://sz-note-md.oss-cn-beijing.aliyuncs.com/imgSpringMVC请求过程.png)

https://www.cnblogs.com/wupeixuan/p/12362325.html



