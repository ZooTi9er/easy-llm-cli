/**
 * @license
 * Copyright 2025 Google LLC
 * SPDX-License-Identifier: Apache-2.0
 */

import {
  CountTokensResponse,
  GenerateContentResponse,
  GenerateContentParameters,
  CountTokensParameters,
  EmbedContentResponse,
  EmbedContentParameters,
} from '@google/genai';
import OpenAI from 'openai';
import { ContentGenerator } from '../core/contentGenerator.js';
import { CustomLLMContentGeneratorConfig, ToolCallMap } from './types.js';
import { extractToolFunctions } from './util.js';
import { ModelConverter } from './converter.js';

export class CustomLLMContentGenerator implements ContentGenerator {
  private model: OpenAI;
  private apiKey: string;
  private baseURL: string;
  private modelName: string;
  private temperature: number;
  private maxTokens: number;
  private topP: number;
  private timeout: number;
  private config: CustomLLMContentGeneratorConfig;

  constructor() {
    // 尝试从配置验证模块读取配置
    let config = null;
    try {
      const configModule = require('../config/index.js');
      config = configModule.default;
    } catch (error) {
      // 如果配置模块加载失败，使用环境变量
      console.log('[CustomLLM] Config module not found, falling back to environment variables');
    }

    // 从配置模块或环境变量读取配置
    this.apiKey = config?.CUSTOM_LLM_API_KEY || process.env.CUSTOM_LLM_API_KEY || '';
    this.baseURL = config?.CUSTOM_LLM_ENDPOINT || process.env.CUSTOM_LLM_ENDPOINT || '';
    this.modelName = config?.CUSTOM_LLM_MODEL_NAME || process.env.CUSTOM_LLM_MODEL_NAME || '';
    this.temperature = Number(config?.CUSTOM_LLM_TEMPERATURE || process.env.CUSTOM_LLM_TEMPERATURE || 0.1);
    this.maxTokens = Number(config?.CUSTOM_LLM_MAX_TOKENS || process.env.CUSTOM_LLM_MAX_TOKENS || 8192);
    this.topP = Number(config?.CUSTOM_LLM_TOP_P || process.env.CUSTOM_LLM_TOP_P || 1);
    this.timeout = Number(config?.CUSTOM_LLM_TIMEOUT || process.env.CUSTOM_LLM_TIMEOUT || 30000);
    
    this.config = {
      model: this.modelName,
      temperature: this.temperature,
      max_tokens: this.maxTokens,
      top_p: this.topP,
    };

    // 调试信息
    console.log('[CustomLLM] Configuration:', {
      baseURL: this.baseURL ? '[REDACTED]' : undefined,
      modelName: this.modelName,
      temperature: this.temperature,
      maxTokens: this.maxTokens,
      topP: this.topP,
      timeout: this.timeout,
    });

    this.model = new OpenAI({
      apiKey: this.apiKey,
      baseURL: this.baseURL,
      timeout: this.timeout,
    });
  }

  /**
   * Asynchronously generates content responses in a streaming fashion.
   * This method converts the input request to OpenAI format, invokes the model API,
   * and returns an asynchronous generator for real-time processing and streaming of responses.
   * It supports tool calls and uses a ToolCallMap to track tool invocation states.
   * @param request - Parameters for generating content, including prompts and configuration.
   * @returns An asynchronous generator that yields GenerateContentResponse objects
   *          until the stream ends or ter mination conditions are met.
   * @remarks This method is ideal for scenarios requiring real-time interaction, such as chat interfaces
   * or interactive applications. Stream responses are processed incrementally via ModelConverter.
   */
  async generateContentStream(
    request: GenerateContentParameters,
  ): Promise<AsyncGenerator<GenerateContentResponse>> {
    const messages = ModelConverter.toOpenAIMessages(request);
    const tools = extractToolFunctions(request.config) || [];

    try {
      const stream = await this.model.chat.completions.create({
        messages,
        stream: true,
        tools,
        stream_options: { include_usage: true },
        ...this.config,
      });
      const map: ToolCallMap = new Map();
      return (async function* (): AsyncGenerator<GenerateContentResponse> {
        for await (const chunk of stream) {
          const { response, shouldReturn } = ModelConverter.processStreamChunk(
            chunk,
            map,
          );
          if (response) {
            yield response;
          }
          if (shouldReturn) {
            return;
          }
        }
      })();
    } catch (error) {
      // Handle timeout and other errors gracefully
      console.error('Error in generateContentStream:', error);
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error occurred';
      const errorResponse = new GenerateContentResponse();
      errorResponse.candidates = [
        {
          content: {
            parts: [
              {
                text: `I apologize, but I encountered an error: ${errorMessage}. Please check your API configuration and try again.`,
              },
            ],
            role: 'model',
          },
          index: 0,
          safetyRatings: [],
        },
      ];
      return (async function* (): AsyncGenerator<GenerateContentResponse> {
        yield errorResponse;
      })();
    }
  }

