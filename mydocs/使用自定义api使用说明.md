# easy-llm-cli 自定义 API 使用说明

## 📖 项目背景介绍

### 什么是 easy-llm-cli？

easy-llm-cli 是一个基于 TypeScript 的命令行工具，专门用于与大型语言模型（LLM）进行交互。它支持多种 LLM 提供商，包括 Google Gemini 和各种自定义 OpenAI 兼容 API。

### 为什么使用自定义 API？

集成自定义 LLM API 提供以下核心价值：

- **💰 成本优化**: 使用更便宜的本地部署或第三方 API
- **🔒 数据隐私**: 敏感数据保留在私有环境或专用云中
- **🔄 供应商灵活性**: 避免绑定到单一 LLM 提供商
- **🎯 专用模型**: 集成特定领域或微调模型
- **⚡ 性能控制**: 根据需求优化响应时间和吞吐量

### 目标用户

- **开发者**: 需要在项目中集成 LLM 功能
- **MLOps 工程师**: 管理和部署 LLM 服务
- **系统管理员**: 配置和维护 LLM 基础设施
- **研究人员**: 实验不同的 LLM 模型和配置

## ⚙️ 自定义 API 配置方法

### 核心发现：CUSTOM_LLM_* 环境变量

**重要提示**: easy-llm-cli 使用 `CUSTOM_LLM_*` 环境变量，而不是常见的 `OPENAI_*` 变量。这种设计避免了与系统级 OpenAI 配置的冲突。

### 必需的环境变量

```bash
# 启用自定义 LLM 模式
export USE_CUSTOM_LLM="true"

# API 端点 URL
export CUSTOM_LLM_ENDPOINT="https://your-api-endpoint.com/v1"

# API 认证密钥
export CUSTOM_LLM_API_KEY="your-api-key-here"

# 使用的模型名称
export CUSTOM_LLM_MODEL_NAME="your-model-name"
```

### 可选的环境变量

```bash
# 生成参数
export CUSTOM_LLM_TEMPERATURE="0.7"
export CUSTOM_LLM_MAX_TOKENS="2048"
export CUSTOM_LLM_TOP_P="0.9"
export CUSTOM_LLM_FREQUENCY_PENALTY="0.0"
export CUSTOM_LLM_PRESENCE_PENALTY="0.0"
```

### 配置文件方式

您也可以使用配置文件 `~/.easy-llm-cli/config.json`：

```json
{
  "customLLM": {
    "enabled": true,
    "endpoint": "https://your-api-endpoint.com/v1",
    "apiKey": "your-api-key-here",
    "modelName": "your-model-name",
    "temperature": 0.7,
    "maxTokens": 2048
  }
}
```

### 配置优先级

**重要**: 环境变量的优先级高于配置文件。如果同时设置了环境变量和配置文件，环境变量将覆盖配置文件中的设置。

## 🚀 使用 npm start 测试自定义 API 的完整步骤

### 前置条件

1. **安装项目依赖**:
```bash
npm install
```

2. **构建项目**:
```bash
npm run build
```

3. **验证构建成功**:
```bash
ls packages/cli/dist/
```

### 步骤 1: 设置环境变量

```bash
# 设置自定义 API 配置
export CUSTOM_LLM_ENDPOINT="http://mini.ewuzhe.dpdns.org:2000/v1"
export CUSTOM_LLM_API_KEY="sk-wuzhe12345"
export CUSTOM_LLM_MODEL_NAME="gemini-2.5-flash"
export USE_CUSTOM_LLM="true"
```

### 步骤 2: 验证 API 端点连通性

```bash
# 测试 API 端点是否可达
curl -s -o /dev/null -w "%{http_code}" "http://mini.ewuzhe.dpdns.org:2000/v1/models" \
  -H "Authorization: Bearer sk-wuzhe12345" \
  -H "Content-Type: application/json"
```

**期望输出**: `200`

### 步骤 3: 检查可用模型列表

