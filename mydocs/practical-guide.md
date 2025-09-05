# easy-llm-cli 自定义 LLM 集成实践指南

## 概述

本指南详细介绍如何在 easy-llm-cli 项目中集成自定义 OpenAI 兼容的 LLM 提供商。通过本指南，您将了解完整的配置、测试和部署流程。

## 目录

1. [前置要求](#前置要求)
2. [环境配置](#环境配置)
3. [快速开始](#快速开始)
4. [详细配置](#详细配置)
5. [API 调用栈分析](#api-调用栈分析)
6. [故障排除](#故障排除)
7. [最佳实践](#最佳实践)
8. [高级配置](#高级配置)
9. [性能优化](#性能优化)
10. [安全考虑](#安全考虑)

## 前置要求

### 系统要求
- **操作系统**: macOS, Linux, Windows
- **Node.js**: >= 18.0.0
- **npm**: >= 8.0.0
- **内存**: >= 4GB RAM
- **网络**: 稳定的互联网连接

### API 要求
- **API 类型**: OpenAI 兼容 API
- **认证方式**: Bearer Token
- **支持的端点**:
  - `/v1/models` (模型列表)
  - `/v1/chat/completions` (聊天完成)
  - `/v1/completions` (文本完成)

## 环境配置

### 基本环境变量

easy-llm-cli 使用以下环境变量配置自定义 LLM：

```bash
# 启用自定义 LLM
export USE_CUSTOM_LLM="true"

# API 端点配置
export CUSTOM_LLM_ENDPOINT="https://your-api-endpoint.com/v1"

# API 认证
export CUSTOM_LLM_API_KEY="your-api-key-here"

# 模型配置
export CUSTOM_LLM_MODEL_NAME="your-model-name"

# 可选参数
export CUSTOM_LLM_TEMPERATURE="0.7"
export CUSTOM_LLM_MAX_TOKENS="2048"
export CUSTOM_LLM_TOP_P="0.9"
```

### 配置文件方式

您也可以创建配置文件 `~/.easy-llm-cli/config.json`：

```json
{
  "customLLM": {
    "enabled": true,
    "endpoint": "https://your-api-endpoint.com/v1",
    "apiKey": "your-api-key-here",
    "modelName": "your-model-name",
    "temperature": 0.7,
    "maxTokens": 2048,
    "topP": 0.9
  }
}
```

## 快速开始

### 1. 安装项目

```bash
# 克隆项目
git clone https://github.com/your-username/easy-llm-cli.git
cd easy-llm-cli

# 安装依赖
npm install

# 构建项目
npm run build
```

### 2. 配置环境变量

```bash
# 设置环境变量
export CUSTOM_LLM_ENDPOINT="https://api.example.com/v1"
export CUSTOM_LLM_API_KEY="sk-your-api-key"
export CUSTOM_LLM_MODEL_NAME="gpt-3.5-turbo"
export USE_CUSTOM_LLM="true"
```

### 3. 测试连接

```bash
# 测试 API 连接
curl -s https://api.example.com/v1/models \
  -H "Authorization: Bearer sk-your-api-key" \
  -H "Content-Type: application/json"

# 运行 CLI 测试
npm run start -- -p "Hello, test message"
```

### 4. 验证配置

```bash
# 检查当前配置
npm run start -- --help

# 查看详细日志
DEBUG=1 npm run start -- -p "Debug test"
```

## 详细配置

### API 端点配置

#### 标准 OpenAI 兼容端点
```bash
export CUSTOM_LLM_ENDPOINT="https://api.openai.com/v1"
```

#### 自定义端点
```bash
export CUSTOM_LLM_ENDPOINT="https://your-custom-api.com/v1"
export CUSTOM_LLM_ENDPOINT="http://localhost:8000/v1"  # 本地部署
```

#### 带路径的端点
```bash
export CUSTOM_LLM_ENDPOINT="https://api.example.com/llm/v1"
```

### 认证配置

#### Bearer Token 认证
```bash
export CUSTOM_LLM_API_KEY="sk-your-api-key-here"
```

#### 自定义认证头
如果需要自定义认证头，可以在代码中修改：

```typescript
// packages/core/src/custom_llm/index.ts
private headers: Record<string, string> = {
  'Authorization': `Bearer ${this.apiKey}`,
  'Content-Type': 'application/json',
  'Custom-Header': 'custom-value'  // 添加自定义头
};
```

### 模型配置

#### 基本模型配置
```bash
export CUSTOM_LLM_MODEL_NAME="gpt-3.5-turbo"
```

#### 高级模型配置
```bash
export CUSTOM_LLM_MODEL_NAME="claude-3-sonnet-20240229"
export CUSTOM_LLM_TEMPERATURE="0.7"
export CUSTOM_LLM_MAX_TOKENS="4096"
export CUSTOM_LLM_TOP_P="0.9"
export CUSTOM_LLM_FREQUENCY_PENALTY="0.0"
export CUSTOM_LLM_PRESENCE_PENALTY="0.0"
```

#### 支持的模型类型
- **OpenAI 模型**: gpt-4, gpt-3.5-turbo, gpt-4-turbo
- **Claude 模型**: claude-3-sonnet, claude-3-opus
- **Gemini 模型**: gemini-pro, gemini-1.5-pro
- **本地模型**: llama-2, mistral, vicuna

## API 调用栈分析

### 调用流程图

```
用户输入 → CLI 解析 → ElcAgent → ContentGenerator → CustomLLMContentGenerator → ModelConverter → HTTP 请求 → 外部 API → 响应处理 → 用户输出
```

### 关键组件说明

#### 1. ElcAgent (`packages/cli/src/api/index.ts`)
- 负责用户输入处理和 API 调用初始化
- 设置环境变量和认证信息
- 选择合适的 ContentGenerator

#### 2. CustomLLMContentGenerator (`packages/core/src/custom_llm/index.ts`)
- 处理自定义 LLM 的核心逻辑
- 管理 API 连接和请求发送
- 处理响应和错误处理

#### 3. ModelConverter (`packages/core/src/custom_llm/converter.ts`)
- 负责 Gemini 和 OpenAI 格式之间的转换
- 处理请求和响应的数据格式转换
- 支持流式和非流式响应

### 数据转换流程

#### 请求转换
```
Gemini 格式 → 验证和标准化 → OpenAI 格式 → HTTP 请求
```

#### 响应转换
```
HTTP 响应 → OpenAI 格式解析 → Gemini 格式转换 → CLI 输出
```

## 故障排除

### 常见错误和解决方案

#### 1. 连接错误

**错误信息**: `ECONNREFUSED` 或 `Connection timeout`

**可能原因**:
- API 端点不可达
- 网络连接问题
- 防火墙阻止

**解决方案**:
```bash
# 测试网络连接
ping your-api-endpoint.com

# 检查端口连通性
telnet your-api-endpoint.com 443

# 使用 curl 测试
curl -v https://your-api-endpoint.com/v1/models
```

#### 2. 认证错误

**错误信息**: `401 Unauthorized` 或 `Invalid API key`

**可能原因**:
- API 密钥错误
- 认证头格式错误
- API 密钥过期

**解决方案**:
```bash
# 验证 API 密钥
curl -s https://your-api-endpoint.com/v1/models \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json"

# 检查环境变量
echo $CUSTOM_LLM_API_KEY
```

#### 3. 模型错误

**错误信息**: `Model not found` 或 `Invalid model`

**可能原因**:
- 模型名称错误
- 模型不可用
- 权限不足

**解决方案**:
```bash
# 获取可用模型列表
curl -s https://your-api-endpoint.com/v1/models \
  -H "Authorization: Bearer your-api-key" | jq '.data[].id'
```

#### 4. 格式错误

**错误信息**: `Invalid request format` 或 `Malformed request`

**可能原因**:
- 请求格式不正确
- 参数缺失
- 数据类型错误

**解决方案**:
```bash
# 启用调试模式
DEBUG=1 npm run start -- -p "Debug test"

# 检查请求格式
curl -v -X POST https://your-api-endpoint.com/v1/chat/completions \
  -H "Authorization: Bearer your-api-key" \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-3.5-turbo", "messages": [{"role": "user", "content": "Hello"}]}'
```

### 调试技巧

#### 1. 启用详细日志
```bash
# 启用调试模式
DEBUG=1 npm run start -- -p "Debug message"

# 查看网络请求
DEBUG=request npm run start -- -p "Debug message"
```

#### 2. 检查环境变量
```bash
# 显示所有相关环境变量
env | grep -E "(CUSTOM_LLM|USE_CUSTOM_LLM)"

# 验证配置
npm run start -- --help
```

#### 3. 测试独立组件
```bash
# 测试 API 连接
npm run test:integration:sandbox:none

# 测试模型转换
npm run test -- packages/core/src/custom_llm/converter.test.ts
```

## 最佳实践

### 1. 环境配置

#### 使用 .env 文件
```bash
# .env 文件
CUSTOM_LLM_ENDPOINT=https://your-api.com/v1
CUSTOM_LLM_API_KEY=your-api-key
CUSTOM_LLM_MODEL_NAME=gpt-3.5-turbo
USE_CUSTOM_LLM=true
```

#### 生产环境配置
```bash
# 生产环境使用环境变量
export CUSTOM_LLM_ENDPOINT="${PROD_API_ENDPOINT}"
export CUSTOM_LLM_API_KEY="${PROD_API_KEY}"
export CUSTOM_LLM_MODEL_NAME="${PROD_MODEL_NAME}"
export USE_CUSTOM_LLM="true"
```

### 2. 错误处理

#### 重试机制
```typescript
// 在代码中添加重试逻辑
const maxRetries = 3;
const retryDelay = 1000;

for (let i = 0; i < maxRetries; i++) {
  try {
    const response = await callAPI();
    return response;
  } catch (error) {
    if (i === maxRetries - 1) throw error;
    await new Promise(resolve => setTimeout(resolve, retryDelay));
  }
}
```

#### 超时设置
```typescript
// 设置合理的超时时间
const timeout = 30000; // 30秒
const controller = new AbortController();
const timeoutId = setTimeout(() => controller.abort(), timeout);

try {
  const response = await fetch(url, {
    signal: controller.signal
  });
} catch (error) {
  if (error.name === 'AbortError') {
    console.error('请求超时');
  }
} finally {
  clearTimeout(timeoutId);
}
```

### 3. 性能优化

#### 连接池
```typescript
// 使用连接池提高性能
import https from 'https';

const agent = new https.Agent({
  keepAlive: true,
  maxSockets: 10,
  maxFreeSockets: 5
});
```

#### 缓存机制
```typescript
// 缓存模型列表
const modelCache = new Map();
const cacheTimeout = 3600000; // 1小时

async function getModelList() {
  const cacheKey = 'model-list';
  const cached = modelCache.get(cacheKey);
  
  if (cached && Date.now() - cached.timestamp < cacheTimeout) {
    return cached.data;
  }
  
  const models = await fetchModelList();
  modelCache.set(cacheKey, {
    data: models,
    timestamp: Date.now()
  });
  
  return models;
}
```

## 高级配置

### 1. 代理配置

#### HTTP 代理
```bash
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="https://proxy.example.com:8080"
```

#### SOCKS 代理
```bash
# 使用 global-agent
npm install global-agent
export GLOBAL_AGENT_HTTP_PROXY="socks5://proxy.example.com:1080"
```

### 2. 自定义请求头

```typescript
// 在 CustomLLMContentGenerator 中添加自定义头
private headers: Record<string, string> = {
  'Authorization': `Bearer ${this.apiKey}`,
  'Content-Type': 'application/json',
  'User-Agent': 'easy-llm-cli/1.0.0',
  'X-Custom-Header': 'custom-value'
};
```

### 3. 多提供商配置

```typescript
// 支持多个 LLM 提供商
const providers = {
  openai: {
    endpoint: 'https://api.openai.com/v1',
    apiKey: 'openai-key',
    model: 'gpt-4'
  },
  claude: {
    endpoint: 'https://api.anthropic.com/v1',
    apiKey: 'claude-key',
    model: 'claude-3-sonnet'
  },
  custom: {
    endpoint: 'https://custom-api.com/v1',
    apiKey: 'custom-key',
    model: 'custom-model'
  }
};

// 动态切换提供商
function switchProvider(providerName: string) {
  const provider = providers[providerName];
  process.env.CUSTOM_LLM_ENDPOINT = provider.endpoint;
  process.env.CUSTOM_LLM_API_KEY = provider.apiKey;
  process.env.CUSTOM_LLM_MODEL_NAME = provider.model;
}
```

## 性能优化

### 1. 请求优化

#### 批量处理
```typescript
// 批量处理多个请求
async function batchRequests(requests: Array<any>) {
  const batchSize = 10;
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

#### 并发控制
```typescript
// 控制并发请求数量
import pLimit from 'p-limit';

const limit = pLimit(5); // 最多5个并发请求

async function controlledRequest(request: any) {
  return limit(() => callAPI(request));
}
```

### 2. 内存优化

#### 流式处理
```typescript
// 使用流式处理减少内存占用
async function streamResponse(response: Response) {
  const reader = response.body?.getReader();
  const decoder = new TextDecoder();
  
  while (true) {
    const { done, value } = await reader?.read() || {};
    if (done) break;
    
    const chunk = decoder.decode(value);
    process.stdout.write(chunk);
  }
}
```

#### 垃圾回收
```typescript
// 及时清理不需要的数据
function cleanup() {
  // 清理缓存
  modelCache.clear();
  
  // 清理事件监听器
  process.removeAllListeners();
  
  // 手动触发垃圾回收
  if (global.gc) {
    global.gc();
  }
}
```

## 安全考虑

### 1. API 密钥安全

#### 环境变量加密
```bash
# 使用加密的环境变量
export CUSTOM_LLM_API_KEY=$(openssl enc -aes-256-cbc -a -pass pass:secret -in api_key.txt)
```

#### 密钥轮换
```typescript
// 定期轮换 API 密钥
async function rotateApiKey() {
  const newKey = await generateNewApiKey();
  process.env.CUSTOM_LLM_API_KEY = newKey;
  
  // 保存到安全存储
  await saveToSecureStorage('api-key', newKey);
}
```

### 2. 数据安全

#### 请求加密
```typescript
// 加密敏感数据
import crypto from 'crypto';

function encryptData(data: string, key: string): string {
  const cipher = crypto.createCipher('aes-256-cbc', key);
  let encrypted = cipher.update(data, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return encrypted;
}
```

#### 响应验证
```typescript
// 验证 API 响应的完整性
function validateResponse(response: any): boolean {
  if (!response.object || !response.choices) {
    return false;
  }
  
  // 验证响应格式
  return true;
}
```

### 3. 网络安全

#### TLS 验证
```typescript
// 启用严格的 TLS 验证
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '1';
```

#### 请求签名
```typescript
// 添加请求签名
function signRequest(request: any, secret: string): string {
  const hmac = crypto.createHmac('sha256', secret);
  hmac.update(JSON.stringify(request));
  return hmac.digest('hex');
}
```

## 部署指南

### 1. Docker 部署

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 3000
CMD ["npm", "start"]
```

### 2. Kubernetes 部署

```yaml
# k8s-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: easy-llm-cli
spec:
  replicas: 3
  selector:
    matchLabels:
      app: easy-llm-cli
  template:
    metadata:
      labels:
        app: easy-llm-cli
    spec:
      containers:
      - name: easy-llm-cli
        image: easy-llm-cli:latest
        env:
        - name: CUSTOM_LLM_ENDPOINT
          valueFrom:
            secretKeyRef:
              name: api-secret
              key: endpoint
        - name: CUSTOM_LLM_API_KEY
          valueFrom:
            secretKeyRef:
              name: api-secret
              key: api-key
```

## 监控和日志

### 1. 性能监控

```typescript
// 添加性能监控
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
      return latency;
    }
  };
}
```

### 2. 日志记录

```typescript
// 结构化日志记录
import winston from 'winston';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});
```

## 总结

本实践指南提供了 easy-llm-cli 自定义 LLM 集成的完整流程，从基本配置到高级部署。通过遵循这些指南，您可以成功地将自定义 OpenAI 兼容 API 集成到 easy-llm-cli 项目中。

### 关键要点

1. **环境配置**: 正确设置环境变量是成功的关键
2. **API 兼容性**: 确保 API 端点完全兼容 OpenAI 标准
3. **错误处理**: 实现完善的错误处理和重试机制
4. **性能优化**: 使用连接池、缓存和并发控制提高性能
5. **安全考虑**: 保护 API 密钥和敏感数据
6. **监控日志**: 实现完善的监控和日志系统

### 下一步

- 深入了解源代码架构
- 参与社区贡献
- 测试更多的 LLM 提供商
- 优化性能和用户体验

---

**文档版本**: v1.0  
**最后更新**: 2025-09-05  
**维护者**: Claude AI Assistant