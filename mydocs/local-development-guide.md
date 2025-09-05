# 如何运行本地修改后的源代码

当您直接通过 `npx` 或 `homebrew` 安装 `elc` 时，您使用的是已发布的 npm 包。这意味着您对本地源代码的任何修改都不会在运行全局 `elc` 命令时生效。

要运行您本地修改过的代码，请遵循以下步骤。

## 步骤 1: 安装依赖

首先，您需要在项目根目录 (`/Users/zhewu/other/easy-llm-cli`) 安装所有必需的开发依赖包。

在终端中运行以下命令：

```bash
npm install
```

此命令会读取 `package.json` 文件，并下载 `devDependencies` 和 `dependencies` 中列出的所有库。您只需要在初次设置或依赖项更新后运行此命令。

## 步骤 2: 运行您修改后的代码

安装依赖后，您可以通过以下任一方法来运行本地代码。

### 方法 A: 使用开发启动脚本 (推荐)

这是最简单直接的方法，专为开发流程设计，它会自动处理编译和执行。

在终端中运行：

```bash
npm run start
```

此命令会执行 `package.json` 中定义的 `"start": "node scripts/start.js"` 脚本。

如果您需要向 `elc` 命令传递参数（例如 `--help`），请在 `npm run start` 后面加上 `--`，然后再跟上您的参数。

**示例:**

```bash
# 相当于运行 "elc --help"
npm run start -- --help

# 相当于运行 "elc '你的提示词'"
npm run start -- "你的提示词"
```

### 方法 B: 手动构建并运行

如果您想模拟最终发布包的构建和执行过程，可以按以下步骤操作：

1.  **构建项目**:
    运行以下命令来编译和打包所有代码：

    ```bash
    npm run bundle
    ```

    此命令会执行一系列脚本，并在 `bundle/` 目录下生成 `gemini.js` 文件。根据 `package.json` 中 `"bin"` 字段的定义，这个文件就是 `elc` 命令的入口点。

2.  **执行构建产物**:
    构建成功后，通过 Node.js 直接运行该文件：
    ```bash
    node bundle/gemini.js
    ```
    同样，您可以在命令后附加参数：
    ```bash
    node bundle/gemini.js --help
    ```

## 总结

为了方便开发，**强烈推荐您使用方法 A (`npm run start`)**。

**简而言之，您只需要执行以下两个核心命令：**

1.  `npm install` (仅在初次配置或依赖更新时需要)
2.  `npm run start -- [您想传递给elc的参数]`

---

## 最新功能更新：解决方案实施完成

为了解决自定义 LLM 的超时问题并提升整体稳定性，我们完成了一系列实施。

**该解决方案包括:**

1.  **增强的自定义 LLM 实现**: 添加了对 `CUSTOM_LLM_TIMEOUT` 环境变量的支持，并设置了 30 秒的默认超时时间。
2.  **改进的错误处理**: 添加了对超时和空响应的优雅处理，并提供用户友好的错误消息。
3.  **API 验证**: 实现了 `validateApi()` 方法，用于测试 API 连接性和模型兼容性。
4.  **诊断工具**: 创建了全面的 `diagnose-api.sh` 脚本用于故障排查。
5.  **配置文档**: 更新了配置示例和故障排查指南。

**关键技术改进:**

- **超时控制**: `CUSTOM_LLM_TIMEOUT` 环境变量允许用户自定义请求超时。
- **稳健的错误处理**: 系统现在可以优雅地处理超时和空响应场景。
- **增强的诊断功能**: 新的诊断工具可帮助用户快速识别和解决配置问题。
- **向后兼容性**: 所有变更都保持了现有功能的兼容性。

## 该实施工作已完成，可以进行测试。它解决了超时问题，同时为用户提供了更好的错误处理和诊断能力。

## 在全局版和开发版之间切换

在开发过程中，您可能希望快速地在通过 Homebrew 安装的全局稳定版 `elc` 和您本地的开发版 `elc` 之间切换。使用 Shell 函数是实现这一点的最佳方式。

此方案将向您的 Shell 配置文件（例如 `~/.zshrc`）中添加两个命令：`use-elc-dev` 和 `use-elc-global`。

### 步骤 1: 配置 Shell 环境

1.  打开您的 Shell 配置文件。如果您使用 Zsh（macOS 默认），该文件是 `~/.zshrc`。

    ```bash
    open ~/.zshrc
    ```

2.  将以下代码复制并粘贴到文件末尾：

    ```bash
    # easy-llm-cli 开发环境切换函数

    # 定义项目源代码的路径
    EASY_LLM_CLI_PROJECT_PATH="/Users/zhewu/other/easy-llm-cli"

    # 切换到使用本地源代码版本的 elc
    function use-elc-dev() {
      if [ -d "$EASY_LLM_CLI_PROJECT_PATH" ]; then
        # 创建一个别名 elc，使其在项目目录中运行 npm run start
        # -- 用于将后续参数正确传递给 npm 脚本
        alias elc="cd '$EASY_LLM_CLI_PROJECT_PATH' && npm run start --"
        echo "✅ 已切换到本地开发版 elc。"
        echo "   现在运行 'elc' 将会使用 '$EASY_LLM_CLI_PROJECT_PATH' 下的源代码。"
      else
        echo "❌ 错误：项目路径 '$EASY_LLM_CLI_PROJECT_PATH' 不存在。"
      fi
    }

    # 切换回全局安装的 elc
    function use-elc-global() {
      # 取消别名
      unalias elc &>/dev/null
      echo "✅ 已切换到 Homebrew 全局版 elc。"
      echo "   现在运行 'elc' 将会使用 '/opt/homebrew/bin/elc'。"
    }

    # (可选) 默认使用全局版本，确保新终端启动时是全局版
    use-elc-global
    ```

### 步骤 2: 应用配置

保存配置文件后，运行以下命令以使更改立即生效（或简单地打开一个新的终端窗口）：

```bash
source ~/.zshrc
```

### 如何使用

现在，您可以在任何终端窗口中使用这两个新命令了：

- **要使用本地源代码进行开发时：**

  ```bash
  use-elc-dev
  ```

  运行此命令后，您再输入 `elc`（例如 `elc --help`），它将执行您本地项目中的代码。

- **要切换回 Homebrew 安装的稳定版时：**
  ```bash
  use-elc-global
  ```
  运行此命令后，`elc` 将恢复为指向全局安装的版本。
