# 自定义 API 配置问题修复项目任务分解文档 (task.md)

## 项目概述

本文档详细分解了修复 easy-llm-cli 自定义 API 配置问题的具体任务，基于需求分析文档 (api-prd.txt) 中的解决方案设计。

## 任务分解总览

### 任务统计
- **总任务数**: 6个
- **高优先级**: 4个
- **中优先级**: 1个
- **低优先级**: 1个
- **预估总时间**: 3.5-4小时

### 任务优先级定义
- **高优先级**: 立即执行，影响核心功能
- **中优先级**: 核心功能修复后执行
- **低优先级**: 优化和文档，不影响核心功能

## 详细任务分解

### 任务 1: 修改入口点文件

**任务ID**: API-FIX-001  
**优先级**: 高  
**预估时间**: 0.5小时  
**依赖任务**: 无  

#### 任务描述
在 `packages/cli/index.ts` 中添加 `dotenv.config()` 调用，确保 `.env` 文件在应用启动时被正确加载。

#### 具体步骤
1. 在 `packages/cli/index.ts` 顶部添加 dotenv 导入
2. 添加 `dotenv.config()` 调用，指定正确的 `.env` 文件路径
3. 添加调试日志验证配置加载
4. 确保在导入其他模块之前加载配置

#### 详细操作
```typescript
// packages/cli/index.ts
#!/usr/bin/env node

/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */

import * as dotenv from 'dotenv';
import * as path from 'path';

// 加载 .env 文件
const pathToEnv = path.resolve(__dirname, '.gemini/.env');
dotenv.config({ path: pathToEnv, override: true });

// 调试日志
console.log(`[DEBUG] Loading .env from: ${pathToEnv}`);
console.log(`[DEBUG] USE_CUSTOM_LLM: ${process.env.USE_CUSTOM_LLM}`);
console.log(`[DEBUG] CUSTOM_LLM_MODEL_NAME: ${process.env.CUSTOM_LLM_MODEL_NAME}`);

import './src/gemini.js';
import { main } from './src/gemini.js';

// --- Global Entry Point ---
main().catch((error) => {
  console.error('An unexpected critical error occurred:');
  if (error instanceof Error) {
    console.error(error.stack);
  } else {
    console.error(String(error));
  }
  process.exit(1);
});
```

#### 预期输出
- `.env` 文件在应用启动时被加载
- 调试日志显示配置值
- 环境变量正确设置到 `process.env`

#### 成功标准
- ✅ `dotenv.config()` 成功执行
- ✅ 环境变量被正确加载
- ✅ 调试日志显示预期配置值

#### 风险评估
- **风险**: 路径解析错误
- **应对**: 使用 `path.resolve()` 确保路径正确，添加路径验证

---

### 任务 2: 创建配置验证模块

**任务ID**: API-FIX-002  
**优先级**: 高  
**预估时间**: 1小时  
**依赖任务**: API-FIX-001  

#### 任务描述
在 `packages/core/src/config/` 中创建配置验证模块，使用 Zod 进行配置类型验证和提供默认值。

#### 具体步骤
1. 检查并安装 `zod` 依赖
2. 创建 `packages/core/src/config/index.ts` 文件
3. 实现配置验证和类型定义
4. 提供配置对象和类型导出

#### 详细操作
```typescript
// packages/core/src/config/index.ts
import { z } from 'zod';

// 定义环境变量 schema
const envSchema = z.object({
  USE_CUSTOM_LLM: z.preprocess(
    (val) => String(val).toLowerCase() === 'true',
    z.boolean()
  ).default(false),
  CUSTOM_LLM_PROVIDER: z.string().optional(),
  CUSTOM_LLM_API_KEY: z.string().optional(),
  CUSTOM_LLM_ENDPOINT: z.string().url().optional(),
  CUSTOM_LLM_MODEL_NAME: z.string().optional(),
  CUSTOM_LLM_TEMPERATURE: z.number().min(0).max(2).optional(),
  CUSTOM_LLM_MAX_TOKENS: z.number().min(1).optional(),
  CUSTOM_LLM_TOP_P: z.number().min(0).max(1).optional(),
  CUSTOM_LLM_TIMEOUT: z.number().min(1000).optional(),
});

// 解析和验证环境变量
const parsedEnv = envSchema.safeParse(process.env);

if (!parsedEnv.success) {
  console.error('ERROR: Invalid environment variables:');
  parsedEnv.error.errors.forEach(err => 
    console.error(`  - ${err.path.join('.')}: ${err.message}`)
  );
  throw new Error('Invalid configuration');
}

const config = parsedEnv.data;

// 条件验证
if (config.USE_CUSTOM_LLM && !config.CUSTOM_LLM_MODEL_NAME) {
  console.warn('WARNING: USE_CUSTOM_LLM is true but CUSTOM_LLM_MODEL_NAME is not set');
}

export type AppConfig = z.infer<typeof envSchema>;
export default config;
```

