#!/bin/bash

# 快速修复自定义 API 配置脚本
# 专门解决 ClawCloud 自定义 API 配置问题

echo "=== ClawCloud 自定义 API 配置修复 ==="
echo

# 检查是否在正确的目录
if [ ! -f "packages/cli/src/gemini.tsx" ]; then
    echo "错误：请在 Easy LLM CLI 项目根目录运行此脚本"
    exit 1
fi

# 创建 .gemini 目录
echo "1. 创建配置目录..."
mkdir -p .gemini

# 创建配置文件
echo "2. 创建自定义 API 配置..."
cat > .gemini/.env << 'EOF'
# 启用自定义 LLM
USE_CUSTOM_LLM=true

# LLM 提供商
CUSTOM_LLM_PROVIDER="openai"

# ClawCloud API 配置
CUSTOM_LLM_API_KEY="sk-wuzhe12345"
CUSTOM_LLM_ENDPOINT="https://rueyfuklmxsq.us-east-1.clawcloudrun.com/v1"
CUSTOM_LLM_MODEL_NAME="gemini-2.5-pro"

# 可选参数
CUSTOM_LLM_TEMPERATURE=0.1
CUSTOM_LLM_MAX_TOKENS=8192
CUSTOM_LLM_TOP_P=1.0
CUSTOM_LLM_TIMEOUT=45000
EOF

echo "   ✓ 配置文件已创建: .gemini/.env"

# 清除可能的缓存
echo "3. 清除缓存..."
if [ -d ~/.gemini ]; then
    # 备份现有设置
    if [ -f ~/.gemini/settings.json ]; then
        cp ~/.gemini/settings.json ~/.gemini/settings.json.backup.$(date +%Y%m%d_%H%M%S)
        echo "   ✓ 用户设置已备份"
    fi
    
    # 清除凭证缓存
    rm -f ~/.gemini/credentials.json 2>/dev/null
    echo "   ✓ 凭证缓存已清除"
fi

# 设置环境变量
echo "4. 设置环境变量..."
export USE_CUSTOM_LLM=true
export CUSTOM_LLM_PROVIDER="openai"
export CUSTOM_LLM_API_KEY="sk-wuzhe12345"
export CUSTOM_LLM_ENDPOINT="https://rueyfuklmxsq.us-east-1.clawcloudrun.com/v1"
export CUSTOM_LLM_MODEL_NAME="gemini-2.5-pro"
export CUSTOM_LLM_TEMPERATURE=0.1
export CUSTOM_LLM_MAX_TOKENS=8192
export CUSTOM_LLM_TOP_P=1.0

echo "   ✓ 环境变量已设置"

# 验证配置
echo "5. 验证配置..."
if [ -f .gemini/.env ]; then
    echo "   ✓ .gemini/.env 文件存在"
    echo "   内容预览："
    cat .gemini/.env | grep -E "(USE_CUSTOM_LLM|CUSTOM_LLM)" | sed 's/^/     /'
fi

echo
echo "6. 测试 API 连接..."
if command -v curl &> /dev/null; then
    echo "   测试端点: https://rueyfuklmxsq.us-east-1.clawcloudrun.com/v1"
    
    # 测试基本连接
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -H "Authorization: Bearer sk-wuzhe12345" \
        -H "Content-Type: application/json" \
        "https://rueyfuklmxsq.us-east-1.clawcloudrun.com/v1/models" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        echo "   ✓ API 连接成功"
    elif [ "$response" = "401" ]; then
        echo "   ⚠ API 认证失败 (401) - 请检查 API 密钥"
    elif [ "$response" = "404" ]; then
        echo "   ⚠ API 端点返回 404 - 可能不支持 models 路由"
    else
        echo "   ⚠ API 连接状态: $response"
    fi
else
    echo "   ⚠ curl 未安装，跳过连接测试"
fi

echo
echo "=== 修复完成 ==="
echo
echo "下一步操作："
echo "1. 运行验证脚本: ./check-config.sh"
echo "2. 诊断 API 问题: ./diagnose-api.sh"
echo "3. 启动 CLI: elc"
echo "4. 如果仍有问题，请运行: elc --debug"
echo
echo "注意事项："
echo "• 确保 API 密钥 'sk-wuzhe12345' 是正确的"
echo "• 确保 ClawCloud 服务正在运行"
echo "• 如果更改了 API 密钥，请编辑 .gemini/.env 文件"
echo
echo "配置文件位置："
echo "• 项目配置: $(pwd)/.gemini/.env"
echo "• 备份配置: ~/.gemini/settings.json.backup.*"