```bash
# 获取可用模型列表
curl -s "http://mini.ewuzhe.dpdns.org:2000/v1/models" \
  -H "Authorization: Bearer sk-wuzhe12345" \
  -H "Content-Type: application/json" | jq '.data[].id'
```

**期望输出**: 包含 `gemini-2.5-flash` 的模型列表

### 步骤 4: 基本对话测试

```bash
# 使用 npm start 进行基本对话测试
npm run start -- -p "Hello, please respond with just 'Test successful'"
```

**期望输出**: CLI 启动并显示 "Test successful" 或类似响应

### 步骤 5: 复杂对话测试

```bash
# 测试更复杂的对话
npm run start -- -p "What is the capital of France? Please answer in one sentence."
```

**期望输出**: "The capital of France is Paris."

### 步骤 6: 流式响应测试

```bash
# 测试流式响应（如果支持）
npm run start -- -s -p "Count from 1 to 5 slowly"
```

## 📋 实际测试案例

### 测试案例 1: 基本功能验证

**目标**: 验证基本的对话功能

**命令**:
```bash
npm run start -- -p "Hello, please respond with just 'Test successful'"
```

**成功标准**:
- CLI 正常启动
- API 连接成功
- 响应内容正确
- 无错误信息

### 测试案例 2: 模型信息验证

**目标**: 确认使用的是正确的自定义模型

**命令**:
```bash
# 启用调试模式
DEBUG=1 npm run start -- -p "What model are you?"
```

**成功标准**:
- 调试信息显示使用的是自定义 API
- 响应来自配置的模型

### 测试案例 3: 参数测试

**目标**: 测试不同的生成参数

**命令**:
```bash
# 测试低温度设置
export CUSTOM_LLM_TEMPERATURE="0.1"
npm run start -- -p "Generate a random number between 1 and 10"

# 测试高温度设置
export CUSTOM_LLM_TEMPERATURE="0.9"
npm run start -- -p "Generate a random number between 1 and 10"
```

**成功标准**:
- 低温度时输出更一致
- 高温度时输出更多样化

### 测试案例 4: 错误处理测试

**目标**: 测试错误场景的处理

**测试 1: 错误的 API 密钥**
```bash
export CUSTOM_LLM_API_KEY="wrong-key"
npm run start -- -p "Test"
```

**期望**: 显示认证错误信息

**测试 2: 错误的模型名称**
```bash
export CUSTOM_LLM_MODEL_NAME="nonexistent-model"
npm run start -- -p "Test"
```

**期望**: 显示模型未找到错误

### 测试案例 5: 性能测试

**目标**: 测试响应性能

**命令**:
```bash
time npm run start -- -p "What is 2+2?"
```

**成功标准**:
- 响应时间在合理范围内（通常 < 10秒）
- 无超时或连接问题

## 🔧 环境变量配置详解

### 变量说明表格

| 变量名 | 必需 | 默认值 | 说明 | 示例 |
|--------|------|--------|------|------|
| `USE_CUSTOM_LLM` | 是 | `false` | 启用自定义 LLM 模式 | `true` |
| `CUSTOM_LLM_ENDPOINT` | 是 | `""` | API 端点 URL | `https://api.example.com/v1` |
| `CUSTOM_LLM_API_KEY` | 是 | `""` | API 认证密钥 | `sk-abc123` |
| `CUSTOM_LLM_MODEL_NAME` | 是 | `""` | 使用的模型名称 | `gpt-3.5-turbo` |
| `CUSTOM_LLM_TEMPERATURE` | 否 | `0.7` | 生成随机性 (0-1) | `0.5` |
| `CUSTOM_LLM_MAX_TOKENS` | 否 | `2048` | 最大生成长度 | `1000` |
| `CUSTOM_LLM_TOP_P` | 否 | `0.9` | 核心采样 (0-1) | `0.8` |
| `CUSTOM_LLM_FREQUENCY_PENALTY` | 否 | `0.0` | 频率惩罚 (-2 到 2) | `0.1` |
| `CUSTOM_LLM_PRESENCE_PENALTY` | 否 | `0.0` | 存在惩罚 (-2 到 2) | `0.1` |

### 环境变量设置方法