#### 预期输出
- 类型安全的配置对象
- 配置验证和错误提示
- 条件验证和警告

#### 成功标准
- ✅ 配置验证模块正常工作
- ✅ 类型定义正确
- ✅ 验证逻辑合理

#### 风险评估
- **风险**: zod 依赖缺失
- **应对**: 检查并安装 zod 包

---

### 任务 3: 更新配置读取逻辑

**任务ID**: API-FIX-003  
**优先级**: 高  
**预估时间**: 1小时  
**依赖任务**: API-FIX-002  

#### 任务描述
更新 `packages/core/src/config/config.ts` 和 `packages/core/src/custom_llm/index.ts` 中的配置读取逻辑，使用新的配置验证模块。

#### 具体步骤
1. 修改 `packages/core/src/config/config.ts` 中的 `getModel()` 方法
2. 更新 `packages/core/src/custom_llm/index.ts` 中的配置读取
3. 确保使用验证后的配置对象
4. 添加错误处理和默认值

#### 详细操作
```typescript
// 在 packages/core/src/config/config.ts 中
import appConfig from './index'; // 导入配置模块

getModel(): string {
  if (appConfig.USE_CUSTOM_LLM) {
    return appConfig.CUSTOM_LLM_MODEL_NAME || this.model;
  }
  return this.contentGeneratorConfig?.model || this.model;
}

// 在 packages/core/src/custom_llm/index.ts 中
import appConfig from '../config';

export class CustomLLMContentGenerator implements ContentGenerator {
  private model: OpenAI;
  private apiKey: string = appConfig.CUSTOM_LLM_API_KEY || '';
  private baseURL: string = appConfig.CUSTOM_LLM_ENDPOINT || '';
  private modelName: string = appConfig.CUSTOM_LLM_MODEL_NAME || '';
  private temperature: number = appConfig.CUSTOM_LLM_TEMPERATURE || 0;
  private maxTokens: number = appConfig.CUSTOM_LLM_MAX_TOKENS || 8192;
  private topP: number = appConfig.CUSTOM_LLM_TOP_P || 1;
  private timeout: number = appConfig.CUSTOM_LLM_TIMEOUT || 30000;
  
  constructor() {
    this.model = new OpenAI({
      apiKey: this.apiKey,
      baseURL: this.baseURL,
      timeout: this.timeout,
    });
  }
}
```

#### 预期输出
- 使用验证后的配置对象
- 改进的错误处理
- 类型安全的配置访问

#### 成功标准
- ✅ 配置读取逻辑更新完成
- ✅ 类型安全得到保证
- ✅ 错误处理合理

#### 风险评估
- **风险**: 配置对象导入错误
- **应对**: 仔细检查导入路径和模块结构

---

### 任务 4: 测试配置加载

**任务ID**: API-FIX-004  
**优先级**: 高  
**预估时间**: 0.5小时  
**依赖任务**: API-FIX-003  

#### 任务描述
验证 `.env` 文件正确加载，测试自定义 API 功能是否使用正确的配置。

#### 具体步骤
1. 运行应用并观察启动日志
2. 检查环境变量是否正确加载
3. 测试自定义 API 功能
4. 验证 API 调用使用正确的端点

#### 详细操作
```bash
# 1. 构建项目
npm run build

# 2. 运行测试命令
npm run start -- -p "What is 2+2? Please answer with just the number."

# 3. 检查调试日志
# 观察是否显示正确的配置值

# 4. 验证 API 调用
# 确认响应来自自定义 API 端点
```

#### 预期输出
- 应用启动时显示配置加载日志
- 自定义 API 功能正常工作
- API 调用使用正确的配置

#### 成功标准
- ✅ 配置加载日志正确显示
- ✅ 自定义 API 功能正常
- ✅ API 调用使用配置的端点

#### 风险评估
- **风险**: 配置仍然未正确加载
- **应对**: 检查路径和 dotenv 配置

---

### 任务 5: 添加调试和验证机制

**任务ID**: API-FIX-005  
**优先级**: 中  
**预估时间**: 0.5小时  
**依赖任务**: API-FIX-004  

