## 微信跳一跳辅助工具
已经配置好4.7的和5.5的iPhone基本不会掉下去，分数不能超过1000分不然会被清除

### 实现过程
1. 使用图片查找找到棋子位置
2. 从上往下去除背景色并且找到跟背景色不一样的点得到下一个位置
3. 根据设备微调计算距离得出按住时间
4. 使用[WebDriverAgent](https://github.com/facebook/WebDriverAgent)模拟点击

### 实测效果
![](https://github.com/zx1262111739/wxJumpTool/blob/master/bbb.jpeg)
