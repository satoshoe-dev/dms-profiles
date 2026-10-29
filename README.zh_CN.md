# Profiles

[English](README.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Français](README.fr.md) · [Italiano](README.it.md) · [Português](README.pt.md) · [Русский](README.ru.md) · [日本語](README.ja.md) · **简体中文**

一个 [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) 插件，可以把 shell 的外观以一个名称保存下来，并在这些外观之间切换。一个配置包含主题和强调色、浅色或深色模式、壁纸、状态栏、框架、透明度、字体、动画，以及桌面部件和它们的位置。

![Profiles](assets/screenshot.png)

带图片的分步说明：[安装与设置指南](docs/GUIDE.zh_CN.md)。

## 切换

用快捷键打开配置选择器，然后选择一个配置。截取屏幕时，画面会短暂定格（约 0.2 秒）。随后过渡动画立即从旧画面过渡到新配置的壁纸。与此同时 DMS 应用配置，完成后状态栏、框架、窗口和部件会在新壁纸上淡入。你不会看到 shell 一块一块地重建。

没有自己壁纸的配置使用以前的流程：截取的画面一直保留到配置应用完毕，然后过渡动画显现出已完成的桌面。过渡动画的时长可以在设置中调整（默认 1.2 秒）。

共有 29 种过渡动画可选，包括淡入淡出、擦除、圆形、开门、百叶窗、融化、碎裂、显像管关闭、雪花屏和五种黑客效果。随机模式可以只在你喜欢的那些里挑选。大多数动画的边缘会以新配置的强调色发光。

## 配置选择器

选择器有四种视图：面板上的条带、不带面板的同一条带、当前配置大幅显示在中间的轮播，以及铺满屏幕的网格。预览可以是纵向、横向、正方形、圆形、六边形或菱形。在网格中，六边形和菱形以蜂窝状排列，间距与窗口相同。轮廓、发光、勾选标记和圆角半径都可以关闭或调整。

鼠标滚轮和方向键移动选择，Enter 或点击应用，Escape 关闭选择器。

## 保存

在 DMS 设置中所做的更改会在几秒后保存到当前配置。每个配置都会记住启用时的样子，因此可以在设置页面撤销更改。壁纸会复制到配置中，移动或删除原始文件不会影响它。只要原始文件还存在，切换时就会显示原文件而不是副本，这样壁纸仍留在自己的文件夹里（DMS 的壁纸轮换和其他插件能看到整个文件夹）。文件消失后才使用副本。可在设置中通过“使用原始壁纸文件”关闭。

## 壁纸选择器

`dms ipc call profiles wallpapers` 会用壁纸文件夹中的图片打开同一个选择器。按 Enter 或点击即可设置，自动保存会把它存入当前配置。它使用你为配置选择的选择器视图和形状。

默认是当前壁纸所在的文件夹。配置也可以有自己的壁纸文件夹，这样选择器总是在那里打开，即使当前图片来自别处：点击设置中配置名称下方的文件夹行来设置（点击×清除），或用 `dms ipc call profiles folder <slug> /path/to/pictures`（路径为空则清除）。它以 `wallpaperFolder` 保存在该配置的 `profile.json` 中。

配置保存在 `~/.config/DankMaterialShell/profiles/`，每个配置一个文件夹。

## 其他插件的设置

插件设置也可以成为配置的一部分。在“设置 → 插件 → Profiles → 随配置保存的插件”中填入插件 ID，例如 `audioFx`。

## DMS 之外的内容

DMS 不管理的终端颜色、浏览器主题或合成器规则，可以用两个可选命令来处理：

- 保存命令在保存配置时运行。它输出的 JSON 会作为 `extras` 存入配置。
- 应用命令在切换过程中运行，时间点是新设置刚写入之后。命令结束后新桌面才会显示。它会收到 `DMS_PROFILE_DIR`、`DMS_PROFILE_SLUG`、`DMS_PROFILE_NAME` 和 `DMS_PROFILE_NEW_COLORS`（正在生成新颜色时为 1）。配置文件是 `$DMS_PROFILE_DIR/profile.json`。

一个按配置保存 GTK 界面字体的小例子：

```sh
# save command
printf '{"font": "%s"}' "$(gsettings get org.gnome.desktop.interface font-name | tr -d "'")"

# apply command
gsettings set org.gnome.desktop.interface font-name \
  "$(python3 -c 'import json,os; print(json.load(open(os.environ["DMS_PROFILE_DIR"] + "/profile.json"))["extras"]["font"])')"
```

## 要求

DankMaterialShell 1.6.1 或更新版本。过渡动画截取屏幕时，如果安装了 `grim` 就用它，否则用 DMS 自带的 `dms screenshot`。我在 niri 上使用这个插件。窗口间距、圆角半径和边框宽度由 DMS 自己写入合成器配置，所以在 DMS 支持的其他合成器上，它们也应该会跟随配置变化。

## 安装

从插件注册表安装：

```sh
dms plugins install dmsProfiles
dms ipc call plugins enable dmsProfiles
```

也可以在 DMS 的 设置 → 插件 → 浏览 中找到它。若要从仓库安装：

```sh
git clone https://github.com/satoshoe-dev/dms-profiles ~/.config/DankMaterialShell/plugins/DmsProfiles
dms ipc call plugins enable dmsProfiles
```

然后添加一个快捷键，例如在 niri 中：

```kdl
Mod+Shift+M { spawn "dms" "ipc" "call" "profiles" "toggle"; }
```

## IPC

```sh
dms ipc call profiles toggle
dms ipc call profiles wallpapers
dms ipc call profiles folder <slug> <path>
dms ipc call profiles list
dms ipc call profiles apply <slug>
dms ipc call profiles create <name>
dms ipc call profiles save
dms ipc call profiles rename <slug> <new name>
dms ipc call profiles remove <slug>
dms ipc call profiles move <slug> left|right|<position>
dms ipc call profiles reset <slug>
dms ipc call profiles previewTransition <type>
dms ipc call profiles status
```

## 翻译

插件提供德语、西班牙语、法语、意大利语、葡萄牙语、俄语、日语和简体中文版本，并跟随 DMS 中设置的语言。如果发现翻译不对，欢迎提交 pull request。

## 说明

这个插件是我在 Claude (Anthropic) 的帮助下写的，我每天都在自己的桌面上使用它。

## 许可证

[MIT](LICENSE)
