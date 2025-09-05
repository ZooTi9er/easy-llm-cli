#!/bin/bash

# Easy LLM CLI API 诊断工具
# 用于诊断自定义 API 配置和连接问题

echo "=== Easy LLM CLI API 诊断工具 ==="
echo

# 检查是否在正确的目录
if [ ! -f "packages/cli/src/gemini.tsx" ]; then
    echo "错误：请在 Easy LLM CLI 项目根目录运行此脚本"
    exit 1
fi

# 检查环境变量
echo "1. 环境变量检查："
echo "   USE_CUSTOM_LLM: ${USE_CUSTOM_LLM:-'未设置'}"
echo "   CUSTOM_LLM_PROVIDER: ${CUSTOM_LLM_PROVIDER:-'未设置'}"
echo "   CUSTOM_LLM_API_KEY: ${CUSTOM_LLM_API_KEY:+'已设置'}"
echo "   CUSTOM_LLM_ENDPOINT: ${CUSTOM_LLM_ENDPOINT:-'未设置'}"
echo "   CUSTOM_LLM_MODEL_NAME: ${CUSTOM_LLM_MODEL_NAME:-'未设置'}"
echo "   CUSTOM_LLM_TEMPERATURE: ${CUSTOM_LLM_TEMPERATURE:-'未设置 (默认0)'}"
echo "   CUSTOM_LLM_MAX_TOKENS: ${CUSTOM_LLM_MAX_TOKENS:-'未设置 (默认8192)'}"
echo "   CUSTOM_LLM_TOP_P: ${CUSTOM_LLM_TOP_P:-'未设置 (默认1)'}"
echo "   CUSTOM_LLM_TIMEOUT: ${CUSTOM_LLM_TIMEOUT:-'未设置 (默认30000ms)'}"
echo

# 验证必需的环境变量
errors=0
if [ "$USE_CUSTOM_LLM" != "true" ]; then
    echo "   ❌ USE_CUSTOM_LLM 未设置为 true"
    errors=$((errors + 1))
fi

if [ -z "$CUSTOM_LLM_API_KEY" ]; then
    echo "   ❌ CUSTOM_LLM_API_KEY 未设置"
    errors=$((errors + 1))
fi

if [ -z "$CUSTOM_LLM_ENDPOINT" ]; then
    echo "   ❌ CUSTOM_LLM_ENDPOINT 未设置"
    errors=$((errors + 1))
fi

if [ -z "$CUSTOM_LLM_MODEL_NAME" ]; then
    echo "   ❌ CUSTOM_LLM_MODEL_NAME 未设置"
    errors=$((errors + 1))
fi

if [ $errors -eq 0 ]; then
    echo "   ✅ 所有必需的环境变量已设置"
else
    echo "   ❌ 发现 $errors 个配置错误"
fi
echo

# 网络连接测试
echo "2. 网络连接测试："

if [ -n "$CUSTOM_LLM_ENDPOINT" ] && [ -n "$CUSTOM_LLM_API_KEY" ]; then
    echo "   测试端点: $CUSTOM_LLM_ENDPOINT"
    
    if command -v curl &> /dev/null; then
        # 测试基本连接
        echo "   测试基本连接..."
        response=$(curl -s -o /dev/null -w "%{http_code}" \
            -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
            -H "Content-Type: application/json" \
            "$CUSTOM_LLM_ENDPOINT/models" 2>/dev/null)
        
        if [ "$response" = "200" ]; then
            echo "   ✅ API 连接成功"
        elif [ "$response" = "401" ]; then
            echo "   ❌ API 认证失败 (401)"
        elif [ "$response" = "404" ]; then
            echo "   ⚠️ API 端点不支持 models 路由 (404)"
        else
            echo "   ❌ API 连接失败: $response"
        fi
        
        # 测试聊天完成端点
        echo "   测试聊天完成端点..."
        chat_response=$(curl -s -X POST \
            -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{
                \"model\": \"$CUSTOM_LLM_MODEL_NAME\",
                \"messages\": [{\"role\": \"user\", \"content\": \"Hello\"}],
                \"max_tokens\": 10,
                \"temperature\": 0.1
            }" \
            "$CUSTOM_LLM_ENDPOINT/chat/completions" 2>/dev/null)
        
        if echo "$chat_response" | grep -q '"choices"'; then
            content=$(echo "$chat_response" | jq -r '.choices[0].message.content // empty')
            if [ -n "$content" ]; then
                echo "   ✅ 聊天完成端点正常"
                echo "   响应内容: $content"
            else
                echo "   ⚠️ 聊天完成端点返回空内容"
                echo "   完整响应: $chat_response"
            fi
        else
            echo "   ❌ 聊天完成端点异常"
            echo "   响应: $chat_response"
        fi
        
        # 测试响应时间
        echo "   测试响应时间..."
        start_time=$(date +%s%3N)
        curl -s -X POST \
            -H "Authorization: Bearer $CUSTOM_LLM_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{
                \"model\": \"$CUSTOM_LLM_MODEL_NAME\",
                \"messages\": [{\"role\": \"user\", \"content\": \"Hi\"}],
                \"max_tokens\": 5
            }" \
            "$CUSTOM_LLM_ENDPOINT/chat/completions" > /dev/null 2>&1
        end_time=$(date +%s%3N)
        response_time=$((end_time - start_time))
        
        if [ $response_time -lt 5000 ]; then
            echo "   ✅ 响应时间: ${response_time}ms (良好)"
        elif [ $response_time -lt 15000 ]; then
            echo "   ⚠️ 响应时间: ${response_time}ms (一般)"
        else
            echo "   ❌ 响应时间: ${response_time}ms (较慢)"
        fi
        
    else
        echo "   ❌ curl 未安装，跳过连接测试"
    fi
