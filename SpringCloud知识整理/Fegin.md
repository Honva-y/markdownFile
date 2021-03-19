#### 开启Fegin注解

在application类中添加@EnableFeginClients

#### Fegin使用

接口中添加@FeginClient（value=""）,在value中指定服务名

#### 涉及到的内容

1. 参数绑定，@RequestParam,@RequestHeader,@ReuqestBody,传递对象的话对象要有默认构造函数

2. 继承性特性，服务提供者的controller需要实现api的接口，可以免去指定@RequestMapping,消费者端接口直接实现api接口，不用重写。好处免去冗余代码，缺点api接口类发生变化容易影响全局

3. Ribbon配置

   ```
   # 全局配置
   ribbon.ConnectTimeout=500
   ribbon.ReadTimeout=500
   
   # 单个服务配置
   #{serverName}.ribbon.ConnecTimeout=500
   #{serverName}.ribbon.ReadTimeout=500
   HELLO-SERVER.ribbon.MaxAutoRetries=1  //超时重试次数
   HELLO-SERVER.ribbon.MaxAutoRetriesNextServer=2 // 更换服务实例的次数
   ```

4. Hystrix配置

   ```
   # 全局配置
   hystrix.command.default.****
   ```

   针对某个服务关闭Hystrix

   ```
   @Configuration
   public class DisableHystrixConfiguration{
   	@Bean
   	@Scope("prototype")
   	public Fegin.Builder feginBuilder(){
   		return Feign.builder();
   	}
   }
   
   // 在对应的接口中
   @FeginClient(name="HELLO-SERVICE",configuration=DisableHystrixConfiguration.class){
   	...
   }
   ```

5. 指定方法配置，通过hsytrix.command.类名#方法名(参数类型).execution.isolation.thread.timeoutInMilliseconds=5000

6. 服务降级，使用fegin的hystrix的话无法像单个使用hystrix直接使用@HystrixCommand注解fallback参数指定降级的处理方法，但是可以重写api对应接口来指定

   ```
   @Component
   public class HelloServiceFallback imples HelloService{
   	@Overide
   	public String hello(){
   		return "error";
   	}
   	....
   }
   
   @FeginClient(name="HELLO-SERVICE",fallback=HelloServiceFallback.class){
   	...
   }
   ```

7. 请求压缩，默认使用请求压缩，类型是txt/xml,application/xml,application/json,大小是2048字节