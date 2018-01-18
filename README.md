## 微信跳一跳辅助工具
已经配置好4.7的和5.5的iPhone基本不会掉下去，分数不能超过1000分不然会被清除

### 实现过程
1. 使用图片查找找到棋子位置
2. 从上往下去除背景色并且找到跟背景色不一样的点得到下一个位置
3. 根据设备微调计算距离得出按住时间
4. 使用[WebDriverAgent](https://github.com/facebook/WebDriverAgent)模拟点击

### 使用方法
1. 首先要配置好[WebDriverAgent](https://github.com/facebook/WebDriverAgent) Demo里面使用了USB接口可以根据需要在 wxJumpTool.swift 里面修改 `let baseUrl = "http://127.0.0.1:8100/"`
2. wxJumpToolConsole 运行在控制台，wxJumpToolGraph 运行在模拟器比前面那个稳定
3. 设置棋子图片用于查找，4.7屏幕使用 chessImage_750.png 的图片，5.5屏幕使用 chessImage_1242.png 的图片，设置方法查看Demo
4. 都准备好之后直接运行就可以了
5. 如果掉下来了可以输出图片使用 wxJumpToolGraph 工程进行调试修改参数，图片输出请查看 wxJumpTool.swift:143，调试请查看 `func parseGameImageData(imageData:Data, debug:Bool )`方法

### 实测效果
![](https://github.com/zx1262111739/wxJumpTool/blob/master/bbb.jpeg)
