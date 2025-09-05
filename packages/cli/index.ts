#!/usr/bin/env node

/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */

import * as dotenv from 'dotenv';
import * as path from 'path';
import { fileURLToPath } from 'url';

// ES module 兼容的 __dirname
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 加载 .env 文件
const pathToEnv = path.resolve(__dirname, '.gemini/.env');
dotenv.config({ path: pathToEnv, override: true });

// 调试日志
console.log(`[DEBUG] Loading .env from: ${pathToEnv}`);
console.log(`[DEBUG] USE_CUSTOM_LLM: ${process.env.USE_CUSTOM_LLM}`);
console.log(`[DEBUG] CUSTOM_LLM_MODEL_NAME: ${process.env.CUSTOM_LLM_MODEL_NAME}`);
console.log(`[DEBUG] CUSTOM_LLM_ENDPOINT: ${process.env.CUSTOM_LLM_ENDPOINT}`);

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