#### 临时设置（当前会话）
```bash
export CUSTOM_LLM_ENDPOINT="https://your-api.com/v1"
export CUSTOM_LLM_API_KEY="your-key"
```

#### 永久设置（bash）
```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
echo 'export CUSTOM_LLM_ENDPOINT="https://your-api.com/v1"' >> ~/.bashrc
echo 'export CUSTOM_LLM_API_KEY="your-key"' >> ~/.bashrc
source ~/.bashrc
```

#### 使用 .env 文件
创建 `.env` 文件：
```bash
# .env
CUSTOM_LLM_ENDPOINT=https://your-api.com/v1
CUSTOM_LLM_API_KEY=your-key
CUSTOM_LLM_MODEL_NAME=gpt-3.5-turbo
USE_CUSTOM_LLM=true
```

然后使用：
```bash
# 安装 dotenv
npm install dotenv

# 运行时加载
node -r dotenv/config your-script.js
```

### 配置验证

easy-llm-cli 会在启动时验证关键配置：

```typescript
// 内置验证逻辑
if (process.env.USE_CUSTOM_LLM === 'true') {
  if (!process.env.CUSTOM_LLM_ENDPOINT) {
    throw new Error('CUSTOM_LLM_ENDPOINT is required when USE_CUSTOM_LLM is true');
  }
  if (!process.env.CUSTOM_LLM_API_KEY) {
    console.warn('Warning: CUSTOM_LLM_API_KEY is not set');
  }
  if (!process.env.CUSTOM_LLM_MODEL_NAME) {
    console.warn('Warning: CUSTOM_LLM_MODEL_NAME is not set');
  }
}
```

## 🚨 常见问题解决方案

### 问题 1: 连接错误

**错误信息**: `ECONNREFUSED` 或 `Connection timeout`

**可能原因**:
- API 端点不可达
- 网络连接问题
- 防火墙阻止

**解决方案**:
```bash
# 1. 检查网络连接
ping your-api-endpoint.com

# 2. 检查端口连通性
telnet your-api-endpoint.com 443

# 3. 使用 curl 详细测试
curl -v https://your-api-endpoint.com/v1/models \
  -H "Authorization: Bearer your-api-key"

# 4. 检查代理设置
echo $HTTP_PROXY
echo $HTTPS_PROXY
```

### 问题 2: 认证错误

**错误信息**: `401 Unauthorized` 或 `Invalid API key`

**可能原因**:
- API 密钥错误
- 认证头格式错误
- API 密钥过期

**解决方案**:
```bash
# 1. 验证 API 密钥格式
echo $CUSTOM_LLM_API_KEY

# 2. 测试认证
curl -s https://your-api-endpoint.com/v1/models \
  -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
  -H "Content-Type: application/json"

# 3. 检查密钥是否包含特殊字符
# 如果包含，确保正确转义
```

### 问题 3: 模型错误

**错误信息**: `Model not found` 或 `Invalid model`

**可能原因**:
- 模型名称错误
- 模型不可用
- 权限不足

**解决方案**:
```bash
# 1. 获取可用模型列表
curl -s https://your-api-endpoint.com/v1/models \
  -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" | jq '.data[].id'

# 2. 验证模型名称拼写
echo $CUSTOM_LLM_MODEL_NAME

# 3. 确认模型在可用列表中
```

### 问题 4: 格式错误

**错误信息**: `Invalid request format` 或 `Malformed request`

**可能原因**:
- 请求格式不正确
- 参数缺失
- 数据类型错误

**解决方案**:
```bash
# 1. 启用详细调试
DEBUG=1 npm run start -- -p "Debug test"

# 2. 检查请求格式
curl -v -X POST https://your-api-endpoint.com/v1/chat/completions \
  -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-3.5-turbo", "messages": [{"role": "user", "content": "Hello"}]}'
```

### 问题 5: 速率限制

**错误信息**: `429 Too Many Requests`

**可能原因**:
- 超过 API 调用限制
- 并发请求过多

