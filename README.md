# tester #

##tester 是什么？
一个自动化工具，通过创建多个连接并运行测试框架，你可以轻松模拟项目运营真实环境。


##tester 有哪些功能？

* `压力测试`功能
    *  通过简单配置(基于lua)文件，便可以自由组合基于游戏功能的原子控件，创建出丰富的压测案例。

* `功能测试`功能
    *  通过创建案例入口，你可以自定义调用脚本接口，达到你想要的目地，比如破坏测试，模拟封包，etc.
    
## 注意事项

* 无论压测，功能测试，首先需要的是登录，不是吗？ 
* 所有的测试案例都在 ./bin/script/test_case 下面，添加案例文件到目录下就ok.
* 界面包含了登录服务器的基本信息，请指定需要测试的目标地址.
* 测试案例只是一份测试方式的配置，你可以开启多个相同名的测试案例，tester便会开启多个相同属性的测试案例, 你只需要，点击下开始按钮.

##有问题反馈
在使用中有任何问题，欢迎反馈给我，可以用以下联系方式跟我交流


##关于作者

```
    author: liuguirong
    email:hroomkeeper@gmail.com
    qq: 16839242
    web: oxrush.com
```
