# Easy LLM CLI 用户使用指南

## 目录

1. [快速开始](#快速开始)
2. [认证方式详解](#认证方式详解)
3. [API 配置管理](#api-配置管理)
4. [API 更换步骤详解](#api-更换步骤详解)
5. [最佳实践](#最佳实践)
6. [故障排除](#故障排除)
7. [常见问题解答](#常见问题解答)

---

## 快速开始

### 安装

```bash
# 使用 npx 直接运行
npx easy-llm-cli

# 或全局安装
npm install -g easy-llm-cli
elc
```

### 首次运行

首次运行时，CLI 会引导您选择认证方式：

1. **Google OAuth 登录** - 适合个人用户
2. **Gemini API Key** - 适合开发者
3. **Vertex AI** - 适合企业用户
4. **自定义 LLM API** - 适合使用其他模型提供商

---

## 认证方式详解

### 1. Google OAuth 登录

```bash
# 无需额外配置，首次运行时选择 "Login with Google" 即可
# 系统会自动打开浏览器进行身份验证
```

**适用场景：**

- 个人开发者
- 已有 Google 账户
- 希望使用 Gemini Code Assist 功能

**注意事项：**

- 需要 Google Workspace 用户可能需要设置 `GOOGLE_CLOUD_PROJECT`
- 浏览器需要能访问 localhost

### 2. Gemini API Key

```bash
# 获取 API Key
# 访问：https://aistudio.google.com/app/apikey

# 临时设置（当前会话有效）
export GEMINI_API_KEY="your_api_key_here"

# 永久设置（添加到 shell 配置文件）
echo 'export GEMINI_API_KEY="your_api_key_here"' >> ~/.bashrc
source ~/.bashrc
```

**适用场景：**

- 开发者
- 需要简单快速配置
- 测试和开发环境

### 3. Vertex AI

```bash
# 标准模式
export GOOGLE_CLOUD_PROJECT="your_project_id"
export GOOGLE_CLOUD_LOCATION="us-central1"
gcloud auth application-default login

# 快速模式
export GOOGLE_API_KEY="your_vertex_api_key"
```

**适用场景：**

- 企业用户
- 已有 Google Cloud 项目
- 需要企业级功能

### 4. 自定义 LLM API

```bash
# 启用自定义 LLM
export USE_CUSTOM_LLM=true

# 配置自定义 LLM 参数
export CUSTOM_LLM_PROVIDER="openai"
export CUSTOM_LLM_API_KEY="your_api_key"
export CUSTOM_LLM_ENDPOINT="https://api.openai.com/v1"
export CUSTOM_LLM_MODEL_NAME="gpt-4"

# 可选参数
export CUSTOM_LLM_TEMPERATURE=0.7
export CUSTOM_LLM_MAX_TOKENS=8192
export CUSTOM_LLM_TOP_P=1.0
export CUSTOM_LLM_TIMEOUT=30000  # 请求超时时间（毫秒）
```

**适用场景：**

- 使用 OpenAI 模型
- 使用自托管模型
- 需要特定模型提供商
- 需要自定义超时和性能参数

**新增功能：**

- **超时控制**：通过 `CUSTOM_LLM_TIMEOUT` 设置请求超时时间
- **API 验证**：内置 `validateApi()` 方法测试连接和模型兼容性
- **错误处理**：优雅处理超时和空响应，提供友好的错误消息
- **诊断工具**：使用 `diagnose-api.sh` 脚本进行全面诊断

---

## API 配置管理

### 环境变量配置优先级

配置按以下优先级加载（高优先级覆盖低优先级）：

1. **命令行参数** - 最高优先级
2. **环境变量** - 会话级别
3. **项目设置文件** - 项目级别
4. **用户设置文件** - 用户级别
5. **默认值** - 最低优先级

### `.env` 文件管理

#### 项目级配置

```bash
# 在项目根目录创建 .gemini/.env
mkdir -p .gemini
cat > .gemini/.env << 'EOF'
# Gemini API 配置
GEMINI_API_KEY="your_gemini_api_key"

# 自定义 LLM 配置
USE_CUSTOM_LLM=true
CUSTOM_LLM_PROVIDER="openai"
CUSTOM_LLM_API_KEY="your_openai_key"
CUSTOM_LLM_ENDPOINT="https://api.openai.com/v1"
CUSTOM_LLM_MODEL_NAME="gpt-4"

# 性能参数配置
CUSTOM_LLM_TEMPERATURE=0.7
CUSTOM_LLM_MAX_TOKENS=8192
CUSTOM_LLM_TOP_P=1.0
CUSTOM_LLM_TIMEOUT=30000  # 30秒超时
EOF
```

#### 用户级配置

```bash
# 在用户主目录创建配置
mkdir -p ~/.gemini
cat > ~/.gemini/.env << 'EOF'
# 默认配置
GEMINI_API_KEY="your_default_gemini_key"
GOOGLE_CLOUD_PROJECT="your_default_project"
EOF
```

### `.env` 文件搜索顺序

CLI 按以下顺序查找 `.env` 文件：

1. 当前目录 → `.gemini/.env` 或 `.env`
2. 向上搜索至项目根目录 → `.gemini/.env` 或 `.env`
3. 用户主目录 → `~/.gemini/.env` 或 `~/.env`

> **注意：** 找到第一个文件后停止搜索，不会合并多个文件。

### `settings.json` 配置

#### 用户级设置文件

```json
// ~/.gemini/settings.json
{
  "selectedAuthType": "gemini-api-key",
  "theme": "GitHub",
  "sandbox": false,
  "telemetry": {
    "enabled": false
  },
  "usageStatisticsEnabled": false
}
```

#### 项目级设置文件

```json
// .gemini/settings.json
{
  "selectedAuthType": "custom-llm-api",
  "contextFileName": "PROJECT.md",
  "coreTools": ["ReadFileTool", "WriteFileTool", "ShellTool"],
  "excludeTools": ["web-fetch", "web-search"]
}
```

---

## API 更换步骤详解

### 场景1：从 Gemini API 切换到 OpenAI

#### 步骤1：获取 OpenAI API Key

```bash
# 访问 https://platform.openai.com/api-keys 获取 API Key
OPENAI_API_KEY="sk-your-openai-api-key"
```

#### 步骤2：创建项目级配置

```bash
# 在项目目录创建配置文件
mkdir -p .gemini
cat > .gemini/.env << 'EOF'
# 启用自定义 LLM
USE_CUSTOM_LLM=true

# OpenAI 配置
CUSTOM_LLM_PROVIDER="openai"
CUSTOM_LLM_API_KEY="sk-your-openai-api-key"
CUSTOM_LLM_ENDPOINT="https://api.openai.com/v1"
CUSTOM_LLM_MODEL_NAME="gpt-4"

# 可选参数
CUSTOM_LLM_TEMPERATURE=0.7
CUSTOM_LLM_MAX_TOKENS=8192
CUSTOM_LLM_TOP_P=1.0
CUSTOM_LLM_TIMEOUT=30000  # 30秒超时
EOF
```

#### 步骤3：更新设置文件

```bash
cat > .gemini/settings.json << 'EOF'
{
  "selectedAuthType": "custom-llm-api",
  "theme": "GitHub",
  "autoAccept": false
}
EOF
```

#### 步骤4：验证配置

```bash
# 检查环境变量
echo "USE_CUSTOM_LLM: $USE_CUSTOM_LLM"
echo "CUSTOM_LLM_PROVIDER: $CUSTOM_LLM_PROVIDER"
echo "CUSTOM_LLM_MODEL_NAME: $CUSTOM_LLM_MODEL_NAME"

# 启动 CLI 验证
elc --help
```

### 场景2：更换 Gemini API Key

#### 步骤1：获取新 API Key

```bash
# 访问 https://aistudio.google.com/app/apikey 获取新 API Key
NEW_GEMINI_KEY="your_new_gemini_api_key"
```

#### 步骤2：更新环境变量

```bash
# 方法1：直接更新环境变量
export GEMINI_API_KEY="$NEW_GEMINI_KEY"

# 方法2：更新 .env 文件
sed -i "s/GEMINI_API_KEY=.*/GEMINI_API_KEY=\"$NEW_GEMINI_KEY\"/" .gemini/.env

# 方法3：更新 shell 配置文件
sed -i "s/export GEMINI_API_KEY=.*/export GEMINI_API_KEY=\"$NEW_GEMINI_KEY\"/" ~/.bashrc
source ~/.bashrc
```

#### 步骤3：清除缓存（如果需要）

```bash
# 清除认证缓存
rm -f ~/.gemini/credentials.json

# 重新启动 CLI
elc
```

### 场景3：切换到自托管模型

#### 步骤1：配置自托管模型

```bash
# 假设自托管模型运行在 http://localhost:8000
cat > .gemini/.env << 'EOF'
USE_CUSTOM_LLM=true
CUSTOM_LLM_PROVIDER="openai"  # 使用 OpenAI 兼容格式
CUSTOM_LLM_API_KEY="your-api-key"
CUSTOM_LLM_ENDPOINT="http://localhost:8000/v1"
CUSTOM_LLM_MODEL_NAME="your-model-name"

# 自托管模型通常需要更长的超时时间
CUSTOM_LLM_TIMEOUT=30000  # 30秒超时 (flash模型响应更快)
CUSTOM_LLM_MAX_TOKENS=8192  # flash模型可以处理更多令牌
EOF
```

#### 步骤2：验证连接

```bash
# 测试 API 连接
curl -X POST "$CUSTOM_LLM_ENDPOINT/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
  -d '{
    "model": "'"$CUSTOM_LLM_MODEL_NAME"'",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10
  }'
```

### 验证配置是否生效

#### 方法1：检查 CLI 启动信息

```bash
elc --debug
```

查看启动日志中的认证信息和模型配置。

#### 方法2：使用测试命令

```bash
# 在 CLI 中运行
> /help
> /model
```

#### 方法3：检查设置文件

```bash
# 查看当前设置
cat ~/.gemini/settings.json
cat .gemini/settings.json

# 查看环境变量
env | grep -E "(GEMINI|CUSTOM_LLM|USE_CUSTOM)"
```

---

## API 性能优化和故障排除

### 超时配置管理

#### 理解超时设置

```bash
# 默认超时时间
CUSTOM_LLM_TIMEOUT=30000  # 30秒

# 针对不同场景的超时配置
# 快速响应API（如OpenAI）
CUSTOM_LLM_TIMEOUT=15000  # 15秒

# 慢速API（如自托管模型）
CUSTOM_LLM_TIMEOUT=60000  # 60秒

# 高延迟网络环境
CUSTOM_LLM_TIMEOUT=120000  # 120秒
```

#### 超时配置建议

**快速响应API（< 5秒响应时间）**

```bash
CUSTOM_LLM_TIMEOUT=15000
CUSTOM_LLM_MAX_TOKENS=2048
```

**标准响应API（5-15秒响应时间）**

```bash
CUSTOM_LLM_TIMEOUT=30000
CUSTOM_LLM_MAX_TOKENS=4096
```

**慢速响应API（> 15秒响应时间）**

```bash
CUSTOM_LLM_TIMEOUT=60000
CUSTOM_LLM_MAX_TOKENS=2048
```

### API 诊断工具

#### 使用诊断脚本

```bash
# 运行全面的API诊断
./diagnose-api.sh

# 诊断脚本功能：
# 1. 环境变量检查
# 2. 网络连接测试
# 3. API端点验证
# 4. 响应时间测试
# 5. 模型兼容性检查
```

#### 手动API验证

```bash
# 测试基本连接
curl -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
     -H "Content-Type: application/json" \
     "$CUSTOM_LLM_ENDPOINT/models"

# 测试聊天完成端点
curl -X POST "$CUSTOM_LLM_ENDPOINT/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
  -d '{
    "model": "'"$CUSTOM_LLM_MODEL_NAME"'",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10,
    "temperature": 0.1
  }'
```

### 性能优化策略

#### 令牌管理

```bash
# 减少输出令牌以提高响应速度
CUSTOM_LLM_MAX_TOKENS=1024  # 快速响应
CUSTOM_LLM_MAX_TOKENS=2048  # 平衡响应
CUSTOM_LLM_MAX_TOKENS=4096  # 详细响应
```

#### 温度参数调整

```bash
# 低温度 - 更一致、更快的响应
CUSTOM_LLM_TEMPERATURE=0.1

# 中等温度 - 平衡创造性和一致性
CUSTOM_LLM_TEMPERATURE=0.7

# 高温度 - 更创造性但可能更慢
CUSTOM_LLM_TEMPERATURE=1.0
```

#### 网络优化

```bash
# 为高延迟网络配置代理
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"

# 增加重试次数和超时时间
CUSTOM_LLM_TIMEOUT=90000
```

### 错误处理和重试

#### 自动重试配置

```bash
# 配置重试参数（通过环境变量）
CUSTOM_LLM_MAX_RETRIES=3
CUSTOM_LLM_RETRY_DELAY=1000  # 1秒延迟
```

#### 错误类型和处理

1. **超时错误**

   ```bash
   # 增加超时时间
   CUSTOM_LLM_TIMEOUT=60000

   # 减少请求复杂度
   CUSTOM_LLM_MAX_TOKENS=1024
   ```

2. **连接错误**

   ```bash
   # 检查网络连接
   ping $(echo $CUSTOM_LLM_ENDPOINT | sed 's|https://||' | sed 's|/.*||')

   # 配置代理
   export HTTP_PROXY="http://proxy.example.com:8080"
   ```

3. **认证错误**
   ```bash
   # 验证API密钥
   curl -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
        -H "Content-Type: application/json" \
        "$CUSTOM_LLM_ENDPOINT/models"
   ```

---

## 最佳实践

### API 密钥安全管理

1. **使用环境变量** - 避免硬编码在代码中
2. **项目隔离** - 不同项目使用不同的 API Key
3. **定期轮换** - 定期更换 API Key
4. **权限最小化** - 使用最小必要权限的 API Key

### 多项目管理

#### 项目 A - 使用 Gemini API（快速响应）

```bash
# project-a/.gemini/.env
GEMINI_API_KEY="gemini_key_for_project_a"
GEMINI_MODEL="gemini-1.5-pro"
```

#### 项目 B - 使用 OpenAI（标准响应）

```bash
# project-b/.gemini/.env
USE_CUSTOM_LLM=true
CUSTOM_LLM_PROVIDER="openai"
CUSTOM_LLM_API_KEY="openai_key_for_project_b"
CUSTOM_LLM_MODEL_NAME="gpt-4"
CUSTOM_LLM_TIMEOUT=30000
CUSTOM_LLM_MAX_TOKENS=4096
```

#### 项目 C - 使用自托管模型（慢速响应）

```bash
# project-c/.gemini/.env
USE_CUSTOM_LLM=true
CUSTOM_LLM_PROVIDER="openai"
CUSTOM_LLM_API_KEY="self_hosted_key"
CUSTOM_LLM_ENDPOINT="http://localhost:8000/v1"
CUSTOM_LLM_MODEL_NAME="custom-model"
CUSTOM_LLM_TIMEOUT=60000
CUSTOM_LLM_MAX_TOKENS=2048
CUSTOM_LLM_TEMPERATURE=0.1
```

### 配置备份

```bash
# 备份用户配置
cp -r ~/.gemini ~/.gemini.backup.$(date +%Y%m%d)

# 备份项目配置
tar -czf project-config-backup.tar.gz .gemini/
```

### 性能优化建议

1. **根据API特性调整超时**
   - 快速响应API：15-30秒
   - 标准响应API：30-60秒
   - 慢速响应API：60-120秒

2. **令牌数优化**
   - 简单查询：1024-2048 tokens
   - 标准查询：2048-4096 tokens
   - 复杂查询：4096-8192 tokens

3. **温度参数调整**
   - 代码生成：0.1-0.3
   - 技术文档：0.3-0.7
   - 创意内容：0.7-1.0

4. **定期监控和调整**

   ```bash
   # 定期运行诊断
   ./diagnose-api.sh

   # 监控响应时间
   curl -X POST "$CUSTOM_LLM_ENDPOINT/chat/completions" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
     -d '{"model": "'"$CUSTOM_LLM_MODEL_NAME"'", "messages": [{"role": "user", "content": "test"}], "max_tokens": 5}' \
     --connect-timeout 10 --max-time 30 -w "%{time_total}" -o /dev/null -s
   ```

### 版本控制建议

```bash
# .gitignore
.gemini/.env
.env
*.key
*.secret
diagnose-api.sh
fix-clawcloud-config.sh
```

---

## 故障排除

### 常见错误及解决方案

#### 1. "API key not found" 错误

```bash
# 检查环境变量
echo $GEMINI_API_KEY
echo $CUSTOM_LLM_API_KEY

# 检查 .env 文件是否存在
ls -la .gemini/.env
ls -la ~/.gemini/.env

# 重新加载环境变量
source ~/.bashrc
# 或重新启动终端
```

#### 2. "Invalid API key" 错误

```bash
# 验证 API Key 格式
echo $GEMINI_API_KEY | grep -E "^AIza[0-9A-Za-z_-]{35}$"

# 测试 API 连接
curl -H "Content-Type: application/json" \
  -H "Authorization: Bearer $GEMINI_API_KEY" \
  -d '{"contents":[{"parts":[{"text":"Hello"}]}]}' \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"
```

#### 3. "Authentication failed" 错误

```bash
# 清除缓存
rm -f ~/.gemini/credentials.json
rm -f ~/.gemini/settings.json

# 重新配置
elc
```

#### 4. 自定义 LLM 连接问题

```bash
# 测试连接
curl $CUSTOM_LLM_ENDPOINT/models

# 检查网络连接
ping $(echo $CUSTOM_LLM_ENDPOINT | sed 's|https://||' | sed 's|/.*||')

# 检查代理设置
echo $HTTP_PROXY
echo $HTTPS_PROXY

# 运行诊断脚本
./diagnose-api.sh
```

#### 5. 超时错误

**症状：**

- 请求长时间无响应
- 出现 "timeout" 或 "request timed out" 错误
- API 响应时间超过预期

**解决方案：**

```bash
# 增加超时时间
export CUSTOM_LLM_TIMEOUT=60000  # 60秒

# 减少请求复杂度
export CUSTOM_LLM_MAX_TOKENS=1024

# 降低温度参数以加快响应
export CUSTOM_LLM_TEMPERATURE=0.1

# 测试API响应时间
curl -X POST "$CUSTOM_LLM_ENDPOINT/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
  -d '{
    "model": "'"$CUSTOM_LLM_MODEL_NAME"'",
    "messages": [{"role": "user", "content": "test"}],
    "max_tokens": 5
  }' --connect-timeout 10 --max-time 30
```

#### 6. 空响应或格式错误

**症状：**

- API 返回空内容
- 响应格式不正确
- 出现解析错误

**解决方案：**

```bash
# 验证API端点
curl -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
     "$CUSTOM_LLM_ENDPOINT/models"

# 测试聊天完成端点
curl -X POST "$CUSTOM_LLM_ENDPOINT/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
  -d '{
    "model": "'"$CUSTOM_LLM_MODEL_NAME"'",
    "messages": [{"role": "user", "content": "Hello"}],
    "max_tokens": 10
  }'

# 检查模型名称是否正确
echo "当前模型: $CUSTOM_LLM_MODEL_NAME"
```

### 调试技巧

#### 启用调试模式

```bash
elc --debug
# 或
DEBUG=1 elc
```

#### 检查配置加载顺序

```bash
# 创建测试脚本
cat > check-config.sh << 'EOF'
#!/bin/bash
echo "=== 环境变量 ==="
env | grep -E "(GEMINI|CUSTOM_LLM|USE_CUSTOM)" | sort

echo -e "\n=== 用户设置文件 ==="
cat ~/.gemini/settings.json 2>/dev/null || echo "不存在"

echo -e "\n=== 项目设置文件 ==="
cat .gemini/settings.json 2>/dev/null || echo "不存在"

echo -e "\n=== .env 文件 ==="
echo "用户级 .env:"
cat ~/.gemini/.env 2>/dev/null || echo "不存在"
echo -e "\n项目级 .env:"
cat .gemini/.env 2>/dev/null || echo "不存在"
EOF

chmod +x check-config.sh
./check-config.sh
```

---

## 常见问题解答

### Q: 如何临时使用不同的 API？

**A:** 使用命令行参数或临时环境变量：

```bash
# 临时使用不同的模型
elc --model gpt-4

# 临时使用自定义 LLM
USE_CUSTOM_LLM=true CUSTOM_LLM_MODEL_NAME="claude-3" elc
```

### Q: 如何在多个项目间切换不同的配置？

**A:** 每个项目使用独立的 `.gemini/.env` 文件：

```bash
# 项目 A
cd project-a
echo 'GEMINI_API_KEY="key_a"' > .gemini/.env

# 项目 B
cd project-b
echo 'USE_CUSTOM_LLM=true' > .gemini/.env
echo 'CUSTOM_LLM_API_KEY="key_b"' >> .gemini/.env
```

### Q: 如何撤销认证？

**A:** 删除认证缓存并重新配置：

```bash
# 删除认证缓存
rm -f ~/.gemini/credentials.json

# 删除设置文件（可选）
rm -f ~/.gemini/settings.json

# 重新运行 CLI 进行配置
elc
```

### Q: 如何配置代理？

**A:** 设置标准代理环境变量：

```bash
# HTTP 代理
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"

# 或在 .env 文件中
echo 'HTTP_PROXY="http://proxy.example.com:8080"' >> .gemini/.env
echo 'HTTPS_PROXY="http://proxy.example.com:8080"' >> .gemini/.env
```

### Q: 如何查看当前使用的配置？

**A:** 使用调试模式或检查配置文件：

```bash
# 启动时查看配置信息
elc --debug

# 在 CLI 中使用命令
> /settings
> /model
> /auth
```

### Q: 配置更改后不生效怎么办？

**A:** 按以下步骤排查：

1. **重启 CLI** - 完全退出并重新启动
2. **检查缓存** - 删除 `~/.gemini/credentials.json`
3. **验证环境变量** - 使用 `env | grep GEMINI` 检查
4. **检查文件权限** - 确保 `.env` 文件可读
5. **使用绝对路径** - 确保路径配置正确

---

## 高级配置示例

### 示例1：ClawCloud 自托管模型完整配置

```bash
# .gemini/.env
USE_CUSTOM_LLM=true
CUSTOM_LLM_PROVIDER="openai"
CUSTOM_LLM_API_KEY="sk-wuzhe12345"
CUSTOM_LLM_ENDPOINT="https://rueyfuklmxsq.us-east-1.clawcloudrun.com/v1"
CUSTOM_LLM_MODEL_NAME="gemini-1.5-flash"

# 性能优化参数
CUSTOM_LLM_TIMEOUT=45000  # 45秒超时
CUSTOM_LLM_TEMPERATURE=0.1  # 低温度以提高一致性
CUSTOM_LLM_MAX_TOKENS=8192  # 最大令牌数
CUSTOM_LLM_TOP_P=1.0  # 保守的采样参数

# 快速修复脚本
chmod +x fix-clawcloud-config.sh
./fix-clawcloud-config.sh
```

### 示例2：高延迟环境配置

```bash
# .gemini/.env
USE_CUSTOM_LLM=true
CUSTOM_LLM_PROVIDER="openai"
CUSTOM_LLM_API_KEY="your_api_key"
CUSTOM_LLM_ENDPOINT="https://your-high-latency-api.com/v1"
CUSTOM_LLM_MODEL_NAME="your_model"

# 高延迟环境优化
CUSTOM_LLM_TIMEOUT=120000  # 120秒超时
CUSTOM_LLM_MAX_TOKENS=2048  # 减少令牌数
CUSTOM_LLM_TEMPERATURE=0.1  # 低温度
CUSTOM_LLM_TOP_P=0.9  # 稍微保守的采样

# 网络代理配置
HTTP_PROXY="http://proxy.example.com:8080"
HTTPS_PROXY="http://proxy.example.com:8080"
```

### 示例3：生产环境稳定配置

```bash
# .gemini/.env
USE_CUSTOM_LLM=true
CUSTOM_LLM_PROVIDER="openai"
CUSTOM_LLM_API_KEY="production_api_key"
CUSTOM_LLM_ENDPOINT="https://api.your-company.com/v1"
CUSTOM_LLM_MODEL_NAME="production-model"

# 生产环境优化
CUSTOM_LLM_TIMEOUT=30000  # 标准超时
CUSTOM_LLM_MAX_TOKENS=4096  # 平衡的令牌数
CUSTOM_LLM_TEMPERATURE=0.3  # 适中的创造性
CUSTOM_LLM_TOP_P=0.95  # 标准采样

# 错误处理配置
CUSTOM_LLM_MAX_RETRIES=3  # 最大重试次数
CUSTOM_LLM_RETRY_DELAY=1000  # 重试延迟
```

### 示例4：开发环境快速配置

```bash
# .gemini/.env
USE_CUSTOM_LLM=true
CUSTOM_LLM_PROVIDER="openai"
CUSTOM_LLM_API_KEY="dev_api_key"
CUSTOM_LLM_ENDPOINT="https://api.openai.com/v1"
CUSTOM_LLM_MODEL_NAME="gpt-4"

# 开发环境优化
CUSTOM_LLM_TIMEOUT=15000  # 快速超时
CUSTOM_LLM_MAX_TOKENS=1024  # 快速响应
CUSTOM_LLM_TEMPERATURE=0.7  # 创造性响应
CUSTOM_LLM_TOP_P=1.0  # 最大采样
```

### 示例5：多环境配置管理

```bash
# 创建配置脚本
cat > setup-env.sh << 'EOF'
#!/bin/bash

ENVIRONMENT=${1:-development}

case $ENVIRONMENT in
  "development")
    cp .gemini/.env.development .gemini/.env
    echo "开发环境配置已加载"
    ;;
  "production")
    cp .gemini/.env.production .gemini/.env
    echo "生产环境配置已加载"
    ;;
  "testing")
    cp .gemini/.env.testing .gemini/.env
    echo "测试环境配置已加载"
    ;;
  *)
    echo "未知环境: $ENVIRONMENT"
    exit 1
    ;;
esac

# 验证配置
./diagnose-api.sh
EOF

chmod +x setup-env.sh

# 使用方法
./setup-env.sh development
./setup-env.sh production
./setup-env.sh testing
```

### 配置验证和测试

```bash
# 创建完整的配置验证脚本
cat > validate-config.sh << 'EOF'
#!/bin/bash

echo "=== 配置验证开始 ==="

# 1. 检查环境变量
echo "1. 检查环境变量..."
required_vars=("USE_CUSTOM_LLM" "CUSTOM_LLM_API_KEY" "CUSTOM_LLM_ENDPOINT" "CUSTOM_LLM_MODEL_NAME")
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ $var 未设置"
  else
    echo "✅ $var 已设置"
  fi
done

# 2. 运行诊断
echo -e "\n2. 运行API诊断..."
./diagnose-api.sh

# 3. 测试基本功能
echo -e "\n3. 测试基本功能..."
echo "test query" | elc --debug

echo -e "\n=== 配置验证完成 ==="
EOF

chmod +x validate-config.sh
```

---

## 总结

Easy LLM CLI 提供了灵活的 API 配置管理系统，支持多种认证方式和模型提供商。通过合理使用环境变量、`.env` 文件和设置文件，可以轻松管理不同项目和场景的配置需求。

**关键要点：**

- 使用项目级 `.env` 文件实现项目隔离
- 理解配置优先级，避免配置冲突
- 定期备份重要配置文件
- 妥善保管 API 密钥，避免泄露
- 根据API特性调整超时和性能参数
- 使用诊断工具定期检查API健康状况
- 针对不同环境（开发/测试/生产）优化配置

按照本指南的步骤，您可以轻松配置和管理不同的 API，并根据需要随时切换使用的模型提供商。新增的超时控制、性能优化和诊断功能将帮助您更好地管理自定义 LLM 配置，确保系统的稳定性和可靠性。