  /**
   * Asynchronously generates a complete content response.
   * This method converts the input request to OpenAI format, invokes the model API,
   * and waits for the full response before converting it to the Gemini API format.
   * @param request - Parameters for generating content, including prompts and configuration.
   * @returns A promise resolving to a complete GenerateContentResponse object.
   * @remarks This method is suitable for scenarios requiring the entire response at once,
   * such as batch processing or non-interactive applications.
   */
  async generateContent(
    request: GenerateContentParameters,
  ): Promise<GenerateContentResponse> {
    const messages = ModelConverter.toOpenAIMessages(request);

    try {
      const completion = await this.model.chat.completions.create({
        messages,
        stream: false,
        ...this.config,
      });

      return ModelConverter.toGeminiResponse(completion);
    } catch (error) {
      // Handle timeout and other errors gracefully
      console.error('Error in generateContent:', error);
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error occurred';
      const errorResponse = new GenerateContentResponse();
      errorResponse.candidates = [
        {
          content: {
            parts: [
              {
                text: `I apologize, but I encountered an error: ${errorMessage}. Please check your API configuration and try again.`,
              },
            ],
            role: 'model',
          },
          index: 0,
          safetyRatings: [],
        },
      ];
      return errorResponse;
    }
  }

  /**
   * Counts the total number of tokens in the given request contents.
   * This function approximates token count by analyzing different types of content
   * (English words, Chinese characters, numbers, punctuations, and spaces)
   * and applying different weighting factors to each type.
   */
  async countTokens(
    request: CountTokensParameters,
  ): Promise<CountTokensResponse> {
    const messages = ModelConverter.toOpenAIMessages(request);
    const text = messages.map((m) => m.content).join(' ');
    const englishWords = (text.match(/[a-zA-Z]+[']?[a-zA-Z]*/g) || []).length;
    const chineseChars = (text.match(/[\u4e00-\u9fff]/g) || []).length;
    const numbers = (text.match(/\b\d+\b/g) || []).length;
    const punctuations = (
      text.match(/[.,!?;:"'(){}[\]<>@#$%^&*\-_+=~`|\\/]/g) || []
    ).length;
    const spaces = Math.ceil((text.match(/\s+/g) || []).length / 5);
    const totalTokens = Math.ceil(
      englishWords * 1.2 +
        chineseChars * 1 +
        numbers * 0.8 +
        punctuations * 0.5 +
        spaces,
    );
    return {
      totalTokens,
    };
  }

  /**
   * This function has not been implemented yet.
   */
  async embedContent(
    _request: EmbedContentParameters,
  ): Promise<EmbedContentResponse> {
    throw Error();
  }

  /**
   * Validate API connectivity and model compatibility
   */
  async validateApi(): Promise<{ valid: boolean; error?: string }> {
    try {
      // Test basic connectivity
      const modelsResponse = await fetch(`${this.baseURL}/models`, {
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
        },
        signal: AbortSignal.timeout(10000), // 10 second timeout
      });

      if (!modelsResponse.ok) {
        return {
          valid: false,
          error: `API connectivity failed: ${modelsResponse.status}`,
        };
      }

      // Test chat completion with minimal request
      const testResponse = await this.model.chat.completions.create(
        {
          model: this.modelName,
          messages: [{ role: 'user', content: 'test' }],
          max_tokens: 5,
          temperature: 0.1,
        },
        {
          timeout: 15000, // 15 second timeout
        },
      );

      if (!testResponse.choices || testResponse.choices.length === 0) {
        return { valid: false, error: 'API returned empty response' };
      }

      return { valid: true };
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : 'Unknown error occurred';
      return { valid: false, error: errorMessage };
    }
  }
}
