#!/bin/bash

# Godot 4.5 项目配置检查脚本
# 用途：快速检查项目配置是否符合Godot 4.5要求

echo "=========================================="
echo "Godot 4.5 项目配置检查"
echo "=========================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查计数器
total_checks=0
passed_checks=0
failed_checks=0

# 检查函数
check_file() {
    local file=$1
    local description=$2
    total_checks=$((total_checks + 1))
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "${RED}✗${NC} $description (缺失)"
        failed_checks=$((failed_checks + 1))
    fi
}

check_dir() {
    local dir=$1
    local description=$2
    total_checks=$((total_checks + 1))
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $description"
        passed_checks=$((passed_checks + 1))
    else
        echo -e "${RED}✗${NC} $description (缺失)"
        failed_checks=$((failed_checks + 1))
    fi
}

check_config_value() {
    local file=$1
    local key=$2
    local expected=$3
    local description=$4
    total_checks=$((total_checks + 1))
    
    if [ -f "$file" ]; then
        actual=$(grep "^${key}=" "$file" | cut -d'=' -f2)
        if [ "$actual" = "$expected" ]; then
            echo -e "${GREEN}✓${NC} $description"
            passed_checks=$((passed_checks + 1))
        else
            echo -e "${RED}✗${NC} $description (期望: $expected, 实际: $actual)"
            failed_checks=$((failed_checks + 1))
        fi
    else
        echo -e "${RED}✗${NC} $description (配置文件不存在)"
        failed_checks=$((failed_checks + 1))
    fi
}

# 开始检查
echo "1. 核心配置文件检查"
echo "-----------------------------------"
check_file "project.godot" "project.godot 配置文件"
check_file ".editorconfig" ".editorconfig 编辑器配置"
check_file "export_presets.cfg" "export_presets.cfg 导出预设"
check_file "icon.svg" "icon.svg 项目图标"
echo ""

echo "2. 目录结构检查"
echo "-----------------------------------"
check_dir "autoloads" "autoloads AutoLoad脚本目录"
check_dir "scenes" "scenes 场景文件目录"
check_dir "scripts" "scripts 脚本文件目录"
check_dir "resources" "resources 资源文件目录"
check_dir "config" "config 配置文件目录"
echo ""

echo "3. 主场景检查"
echo "-----------------------------------"
check_file "scenes/main_menu/Main_Menu.tscn" "Main_Menu.tscn 主场景"
echo ""

echo "4. AutoLoad脚本检查"
echo "-----------------------------------"
check_file "autoloads/GameManager.gd" "GameManager.gd 游戏管理器"
check_file "autoloads/CardSystem.gd" "CardSystem.gd 卡牌系统"
check_file "autoloads/AttributeSystem.gd" "AttributeSystem.gd 属性系统"
check_file "autoloads/ComboSystem.gd" "ComboSystem.gd 连击系统"
check_file "autoloads/EconomySystem.gd" "EconomySystem.gd 经济系统"
check_file "autoloads/SaveManager.gd" "SaveManager.gd 存档管理器"
check_file "autoloads/UIManager.gd" "UIManager.gd UI管理器"
check_file "autoloads/AudioManager.gd" "AudioManager.gd 音频管理器"
check_file "autoloads/SteamManager.gd" "SteamManager.gd Steam管理器"
echo ""

echo "5. project.godot 配置值检查"
echo "-----------------------------------"
check_config_value "project.godot" "config_version" "5" "config_version=5"
check_config_value "project.godot" 'config/features=PackedStringArray("4.5"' "Godot 4.5特性"
echo ""

echo "6. Git配置检查"
echo "-----------------------------------"
check_file ".gitignore" ".gitignore Git忽略文件"
check_dir ".git" ".git Git仓库"
echo ""

# 总结
echo "=========================================="
echo "检查结果总结"
echo "=========================================="
echo -e "总检查项: $total_checks"
echo -e "${GREEN}通过: $passed_checks${NC}"
echo -e "${RED}失败: $failed_checks${NC}"
echo ""

if [ $failed_checks -eq 0 ]; then
    echo -e "${GREEN}✓ 所有检查通过！项目配置符合Godot 4.5要求。${NC}"
    echo ""
    echo "下一步："
    echo "1. 打开Godot 4.5编辑器"
    echo "2. 导入项目"
    echo "3. 验证主场景可以正常加载"
    exit 0
else
    echo -e "${RED}✗ 发现 $failed_checks 个问题，请根据上述提示修复。${NC}"
    exit 1
fi
