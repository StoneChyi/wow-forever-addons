# 魔兽世界无限服插件

记录「无限服插件」项目实际制作或修改过的插件。玩家可按需安装，维护者可在 Git 历史中追踪每次提交。

| 插件 | 用途 | 下载与记录 |
| --- | --- | --- |
| **WIM_EllesmereUI** | 为 WIM 私聊窗口添加 EllesmereUI 风格皮肤 | [下载独立 ZIP](https://github.com/StoneChyi/wow-forever-addons/releases/latest/download/WIM_EllesmereUI.zip) · [源码](addons/WIM_EllesmereUI) |
| **TotemTimers 20.13** | 修复图腾图标和实际左键施法不一致等问题 | [本项目修改记录](CHANGELOG.md#totemtimers-2013) · [作者原版](https://www.curseforge.com/wow/addons/totemtimers/files/9593963) |
| **StoneTotemTimers** | 本地独立版，增加同系排序和三个召唤组合的预览 | [本项目修改记录](CHANGELOG.md#stonetotemtimers) |

TotemTimers 上游保留全部权利。两个图腾插件的自定义改动在此存档，安装包的公开发布需要上游授权。 [上游项目与许可](https://www.curseforge.com/wow/addons/totemtimers)

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
