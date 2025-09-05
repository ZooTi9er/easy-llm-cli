#!/usr/bin/env node

/**
 * 配置验证工具
 * 用于验证自定义 API 配置是否正确加载
 */

import * as dotenv from 'dotenv';
import * as path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

// ES module 兼容的 __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 加载 .env 文件
const pathToEnv = path.resolve(__dirname, '../.gemini/.env');
dotenv.config({ path: pathToEnv, override: true });

console.log('=== Easy LLM CLI 配置验证 ===\n');

// 检查关键配置项
const configChecks = [
  { key: 'USE_CUSTOM_LLM', required: true, description: '是否使用自定义 LLM' },
  { key: 'CUSTOM_LLM_MODEL_NAME', required: true, description: '自定义 LLM 模型名称' },
  { key: 'CUSTOM_LLM_ENDPOINT', required: true, description: '自定义 LLM API 端点' },
  { key: 'CUSTOM_LLM_API_KEY', required: true, description: '自定义 LLM API 密钥' },
  { key: 'CUSTOM_LLM_PROVIDER', required: false, description: '自定义 LLM 提供商' },
  { key: 'CUSTOM_LLM_TEMPERATURE', required: false, description: '温度参数' },
  { key: 'CUSTOM_LLM_MAX_TOKENS', required: false, description: '最大令牌数' },
  { key: 'CUSTOM_LLM_TOP_P', required: false, description: 'Top-P 参数' },
  { key: 'CUSTOM_LLM_TIMEOUT', required: false, description: '超时时间' },
];

let allPassed = true;
let customLlmEnabled = false;

console.log('📋 配置项检查:');
console.log('─'.repeat(50));

configChecks.forEach(check => {
  const value = process.env[check.key];
  const isSet = value !== undefined && value !== '';
  const isRequiredAndMissing = check.required && !isSet;
  
  if (isRequiredAndMissing) {
    console.log(`❌ ${check.key}: 未设置 (${check.description})`);
    allPassed = false;
  } else if (isSet) {
    console.log(`✅ ${check.key}: ${check.key.includes('API_KEY') || check.key.includes('ENDPOINT') ? '[已设置]' : value}`);
    if (check.key === 'USE_CUSTOM_LLM' && value === 'true') {
      customLlmEnabled = true;
    }
  } else {
    console.log(`⚠️  ${check.key}: 未设置 (可选) (${check.description})`);
  }
});

console.log('\n📊 配置状态总结:');
console.log('─'.repeat(30));

if (customLlmEnabled) {
  console.log('✅ 自定义 LLM 模式已启用');
  
  // 检查必需的自定义 LLM 配置
  const requiredCustomConfig = ['CUSTOM_LLM_MODEL_NAME', 'CUSTOM_LLM_ENDPOINT', 'CUSTOM_LLM_API_KEY'];
  const missingCustomConfig = requiredCustomConfig.filter(key => !process.env[key]);
  
  if (missingCustomConfig.length === 0) {
    console.log('✅ 所有必需的自定义 LLM 配置项已设置');
  } else {
    console.log(`❌ 缺少必需的自定义 LLM 配置: ${missingCustomConfig.join(', ')}`);
    allPassed = false;
  }
} else {
  console.log('ℹ️  使用默认 Gemini 模式');
}

console.log('\n🔍 详细配置信息:');
console.log('─'.repeat(30));
console.log(`配置文件路径: ${pathToEnv}`);
console.log(`配置文件存在: ${fs.existsSync(pathToEnv) ? '是' : '否'}`);

if (fs.existsSync(pathToEnv)) {
  try {
    const envContent = fs.readFileSync(pathToEnv, 'utf8');
    const lines = envContent.split('\n').filter(line => line.trim() && !line.startsWith('#'));
    console.log(`配置项数量: ${lines.length}`);
  } catch (error) {
    console.log(`⚠️  无法读取配置文件: ${error.message}`);
  }
}

console.log('\n🎯 验证结果:');
console.log('─'.repeat(20));

if (allPassed) {
  console.log('✅ 所有配置检查通过！');
  if (customLlmEnabled) {
    console.log('🚀 自定义 API 配置已就绪，可以正常使用');
  } else {
    console.log('🔧 将使用默认 Gemini API');
  }
  process.exit(0);
} else {
  console.log('❌ 配置检查失败，请检查上述问题');
  process.exit(1);
}