#### 任务描述
实现配置状态检查和详细调试信息，帮助用户诊断配置问题。

#### 具体步骤
1. 创建配置状态检查函数
2. 添加详细的调试信息
3. 实现配置验证命令
4. 提供用户友好的错误提示

#### 详细操作
```typescript
// 在配置模块中添加调试函数
export function getConfigStatus() {
  return {
    useCustomLLM: appConfig.USE_CUSTOM_LLM,
    model: appConfig.CUSTOM_LLM_MODEL_NAME,
    endpoint: appConfig.CUSTOM_LLM_ENDPOINT,
    provider: appConfig.CUSTOM_LLM_PROVIDER,
    configLoaded: Object.keys(process.env).filter(key => key.startsWith('CUSTOM_LLM_')),
  };
}

// 在应用启动时显示配置状态
console.log('[CONFIG] Current configuration:', getConfigStatus());
```

#### 预期输出
- 详细的配置状态信息
- 用户友好的错误提示
- 调试和诊断工具

#### 成功标准
- ✅ 调试机制正常工作
- ✅ 配置状态信息完整
- ✅ 错误提示清晰易懂

#### 风险评估
- **风险**: 调试信息过于冗长
- **应对**: 提供简洁和详细的两种模式

---

### 任务 6: 文档和总结

**任务ID**: API-FIX-006  
**优先级**: 低  
**预估时间**: 0.5小时  
**依赖任务**: API-FIX-005  

#### 任务描述
更新项目文档，创建修复总结报告，记录解决方案和最佳实践。

#### 具体步骤
1. 更新项目 README 和配置文档
2. 创建修复总结报告
3. 记录解决方案和最佳实践
4. 提供故障排除指南

#### 详细操作
```bash
# 创建文档
# 1. 更新配置文档
# 2. 创建故障排除指南
# 3. 记录修复过程
# 4. 提供最佳实践建议
```

#### 预期输出
- 完整的项目文档
- 修复总结报告
- 故障排除指南
- 最佳实践建议

#### 成功标准
- ✅ 文档完整准确
- ✅ 修复过程记录详细
- ✅ 最佳实践实用

#### 风险评估
- **风险**: 文档信息不完整
- **应对**: 多次审查和更新

## 任务依赖关系图

```
API-FIX-001 (入口点修改) → API-FIX-002 (配置验证) → API-FIX-003 (配置读取更新) → API-FIX-004 (测试) → API-FIX-005 (调试机制) → API-FIX-006 (文档)
```

## 关键里程碑

### 里程碑 1: 配置加载修复 (API-FIX-001)
- **时间**: 0.5小时
- **标志**: .env 文件正确加载
- **验证**: 调试日志显示配置值

### 里程碑 2: 配置验证实现 (API-FIX-002)
- **时间**: 1.5小时
- **标志**: 配置验证模块完成
- **验证**: 类型安全和验证逻辑正常

### 里程碑 3: 功能修复完成 (API-FIX-003 + API-FIX-004)
- **时间**: 3小时
- **标志**: 自定义 API 功能正常
- **验证**: API 调用使用正确配置

### 里程碑 4: 项目完成 (API-FIX-005 + API-FIX-006)
- **时间**: 4小时
- **标志**: 调试机制和文档完成
- **验证**: 所有功能正常，文档完整

## 质量保证措施

### 每个任务的质量检查
1. **代码质量**: 确保代码符合项目规范
2. **类型安全**: 验证 TypeScript 类型正确
3. **功能测试**: 每个功能都要经过测试
4. **错误处理**: 确保错误处理合理

### 整体质量保证
1. **回归测试**: 确保修复不引入新问题
2. **用户体验**: 确保解决方案用户友好
3. **文档质量**: 确保文档清晰完整
4. **代码维护**: 确保代码易于维护

## 风险管理

### 主要风险
1. **技术风险**: 配置加载机制复杂
2. **时间风险**: 实际修复时间可能超出预估
3. **质量风险**: 修复可能影响其他功能
4. **兼容性风险**: 可能与现有配置不兼容

### 风险应对策略
1. **渐进式修复**: 从最基本的问题开始
2. **充分测试**: 每个步骤后都进行验证
3. **详细记录**: 保持详细的过程记录
4. **备份方案**: 保留原始文件的备份

---

**文档创建时间**: 2025-09-05  
**文档版本**: v1.0  
**创建者**: Claude AI Assistant  
**项目状态**: 待开始