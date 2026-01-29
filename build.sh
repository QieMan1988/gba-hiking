#!/bin/bash

# ============================================================
# 脚本名称：build.sh
# 功能描述：自动化构建脚本
# 作者：Godot开发团队
# 创建日期：2026-01-29
# 使用方法：./build.sh [target] [platform]
#   target: debug (默认) | release
#   platform: windows (默认) | linux | macos
# ============================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 参数解析
TARGET=${1:-debug}
PLATFORM=${2:-windows}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
EXPORT_DIR="$BUILD_DIR/export"

log_info "=================================================="
log_info "《大湾区徒步》构建脚本"
log_info "=================================================="
log_info "目标: $TARGET"
log_info "平台: $PLATFORM"
log_info "项目路径: $PROJECT_ROOT"
log_info "=================================================="

# 检查Godot是否安装
if ! command -v godot &> /dev/null; then
    log_error "Godot未安装或不在PATH中"
    log_error "请先安装Godot 4.5.1+"
    exit 1
fi

# 创建构建目录
log_info "创建构建目录..."
mkdir -p "$BUILD_DIR"
mkdir -p "$EXPORT_DIR"

# 清理旧的构建文件
log_info "清理旧的构建文件..."
rm -rf "$BUILD_DIR/"*.tmp 2>/dev/null || true
rm -rf "$BUILD_DIR/"*.log 2>/dev/null || true

# 根据目标配置
log_info "配置构建参数..."
case $TARGET in
    debug)
        EXPORT_OPTIONS="export_presets.cfg"
        log_info "构建模式: Debug"
        ;;
    release)
        EXPORT_OPTIONS="export_presets.cfg"
        log_info "构建模式: Release"
        ;;
    *)
        log_error "未知的构建目标: $TARGET"
        log_error "支持的选项: debug, release"
        exit 1
        ;;
esac

# 导出项目
log_info "开始导出项目..."
log_info "这可能需要几分钟时间..."

case $PLATFORM in
    windows)
        godot --headless --export-release "Windows Desktop" "$EXPORT_DIR/大湾区徒步.exe"
        ;;
    linux)
        godot --headless --export-release "Linux/X11" "$EXPORT_DIR/gba-hiking.x86_64"
        ;;
    macos)
        godot --headless --export-release "macOS" "$EXPORT_DIR/大湾区徒步.app"
        ;;
    *)
        log_error "不支持的平台: $PLATFORM"
        log_error "支持的选项: windows, linux, macos"
        exit 1
        ;;
esac

# 检查导出结果
if [ $? -eq 0 ]; then
    log_info "构建成功！"
    log_info "输出目录: $EXPORT_DIR"
    
    # 列出导出的文件
    log_info "导出的文件："
    ls -lh "$EXPORT_DIR"
    
    # 创建构建信息文件
    BUILD_INFO="$BUILD_DIR/build_info.txt"
    echo "构建信息" > "$BUILD_INFO"
    echo "=========" >> "$BUILD_INFO"
    echo "项目: 大湾区徒步" >> "$BUILD_INFO"
    echo "版本: 1.0.0" >> "$BUILD_INFO"
    echo "构建目标: $TARGET" >> "$BUILD_INFO"
    echo "构建平台: $PLATFORM" >> "$BUILD_INFO"
    echo "构建时间: $(date)" >> "$BUILD_INFO"
    echo "构建机器: $(hostname)" >> "$BUILD_INFO"
    echo "Git分支: $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'unknown')" >> "$BUILD_INFO"
    echo "Git提交: $(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" >> "$BUILD_INFO"
    
    log_info "构建信息已保存到: $BUILD_INFO"
    
    log_info "=================================================="
    log_info "构建完成！"
    log_info "=================================================="
else
    log_error "构建失败！"
    log_error "请检查日志文件获取详细信息"
    exit 1
fi
