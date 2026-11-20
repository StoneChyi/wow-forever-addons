# 魔兽世界无限服插件

记录「无限服插件」项目实际制作或修改过的插件。玩家可按需安装，维护者可在 Git 历史中追踪每次提交。

| 插件 | 用途 | 下载与记录 |
| --- | --- | --- |
| **ForeverChatInput** | 单独移动聊天输入框，支持 EllesmereUI 解锁模式 | [下载独立 ZIP](https://github.com/StoneChyi/wow-forever-addons/releases/download/ForeverChatInput-v1.1.3/ForeverChatInput.zip) · [源码](addons/ForeverChatInput) |
| **ForeverShamanBuffFix** | 为无限服萨满恢复 EllesmereUI 冷却管理器里的强化风暴打击和乱舞追踪 | [下载独立 ZIP](https://github.com/StoneChyi/wow-forever-addons/releases/download/ForeverShamanBuffFix-v1.0.0/ForeverShamanBuffFix.zip) · [源码](addons/ForeverShamanBuffFix) |
| **WIM_EllesmereUI** | 为 WIM 私聊窗口添加 EllesmereUI 风格皮肤 | [下载独立 ZIP](https://github.com/StoneChyi/wow-forever-addons/releases/latest/download/WIM_EllesmereUI.zip) · [源码](addons/WIM_EllesmereUI) |
| **TotemTimers 20.13** | 修复图腾图标和实际左键施法不一致等问题 | [本项目修改记录](CHANGELOG.md#totemtimers-2013) · [作者原版](https://www.curseforge.com/wow/addons/totemtimers/files/9593963) |
| **StoneTotemTimers** | 本地独立版，增加同系排序和三个召唤组合的预览 | [本项目修改记录](CHANGELOG.md#stonetotemtimers) |

TotemTimers 上游保留全部权利。两个图腾插件的自定义改动在此存档，安装包的公开发布需要上游授权。 [上游项目与许可](https://www.curseforge.com/wow/addons/totemtimers)

## 安装 ForeverChatInput

下载 ZIP 并解压到魔兽目录的 `_forever_/Interface/AddOns/`。确认结构为 `AddOns/ForeverChatInput/ForeverChatInput.toc`，并在游戏插件列表启用 **ForeverChatInput**。

使用 EllesmereUI 时，脱战后输入 `/unlock` 进入「解锁模式」，拖动「聊天输入框」，然后点击「保存并退出」。之后按回车会在新位置打开输入框，聊天窗口留在原位。

也可以输入 `/fci` 打开独立预览，按住鼠标左键拖动后点击「保存」。点击「取消」或再次输入 `/fci` 可退出预览。两个入口共用同一份按角色保存的位置，输入 `/fci reset` 可恢复原位。

启用 EllesmereUIChat 时，移出的输入框跟随聊天外观。EllesmereUI 样式采用聊天背景和边框设置，WoW Forever 样式使用铜色边框，暴雪和经典样式沿用原输入框的装饰。文字沿用原输入框的字体设置。插件也支持无限服原生聊天。临时弹出的密语窗口沿用自己的布局。

移出的输入框默认隐藏右侧的「中／英」输入法按钮。键盘切换中英文的方式照旧。输入 `/fci ime show` 可恢复按钮，`/fci ime hide` 可再次隐藏。

开启 EllesmereUI 的「输入框在顶部」时，输入框移出后会释放聊天记录上方的预留空间。输入 `/fci reset` 恢复原位后，输入框重新按 EllesmereUI 的置顶设置显示。

## ForeverChatTab 已停止维护

RurutiaSuite 4.9.1 已在无限服提供 Tab 正向、Shift+Tab 反向切换发言频道及频道筛选。使用 `/rs` 打开「聊天条」，启用「Tab切换频道」，通过旁边的齿轮选择参与轮换的频道。

2026 年 11 月 20 日停用 ForeverChatTab。本地完整插件已备份，存档保留。旧补丁的输入框短名、自定义别名、短名悬停全名以及设置内的加入频道入口随停用而失效，相关设置尚未迁移到 RurutiaSuite。加入自定义频道可用游戏的 `/join 频道名`。游戏内实际切换仍待确认。

源码保存在 [归档目录](archive/ForeverChatTab)，历史安装包可在 [1.2.2 发行页](https://github.com/StoneChyi/wow-forever-addons/releases/tag/ForeverChatTab-v1.2.2) 查阅。

## 安装 ForeverShamanBuffFix

把 ZIP 解压到 `_forever_/Interface/AddOns/`。在角色插件列表启用 **无限服萨满增益修正** 和 **EllesmereUI Cooldown Manager**。进入萨满后，补丁会在启用的「冷却管理器 → CDM 条 → 增益」补回强化风暴打击 `1238931` 和乱舞 `16257`。已放在其他启用的 CDM 增益条上的自定义追踪会保留在原处。

两项会在实际触发时显示。换包如果清空插件目录，需把补丁目录一并装回。想手动删除这两项时，先停用补丁再重载界面。

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
