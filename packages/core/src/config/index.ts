/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */

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

if (config.USE_CUSTOM_LLM && !config.CUSTOM_LLM_ENDPOINT) {
  console.warn('WARNING: USE_CUSTOM_LLM is true but CUSTOM_LLM_ENDPOINT is not set');
}

if (config.USE_CUSTOM_LLM && !config.CUSTOM_LLM_API_KEY) {
  console.warn('WARNING: USE_CUSTOM_LLM is true but CUSTOM_LLM_API_KEY is not set');
}

// 调试信息
console.log('[CONFIG] Configuration loaded:', {
  USE_CUSTOM_LLM: config.USE_CUSTOM_LLM,
  CUSTOM_LLM_PROVIDER: config.CUSTOM_LLM_PROVIDER,
  CUSTOM_LLM_MODEL_NAME: config.CUSTOM_LLM_MODEL_NAME,
  CUSTOM_LLM_ENDPOINT: config.CUSTOM_LLM_ENDPOINT ? '[REDACTED]' : undefined,
  CUSTOM_LLM_TEMPERATURE: config.CUSTOM_LLM_TEMPERATURE,
  CUSTOM_LLM_MAX_TOKENS: config.CUSTOM_LLM_MAX_TOKENS,
  CUSTOM_LLM_TOP_P: config.CUSTOM_LLM_TOP_P,
  CUSTOM_LLM_TIMEOUT: config.CUSTOM_LLM_TIMEOUT,
});

export type AppConfig = z.infer<typeof envSchema>;
export default config;

// 导出配置状态检查函数
export function getConfigStatus() {
  return {
    useCustomLLM: config.USE_CUSTOM_LLM,
    provider: config.CUSTOM_LLM_PROVIDER,
    model: config.CUSTOM_LLM_MODEL_NAME,
    endpoint: config.CUSTOM_LLM_ENDPOINT ? '[REDACTED]' : undefined,
    temperature: config.CUSTOM_LLM_TEMPERATURE,
    maxTokens: config.CUSTOM_LLM_MAX_TOKENS,
    topP: config.CUSTOM_LLM_TOP_P,
    timeout: config.CUSTOM_LLM_TIMEOUT,
    configLoaded: Object.keys(process.env).filter(key => key.startsWith('CUSTOM_LLM_')),
  };
}