# Mouse Recorder

基于 AutoHotkey v2 的鼠标录制与回放工具。

## 功能

- 录制鼠标移动和点击
- 回放录制的操作（支持循环）
- 暂停/恢复回放
- 状态栏实时显示

## 快捷键

| 快捷键 | 功能 |
|--------|------|
| F9 | 开始/停止录制 |
| F10 | 开始回放 |
| F11 | 暂停/恢复回放 |
| F12 | 停止所有操作 |

## 使用方法

### 方法一：直接运行批处理文件
双击 `run_recorder.bat` 即可启动程序。

### 方法二：手动运行 AHK 脚本
需要先安装 [AutoHotkey v2](https://www.autohotkey.com/)，然后双击 `MouseRecorder.ahk`。

## 录制文件

录制的数据保存在 `mouse_record.txt` 中，格式为 CSV：
```
时间(ms), X坐标, Y坐标, 鼠标按键状态(0/1)
```

## 配置

在 `MouseRecorder.ahk` 中可修改以下参数：

- `PLAYBACK_SPEED` - 回放速度（1=原速，2=两倍速，0.5=半速）
- `SAMPLE_MS` - 录制采样间隔（毫秒）

## 系统要求

- Windows 10/11
- AutoHotkey v2（方法二运行时需要）
