## 微信跳一跳辅助工具
已经配置好4.7和5.5寸的iPhone 基本不会掉下去，但是不能超过1000分，超过分数会被清除

### 实现过程

通过图片查找棋子位置
从上往下去除背景色，找到下一个图形的顶点得出大概位置
根据设备微调计算距离得出时间 使用WebDriverAgent来模拟屏幕点击

![](https://github.com/zx1262111739/wxJumpTool/blob/master/bbb.jpeg)