else
    echo "   ❌ 缺少必要的配置，跳过连接测试"
fi
echo

# 模型兼容性检查
echo "3. 模型兼容性检查："

if [ -n "$CUSTOM_LLM_MODEL_NAME" ]; then
    case "$CUSTOM_LLM_MODEL_NAME" in
        *gemini*)
            echo "   ✅ Gemini 模型: $CUSTOM_LLM_MODEL_NAME"
            echo "   注意：确保您的 API 端点支持 Gemini 模型"
            ;;
        *gpt*)
            echo "   ✅ GPT 模型: $CUSTOM_LLM_MODEL_NAME"
            echo "   注意：确保您的 API 端点支持 GPT 模型"
            ;;
        *claude*)
            echo "   ✅ Claude 模型: $CUSTOM_LLM_MODEL_NAME"
            echo "   注意：确保您的 API 端点支持 Claude 模型"
            ;;
        *llama*)
            echo "   ✅ LLaMA 模型: $CUSTOM_LLM_MODEL_NAME"
            echo "   注意：确保您的 API 端点支持 LLaMA 模型"
            ;;
        *)
            echo "   ⚠️ 未知模型: $CUSTOM_LLM_MODEL_NAME"
            echo "   注意：请确保您的 API 端点支持此模型"
            ;;
    esac
else
    echo "   ❌ 模型名称未设置"
fi
echo

# 配置文件检查
echo "4. 配置文件检查："

if [ -f .gemini/.env ]; then
    echo "   ✅ 项目配置文件: .gemini/.env"
    echo "   配置内容："
    cat .gemini/.env | grep -E "(USE_CUSTOM_LLM|CUSTOM_LLM)" | sed 's/^/     /'
else
    echo "   ❌ 项目配置文件不存在: .gemini/.env"
fi

if [ -f ~/.gemini/settings.json ]; then
    echo "   ✅ 用户设置文件: ~/.gemini/settings.json"
    auth_type=$(grep -o '"selectedAuthType": "[^"]*"' ~/.gemini/settings.json | cut -d'"' -f4)
    echo "   认证类型: $auth_type"
else
    echo "   ❌ 用户设置文件不存在: ~/.gemini/settings.json"
fi
echo

# 建议和解决方案
echo "5. 建议和解决方案："

if [ $errors -gt 0 ]; then
    echo "   配置错误："
    if [ "$USE_CUSTOM_LLM" != "true" ]; then
        echo "   • 设置 USE_CUSTOM_LLM=true"
    fi
    if [ -z "$CUSTOM_LLM_API_KEY" ]; then
        echo "   • 设置 CUSTOM_LLM_API_KEY"
    fi
    if [ -z "$CUSTOM_LLM_ENDPOINT" ]; then
        echo "   • 设置 CUSTOM_LLM_ENDPOINT"
    fi
    if [ -z "$CUSTOM_LLM_MODEL_NAME" ]; then
        echo "   • 设置 CUSTOM_LLM_MODEL_NAME"
    fi
fi

echo "   性能优化："
echo "   • 如果响应时间过长，考虑增加 CUSTOM_LLM_TIMEOUT"
echo "   • 减少 CUSTOM_LLM_MAX_TOKENS 以加快响应"
echo "   • 调整 CUSTOM_LLM_TEMPERATURE 以获得更好的结果"

echo "   故障排除："
echo "   • 检查 API 密钥是否正确"
echo "   • 确认 API 端点是否可访问"
echo "   • 验证模型名称是否正确"
echo "   • 查看网络连接是否稳定"

echo
echo "6. 测试命令："
echo "   运行基本测试: elc --debug"
echo "   测试简单查询: echo '1+1=?' | elc"
echo "   查看详细日志: elc --debug 2>&1 | tee debug.log"

echo
echo "=== 诊断完成 ==="

if [ $errors -eq 0 ]; then
    echo "✅ 配置看起来正常，但 API 可能存在问题"
    echo "   尝试运行 elc --debug 进行进一步测试"
else
    echo "❌ 发现配置错误，请先修复这些问题"
    echo "   使用 ./fix-clawcloud-config.sh 快速修复配置"
fi