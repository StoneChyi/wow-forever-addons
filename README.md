# 魔兽世界无限服插件

记录「无限服插件」项目实际制作或修改过的插件。玩家可按需安装，维护者可在 Git 历史中追踪每次提交。

| 插件 | 用途 | 下载与记录 |
| --- | --- | --- |
| **ForeverChatInput** | 单独移动聊天输入框，支持 EllesmereUI 解锁模式 | [下载独立 ZIP](https://github.com/StoneChyi/wow-forever-addons/releases/download/ForeverChatInput-v1.1.1/ForeverChatInput.zip) · [源码](addons/ForeverChatInput) |
| **ForeverChatTab** | 聊天输入时用 Tab 和 Shift+Tab 轮换自选发言频道 | [下载独立 ZIP](https://github.com/StoneChyi/wow-forever-addons/releases/download/ForeverChatTab-v1.2.1/ForeverChatTab.zip) · [源码](addons/ForeverChatTab) |
| **WIM_EllesmereUI** | 为 WIM 私聊窗口添加 EllesmereUI 风格皮肤 | [下载独立 ZIP](https://github.com/StoneChyi/wow-forever-addons/releases/latest/download/WIM_EllesmereUI.zip) · [源码](addons/WIM_EllesmereUI) |
| **TotemTimers 20.13** | 修复图腾图标和实际左键施法不一致等问题 | [本项目修改记录](CHANGELOG.md#totemtimers-2013) · [作者原版](https://www.curseforge.com/wow/addons/totemtimers/files/9593963) |
| **StoneTotemTimers** | 本地独立版，增加同系排序和三个召唤组合的预览 | [本项目修改记录](CHANGELOG.md#stonetotemtimers) |

TotemTimers 上游保留全部权利。两个图腾插件的自定义改动在此存档，安装包的公开发布需要上游授权。 [上游项目与许可](https://www.curseforge.com/wow/addons/totemtimers)

## 安装 ForeverChatInput

下载 ZIP 并解压到魔兽目录的 `_forever_/Interface/AddOns/`。确认结构为 `AddOns/ForeverChatInput/ForeverChatInput.toc`，并在游戏插件列表启用 **ForeverChatInput**。

使用 EllesmereUI 时，脱战后输入 `/unlock` 进入「解锁模式」，拖动「聊天输入框」，然后点击「保存并退出」。之后按回车会在新位置打开输入框，聊天窗口留在原位。

也可以输入 `/fci` 打开独立预览，按住鼠标左键拖动后点击「保存」。点击「取消」或再次输入 `/fci` 可退出预览。两个入口共用同一份按角色保存的位置，输入 `/fci reset` 可恢复原位。

启用 EllesmereUIChat 时，移出的输入框跟随聊天外观。EllesmereUI 样式采用聊天背景和边框设置，WoW Forever 样式使用铜色边框，暴雪和经典样式沿用原输入框的装饰。文字沿用原输入框的字体设置。插件也支持无限服原生聊天，可与 ForeverChatTab 一起使用。临时弹出的密语窗口沿用自己的布局。

移出的输入框默认隐藏右侧的「中／英」输入法按钮。键盘切换中英文的方式照旧。输入 `/fci ime show` 可恢复按钮，`/fci ime hide` 可再次隐藏。

## 安装 ForeverChatTab

下载 ZIP 并解压到魔兽目录的 `_forever_/Interface/AddOns/`。确认结构为 `AddOns/ForeverChatTab/ForeverChatTab.toc`，并在游戏插件列表启用 **ForeverChatTab**。打开聊天输入框后按 **Tab** 正向切换发言频道，按 **Shift+Tab** 反向切换。可以与 RurutiaSuite 一起使用。

输入 `/fct` 或打开「设置 → 插件 → ForeverChatTab」。可分别勾选说话、小队、团队、副本和公会频道，轮换时自动跳过当前不可用的频道。已加入的编号频道默认自动纳入，可逐项取消，或关闭自动纳入后手动勾选。要加入自定义频道，在设置里输入频道名并点击「加入频道」。

用 Tab 或 Shift+Tab 切到编号频道后，聊天输入框保留频道编号并显示短名，鼠标悬停可查看全名。打开 `/fct`，点频道右侧的「短名」可输入最多 16 个字符，也可用「恢复自动」清除自定义短名。

密语、社区频道和斜杠命令使用客户端原有的 Tab 行为。输入 `/fct off` 暂停，`/fct on` 恢复。

## 安装 WIM_EllesmereUI

1. 安装适用于无限服的 [WIM](https://www.curseforge.com/wow/addons/wim-3) 和 [EllesmereUI](https://www.curseforge.com/wow/addons/ellesmereui)。
2. 下载上表的 ZIP，解压到魔兽目录的 `_forever_/Interface/AddOns/`。确认结构为 `AddOns/WIM_EllesmereUI/WIM_EllesmereUI.toc`。
3. 进入游戏并启用三个插件。输入 `/wim`，在「外观 → 消息窗口 → 窗口皮肤」选择 **EllesmereUI**。恢复原皮肤时可以选回 **WIM Modern**。

离线核对环境为无限服 1.60.1（接口版本 16001）、WIM 3.19.6 和 EllesmereUI 9.8.4。游戏内验收状态见 [已知问题与后续计划](docs/maintenance.md)。

## 维护

- [修改记录](CHANGELOG.md)包含版本、行为变化和验证记录。
- [已知问题与后续计划](docs/maintenance.md)包含玩家反馈、待验证场景和拟议改动。
- [Issues](https://github.com/StoneChyi/wow-forever-addons/issues)可提交反馈。请附上插件和依赖版本、客户端版本、复现步骤和预期行为。贴截图或报错前请遮住角色名与私聊内容。
- 本地运行 `python scripts/build_release.py`，从当前 Git 提交生成 `dist/` 下的独立安装 ZIP。发布时在 [Releases](https://github.com/StoneChyi/wow-forever-addons/releases) 上传对应的 ZIP，并注明适用的游戏与插件版本。
