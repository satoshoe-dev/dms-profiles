# Profiles：分步指南

[English](GUIDE.md) · [Deutsch](GUIDE.de.md) · [Español](GUIDE.es.md) · [Français](GUIDE.fr.md) · [Italiano](GUIDE.it.md) · [Português](GUIDE.pt.md) · [Русский](GUIDE.ru.md) · [日本語](GUIDE.ja.md) · **简体中文**

## 1. 安装并启用插件

从插件注册表安装：

```sh
dms plugins install dmsProfiles
```

也可以在 DMS 的 设置 → 插件 → 浏览 中找到它。或者将仓库克隆到 DMS 插件目录：

```sh
git clone https://github.com/satoshoe-dev/dms-profiles ~/.config/DankMaterialShell/plugins/DmsProfiles
```

打开 设置 → 插件，启用 Profiles。

![列出 Profiles 的插件列表](images/01-plugin-list.png)

## 2. 创建第一个配置

先把外壳调整成你喜欢的样子：主题、强调色、壁纸、状态栏、框架。然后在插件列表中展开 Profiles，输入名称并点击“创建”。

![创建配置](images/02-create.png)

新配置会立即生效。之后做的所有更改都会在几秒后保存到其中。

## 3. 再创建一个

更改外观，例如换一张壁纸和另一种强调色，然后用同样的方法创建第二个配置。现在更改会保存到第二个配置中，第一个保持原样。

## 4. 为选择器添加快捷键

在 niri 中，将以下内容添加到配置：

```kdl
binds {
    Mod+Shift+M { spawn "dms" "ipc" "call" "profiles" "toggle"; }
}
```

## 5. 切换

按下快捷键，用鼠标滚轮或方向键选择一个配置，然后按 Enter 或点击它。

![轮播视图的选择器](images/03-picker-carousel.png)

截取屏幕时画面会短暂定格。随后过渡动画切到新配置的壁纸，DMS 应用完配置后，状态栏、框架、窗口和部件淡入。如果配置没有自己的壁纸，过渡动画会改为显现已完成的桌面。

![正在进行的过渡](images/04-transition.png)

## 6. 选择选择器的外观

在“配置选择器”中选择视图（条带、自由、轮播或网格）以及预览的形状。

![选择器设置](images/05-picker-settings.png)

![六边形网格](images/06-picker-grid.png)

## 7. 选择过渡动画

在“过渡动画”中选择一种类型，或保持“随机”。选择随机时，点击你想允许的类型。“时长”决定动画持续多久，默认 1200 毫秒。“预览过渡动画”会在不切换的情况下播放一次动画，旧画面以灰色显示。

![过渡动画设置](images/07-transition-settings.png)

## 8. 管理配置

插件设置顶部的列表中有用于应用、重命名、上移或下移以及删除配置的按钮。当前配置旁边的撤销按钮可恢复它在启用时的状态。每个配置名称下方的文件夹行用于设置壁纸选择器（`dms ipc call profiles wallpapers`）打开的文件夹：点击选择，旁边的×清除。

![配置列表](images/08-list.png)

## 9. 在配置中保存插件设置（可选）

要按配置保存其他插件的设置，请在“随配置保存的插件”中输入该插件的 id，例如 `audioFx`。

## 10. DMS 以外的内容（可选）

在“高级”中，可以为 DMS 不管理的设置（例如终端颜色）设置保存命令和应用命令。命令会收到哪些内容以及示例，请参阅 README。
