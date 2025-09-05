# CLAUDE.md

本文件为Claude Code (claude.ai/code) 提供在本代码库中工作的指导。

## 开发命令

### 构建与测试

- `npm run preflight` - 完整的开发工作流（清理、安装、格式化、lint、构建、类型检查、测试）
- `npm run build` - 构建所有包并创建分发包
- `npm run build:all` - 构建所有内容，包括沙箱容器
- `npm run test` - 在所有工作区运行测试
- `npm run test:ci` - 运行带覆盖率的CI测试
- `npm run test:e2e` - 运行端到端集成测试
- `npm run lint` - 对所有TypeScript文件进行lint检查
- `npm run lint:fix` - 自动修复lint问题
- `npm run format` - 使用Prettier格式化代码
- `npm run typecheck` - 运行TypeScript类型检查

### 开发工作流

- `npm run start` - 以开发模式启动CLI
- `npm run debug` - 附加Node.js调试器启动CLI
- `npm run bundle` - 创建用于npm发布的分发包

### 测试单个组件

- `npm run test --workspace=packages/cli` - 仅测试CLI包
- `npm run test --workspace=packages/core` - 仅测试core包
- `npm run test:integration:sandbox:none` - 不使用沙箱运行集成测试
- `npm run test:integration:sandbox:docker` - 使用Docker沙箱运行集成测试
- `vitest run path/to/test.test.ts` - 运行特定测试文件

## 架构概述

### 包结构

这是一个包含两个主要包的monorepo：

1. **`packages/cli`** - 前端/UI层
   - 使用Ink的基于React的终端UI
   - 处理用户输入、显示渲染和配置
   - 入口点：`packages/cli/src/gemini.tsx`
   - API接口：`packages/cli/src/api/index.ts` (ElcAgent类)

2. **`packages/core`** - 后端/LLM集成层
   - LLM API通信和工具执行
   - 工具注册和调度
   - 配置管理
   - 入口点：`packages/core/src/index.ts`

### 关键架构模式

#### 多LLM支持

- **自定义LLM集成**：通过`packages/core/src/custom_llm/`支持OpenAI兼容API
- **环境配置**：使用`CUSTOM_LLM_*`环境变量配置自定义提供者
- **模型切换**：可以在Gemini和自定义LLM之间切换而无需更改工作流

#### 工具系统

- **BaseTool抽象**：所有工具都继承自`packages/core/src/tools/tools.ts`中的`BaseTool<TParams, TResult>`
- **工具注册中心**：在`packages/core/src/tools/tool-registry.ts`中集中注册工具
- **MCP集成**：支持模型上下文协议的可扩展工具
- **内置工具**：文件操作、shell执行、web获取、git集成

#### 配置系统

- **分层配置**：用户设置 → 项目设置 → CLI参数
- **扩展系统**：支持MCP服务器和工具扩展
- **沙箱支持**：使用Docker/Podman容器化实现安全的工具执行

#### 内存和上下文管理

- **对话历史**：超过token限制时自动压缩
- **文件发现**：智能文件发现和上下文构建
- **检查点**：会话持久化和恢复

### 重要开发说明

#### 构建过程

- 使用ESBuild进行打包，同时输出ESM和CommonJS
- 两个主要包：`bundle/gemini.js` (CLI) 和 `bundle/api.js` (编程API)
- 基于npm工作区的构建

#### 测试策略

- 使用Vitest进行单元测试
- 使用实际LLM API调用进行集成测试
- 沙箱测试确保工具执行安全
- 端到端测试完整用户工作流

#### 安全考虑

- **工具执行**：所有文件修改和shell命令需要用户确认
- **沙箱**：可选Docker/Podman隔离工具执行
- **API密钥**：使用环境变量，绝不提交到代码
- **只读模式**：可以限制为只读操作

#### 错误处理

- 提供上下文信息的全面错误报告
- API失败时自动重试并指数退避
- 工具不可用时优雅降级
- 提供可操作建议的用户友好错误信息

### 开发环境变量

#### LLM配置

- `USE_CUSTOM_LLM=true` - 启用自定义LLM提供者
- `CUSTOM_LLM_MODEL_NAME` - 模型名称(如"gpt-4")
- `CUSTOM_LLM_ENDPOINT` - API端点URL
- `CUSTOM_LLM_API_KEY` - API认证密钥
- `CUSTOM_LLM_TEMPERATURE` - 响应温度(0-1)
- `CUSTOM_LLM_MAX_TOKENS` - 最大响应token数

#### 调试

- `DEBUG=1` - 启用调试日志
- `GEMINI_CLI_NO_RELAUNCH` - 禁用自动内存重启
- `GEMINI_SANDBOX=docker|podman` - 启用沙箱测试

#### 开发功能

- `READ_ONLY=true` - 限制为只读操作
- `SYSTEM_PROMPT` - 覆盖默认系统提示
- `NO_COLOR` - 禁用彩色输出

### 常见开发模式

#### 添加新工具

1. 在`packages/core/src/tools/`中继承`BaseTool<TParams, TResult>`
2. 实现必需方法：`validateToolParams`, `getDescription`, `shouldConfirmExecute`, `execute`
3. 在适当的工具注册中心注册工具
4. 按照现有模式添加测试

#### 修改配置

1. 更新`packages/core/src/config/config.ts`中的配置接口
2. 修改`packages/cli/src/config/config.ts`中的参数解析
3. 更新`packages/cli/src/config/settings.ts`中的设置管理
4. 如有需要添加迁移逻辑

#### 生产构建

1. 运行`npm run preflight`确保所有检查通过
2. 使用`npm run bundle`创建分发包
3. 使用`npm run test:e2e`进行完整工作流验证
4. 通过`npm run release:version`进行版本管理