**解决方案**:
```bash
# 1. 检查 API 限制文档
# 查看您的 API 提供商的速率限制政策

# 2. 实现重试逻辑
# 在代码中添加指数退避重试

# 3. 降低请求频率
# 在请求之间添加延迟
```

### 问题 6: 响应格式不匹配

**错误信息**: 解析错误或 unexpected response format

**可能原因**:
- API 响应不符合 OpenAI 格式
- 自定义 API 实现不完整

**解决方案**:
```bash
# 1. 检查原始响应
curl -s https://your-api-endpoint.com/v1/chat/completions \
  -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-3.5-turbo", "messages": [{"role": "user", "content": "Hello"}]}'

# 2. 验证响应格式
# 确保响应包含必要的字段：id, object, choices, usage

# 3. 检查自定义 API 日志
# 如果您控制 API 服务器，检查服务器端日志
```

## 💡 最佳实践建议

### 安全最佳实践

#### 1. 密钥管理
```bash
# ✅ 好的做法：使用环境变量
export CUSTOM_LLM_API_KEY="your-key"

# ✅ 好的做法：使用 .env 文件（添加到 .gitignore）
# .env
CUSTOM_LLM_API_KEY=your-key

# ❌ 避免的做法：硬编码在代码中
# const apiKey = "your-key"; // 不要这样做！

# ❌ 避免的做法：提交到版本控制
# git add .env  # 不要这样做！
```

#### 2. 生产环境部署
```yaml
# Kubernetes 示例
apiVersion: v1
kind: Secret
metadata:
  name: llm-api-secret
type: Opaque
stringData:
  CUSTOM_LLM_API_KEY: your-production-key
  CUSTOM_LLM_ENDPOINT: https://your-production-api.com/v1
```

#### 3. 权限最小化
- 只授予 API 密钥必要的权限
- 定期轮换 API 密钥
- 使用不同的密钥用于开发和生产

### 性能优化

#### 1. 连接池配置
```typescript
// 在高级配置中使用连接池
const https = require('https');

const agent = new https.Agent({
  keepAlive: true,
  maxSockets: 10,
  maxFreeSockets: 5
});
```

#### 2. 请求缓存
```typescript
// 缓存模型列表等不常变化的数据
const modelCache = new Map();
const cacheTimeout = 3600000; // 1小时

async function getCachedModels() {
  const cacheKey = 'models';
  const cached = modelCache.get(cacheKey);
  
  if (cached && Date.now() - cached.timestamp < cacheTimeout) {
    return cached.data;
  }
  
  const models = await fetchModels();
  modelCache.set(cacheKey, {
    data: models,
    timestamp: Date.now()
  });
  
  return models;
}
```

#### 3. 批量处理
```typescript
// 批量处理多个请求
async function batchRequests(requests) {
  const batchSize = 5; // 根据 API 限制调整
  const results = [];
  
  for (let i = 0; i < requests.length; i += batchSize) {
    const batch = requests.slice(i, i + batchSize);
    const batchResults = await Promise.allSettled(
      batch.map(req => callAPI(req))
    );
    results.push(...batchResults);
  }
  
  return results;
}
```

### 错误处理和重试

#### 1. 指数退避重试
```typescript
async function retryWithBackoff(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      
      const delay = Math.pow(2, i) * 1000; // 1s, 2s, 4s
      console.log(`Retry ${i + 1}/${maxRetries} after ${delay}ms`);
      await new Promise(resolve => setTimeout(resolve, delay));
    }
  }
}
```

#### 2. 超时处理
```typescript
async function callWithTimeout(url, options, timeout = 30000) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeout);
  
  try {
    const response = await fetch(url, {
      ...options,
      signal: controller.signal
    });
    clearTimeout(timeoutId);
    return response;
  } catch (error) {
    clearTimeout(timeoutId);
    if (error.name === 'AbortError') {
      throw new Error('Request timeout');
    }
    throw error;
  }
}
```

### 监控和日志

#### 1. 结构化日志
```typescript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

// 使用日志
logger.info('API call started', { 
  endpoint: process.env.CUSTOM_LLM_ENDPOINT,
  model: process.env.CUSTOM_LLM_MODEL_NAME 
});
```

