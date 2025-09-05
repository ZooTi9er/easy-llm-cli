#!/bin/bash

# Easy LLM CLI 配置验证脚本
# 用于验证自定义 LLM API 配置是否正确

echo "=== Easy LLM CLI 配置验证 ==="
echo

# 检查关键环境变量
echo "1. 环境变量检查："
echo "   USE_CUSTOM_LLM: ${USE_CUSTOM_LLM:-'未设置'}"
echo "   CUSTOM_LLM_PROVIDER: ${CUSTOM_LLM_PROVIDER:-'未设置'}"
echo "   CUSTOM_LLM_API_KEY: ${CUSTOM_LLM_API_KEY:+'已设置'}"
echo "   CUSTOM_LLM_ENDPOINT: ${CUSTOM_LLM_ENDPOINT:-'未设置'}"
echo "   CUSTOM_LLM_MODEL_NAME: ${CUSTOM_LLM_MODEL_NAME:-'未设置'}"
echo "   CUSTOM_LLM_TEMPERATURE: ${CUSTOM_LLM_TEMPERATURE:-'未设置 (默认0)'}"
echo "   CUSTOM_LLM_MAX_TOKENS: ${CUSTOM_LLM_MAX_TOKENS:-'未设置 (默认8192)'}"
echo "   CUSTOM_LLM_TOP_P: ${CUSTOM_LLM_TOP_P:-'未设置 (默认1)'}"
echo

# 检查设置文件
echo "2. 设置文件检查："

# 用户级设置
if [ -f ~/.gemini/settings.json ]; then
    echo "   用户设置文件: ~/.gemini/settings.json"
    selected_auth_type=$(grep -o '"selectedAuthType": "[^"]*"' ~/.gemini/settings.json | cut -d'"' -f4)
    echo "   认证类型: $selected_auth_type"
else
    echo "   用户设置文件: 不存在"
fi

# 项目级设置
if [ -f .gemini/settings.json ]; then
    echo "   项目设置文件: .gemini/settings.json"
    selected_auth_type=$(grep -o '"selectedAuthType": "[^"]*"' .gemini/settings.json | cut -d'"' -f4)
    echo "   认证类型: $selected_auth_type"
else
    echo "   项目设置文件: 不存在"
fi
echo

# 检查 .env 文件
echo "3. .env 文件检查："

# 检查项目级 .env 文件
if [ -f .gemini/.env ]; then
    echo "   项目级 .env 文件: .gemini/.env"
    echo "   内容："
    cat .gemini/.env | grep -E "(USE_CUSTOM_LLM|CUSTOM_LLM)" | sed 's/^/     /'
else
    echo "   项目级 .env 文件: 不存在"
fi

# 检查用户级 .env 文件
if [ -f ~/.gemini/.env ]; then
    echo "   用户级 .env 文件: ~/.gemini/.env"
    echo "   内容："
    cat ~/.gemini/.env | grep -E "(USE_CUSTOM_LLM|CUSTOM_LLM)" | sed 's/^/     /'
else
    echo "   用户级 .env 文件: 不存在"
fi
echo

# 配置验证
echo "4. 配置验证："

if [ "$USE_CUSTOM_LLM" = "true" ]; then
    echo "   ✓ USE_CUSTOM_LLM 已启用"
    
    if [ -n "$CUSTOM_LLM_API_KEY" ]; then
        echo "   ✓ API 密钥已设置"
    else
        echo "   ✗ API 密钥未设置"
    fi
    
    if [ -n "$CUSTOM_LLM_ENDPOINT" ]; then
        echo "   ✓ API 端点已设置: $CUSTOM_LLM_ENDPOINT"
    else
        echo "   ✗ API 端点未设置"
    fi
    
    if [ -n "$CUSTOM_LLM_MODEL_NAME" ]; then
        echo "   ✓ 模型名称已设置: $CUSTOM_LLM_MODEL_NAME"
    else
        echo "   ✗ 模型名称未设置"
    fi
    
    if [ -n "$CUSTOM_LLM_PROVIDER" ]; then
        echo "   ✓ 提供商已设置: $CUSTOM_LLM_PROVIDER"
    else
        echo "   ✗ 提供商未设置"
    fi
else
    echo "   ✗ USE_CUSTOM_LLM 未启用 - 自定义 LLM 将不会使用"
fi
echo

# API 连接测试
echo "5. API 连接测试："

if [ -n "$CUSTOM_LLM_ENDPOINT" ] && [ -n "$CUSTOM_LLM_API_KEY" ]; then
    echo "   测试连接到: $CUSTOM_LLM_ENDPOINT"
    
    # 测试基本连接
    if command -v curl &> /dev/null; then
        # 测试 models 端点
        response=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
            -H "Content-Type: application/json" \
            "$CUSTOM_LLM_ENDPOINT/models" 2>/dev/null)
        
        if [ "$response" = "200" ]; then
            echo "   ✓ API 连接成功"
        elif [ "$response" = "401" ]; then
            echo "   ✗ API 认证失败 (401)"
        elif [ "$response" = "404" ]; then
            echo "   ⚠ API 端点可能不支持 models 路由 (404)"
        else
            echo "   ⚠ API 连接状态: $response"
        fi
        
        # 测试聊天完成端点
        echo "   测试聊天完成端点..."
        chat_response=$(curl -s -X POST \
            -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
            -H "Content-Type: application/json" \
            -d '{
                "model": "'"$CUSTOM_LLM_MODEL_NAME"'",
                "messages": [{"role": "user", "content": "Hello"}],
                "max_tokens": 10
            }' \
            "$CUSTOM_LLM_ENDPOINT/chat/completions" 2>/dev/null)
        
        if echo "$chat_response" | grep -q '"choices"'; then
            echo "   ✓ 聊天完成端点正常"
        else
            echo "   ✗ 聊天完成端点异常"
            echo "   响应: $chat_response"
        fi
    else
        echo "   ⚠ curl 未安装，跳过连接测试"
    fi
else
    echo "   ⚠ 缺少必要的配置，跳过连接测试"
fi
echo

# 建议和解决方案
echo "6. 建议和解决方案："

if [ "$USE_CUSTOM_LLM" != "true" ]; then
    echo "   • 设置 USE_CUSTOM_LLM=true 启用自定义 LLM"
fi

if [ -z "$CUSTOM_LLM_API_KEY" ]; then
    echo "   • 设置 CUSTOM_LLM_API_KEY 为您的 API 密钥"
fi

if [ -z "$CUSTOM_LLM_ENDPOINT" ]; then
    echo "   • 设置 CUSTOM_LLM_ENDPOINT 为您的 API 端点"
fi

if [ -z "$CUSTOM_LLM_MODEL_NAME" ]; then
    echo "   • 设置 CUSTOM_LLM_MODEL_NAME 为您的模型名称"
fi

if [ -z "$CUSTOM_LLM_PROVIDER" ]; then
    echo "   • 设置 CUSTOM_LLM_PROVIDER 为 'openai' 或其他提供商"
fi

echo "   • 使用 'elc --debug' 启动调试模式"
echo "   • 检查 ~/.gemini/settings.json 中的认证类型设置"
echo "   • 确保所有环境变量在启动 elc 前已设置"

echo
echo "=== 验证完成 ==="