#### 2. 性能监控
```typescript
const performance = {
  requestCount: 0,
  totalLatency: 0,
  errorCount: 0
};

function monitorRequest() {
  const start = Date.now();
  performance.requestCount++;
  
  return {
    end: () => {
      const latency = Date.now() - start;
      performance.totalLatency += latency;
      logger.info('Request completed', { latency });
      return latency;
    }
  };
}
```

### 开发和测试

#### 1. 本地开发环境
```bash
# 创建开发环境配置
# .env.development
CUSTOM_LLM_ENDPOINT=http://localhost:8000/v1
CUSTOM_LLM_API_KEY=dev-key
CUSTOM_LLM_MODEL_NAME=test-model
USE_CUSTOM_LLM=true

# 加载开发配置
node -r dotenv/config --dotenv-file=.env.development your-script.js
```

#### 2. 自动化测试
```javascript
// 测试脚本示例
const { spawn } = require('child_process');

function testCLI(prompt, expectedResponse) {
  return new Promise((resolve, reject) => {
    const child = spawn('npm', ['run', 'start', '--', '-p', prompt]);
    
    let output = '';
    child.stdout.on('data', (data) => {
      output += data.toString();
    });
    
    child.on('close', (code) => {
      if (output.includes(expectedResponse)) {
        resolve(true);
      } else {
        reject(new Error(`Expected "${expectedResponse}" but got "${output}"`));
      }
    });
  });
}
```

#### 3. 配置验证
```javascript
// 验证配置
function validateConfig() {
  const required = ['USE_CUSTOM_LLM', 'CUSTOM_LLM_ENDPOINT', 'CUSTOM_LLM_API_KEY'];
  const missing = required.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
  }
  
  if (process.env.USE_CUSTOM_LLM === 'true' && !process.env.CUSTOM_LLM_MODEL_NAME) {
    console.warn('Warning: CUSTOM_LLM_MODEL_NAME not set');
  }
}
```

## 📚 高级用法

### 多提供商配置

```javascript
// 支持多个 LLM 提供商
const providers = {
  openai: {
    endpoint: 'https://api.openai.com/v1',
    apiKey: 'openai-key',
    model: 'gpt-4'
  },
  custom: {
    endpoint: 'https://custom-api.com/v1',
    apiKey: 'custom-key',
    model: 'custom-model'
  }
};

// 动态切换提供商
function switchProvider(providerName) {
  const provider = providers[providerName];
  process.env.CUSTOM_LLM_ENDPOINT = provider.endpoint;
  process.env.CUSTOM_LLM_API_KEY = provider.apiKey;
  process.env.CUSTOM_LLM_MODEL_NAME = provider.model;
}
```

### 代理配置

```bash
# HTTP 代理
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="https://proxy.example.com:8080"

# SOCKS 代理
export ALL_PROXY="socks5://proxy.example.com:1080"
```

### 自定义请求头

```javascript
// 在高级配置中添加自定义头
const customHeaders = {
  'User-Agent': 'easy-llm-cli/1.0.0',
  'X-Custom-Header': 'custom-value',
  'Authorization': `Bearer ${process.env.CUSTOM_LLM_API_KEY}`
};
```

## 🎯 总结

本使用说明提供了 easy-llm-cli 自定义 API 集成的完整指南。通过遵循这些步骤和最佳实践，您可以成功地：

1. ✅ 配置自定义 OpenAI 兼容 API
2. ✅ 使用 npm start 测试 API 功能
3. ✅ 解决常见问题和错误
4. ✅ 实现生产级别的部署
5. ✅ 优化性能和安全性

记住，成功的自定义 API 集成关键在于：
- **正确的环境变量配置**
- **充分的测试验证**
- **完善的错误处理**
- **严格的安全措施**
- **持续的监控优化**

---

**文档版本**: v1.0  
**最后更新**: 2025-09-05  
**维护者**: Claude AI Assistant  
**基于项目**: easy-llm-cli 自定义模型 API 调用栈分析