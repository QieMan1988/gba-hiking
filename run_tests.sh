#!/bin/bash

# ============================================================
# 脚本名称：run_tests.sh
# 功能描述：测试运行脚本
# 作者：Godot开发团队
# 创建日期：2026-01-29
# 使用方法：./run_tests.sh [test_type]
#   test_type: unit (默认) | integration | all
# ============================================================

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 统计变量
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

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

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# 参数解析
TEST_TYPE=${1:-unit}
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$PROJECT_ROOT/tests"
TEST_RESULTS="$TEST_DIR/results"

log_info "=================================================="
log_info "《大湾区徒步》测试脚本"
log_info "=================================================="
log_info "测试类型: $TEST_TYPE"
log_info "项目路径: $PROJECT_ROOT"
log_info "=================================================="

# 检查Godot是否安装
if ! command -v godot &> /dev/null; then
    log_error "Godot未安装或不在PATH中"
    log_error "请先安装Godot 4.5.1+"
    exit 1
fi

# 创建测试结果目录
log_info "创建测试结果目录..."
mkdir -p "$TEST_RESULTS"

# 清理旧的测试结果
log_info "清理旧的测试结果..."
rm -rf "$TEST_RESULTS/"*.xml 2>/dev/null || true

# 运行测试
run_unit_tests() {
    log_info "运行单元测试..."
    log_info "=================================================="
    
    local test_files=$(find "$TEST_DIR/unit" -name "*_test.gd" 2>/dev/null)
    
    if [ -z "$test_files" ]; then
        log_warn "未找到单元测试文件"
        log_warn "请确保测试文件位于: $TEST_DIR/unit/"
        return 0
    fi
    
    # 统计测试文件数量
    local test_count=$(echo "$test_files" | wc -l)
    log_info "找到 $test_count 个测试文件"
    
    # 运行每个测试文件
    for test_file in $test_files; do
        local test_name=$(basename "$test_file" .gd)
        log_test "运行测试: $test_name"
        
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        
        if godot --headless --script "$test_file" > "$TEST_RESULTS/${test_name}.log" 2>&1; then
            log_info "✓ $test_name 通过"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            log_error "✗ $test_name 失败"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            log_error "日志: $TEST_RESULTS/${test_name}.log"
        fi
    done
}

run_integration_tests() {
    log_info "运行集成测试..."
    log_info "=================================================="
    
    local test_files=$(find "$TEST_DIR/integration" -name "*_integration_test.gd" 2>/dev/null)
    
    if [ -z "$test_files" ]; then
        log_warn "未找到集成测试文件"
        log_warn "请确保测试文件位于: $TEST_DIR/integration/"
        return 0
    fi
    
    # 统计测试文件数量
    local test_count=$(echo "$test_files" | wc -l)
    log_info "找到 $test_count 个测试文件"
    
    # 运行每个测试文件
    for test_file in $test_files; do
        local test_name=$(basename "$test_file" .gd)
        log_test "运行测试: $test_name"
        
        TOTAL_TESTS=$((TOTAL_TESTS + 1))
        
        if godot --headless --script "$test_file" > "$TEST_RESULTS/${test_name}.log" 2>&1; then
            log_info "✓ $test_name 通过"
            PASSED_TESTS=$((PASSED_TESTS + 1))
        else
            log_error "✗ $test_name 失败"
            FAILED_TESTS=$((FAILED_TESTS + 1))
            log_error "日志: $TEST_RESULTS/${test_name}.log"
        fi
    done
}

# 根据测试类型运行测试
case $TEST_TYPE in
    unit)
        run_unit_tests
        ;;
    integration)
        run_integration_tests
        ;;
    all)
        run_unit_tests
        echo ""
        run_integration_tests
        ;;
    *)
        log_error "未知的测试类型: $TEST_TYPE"
        log_error "支持的选项: unit, integration, all"
        exit 1
        ;;
esac

# 输出测试结果
echo ""
log_info "=================================================="
log_info "测试结果汇总"
log_info "=================================================="
log_info "总测试数: $TOTAL_TESTS"
log_info -e "${GREEN}通过: $PASSED_TESTS${NC}"
if [ $FAILED_TESTS -gt 0 ]; then
    log_info -e "${RED}失败: $FAILED_TESTS${NC}"
else
    log_info "失败: $FAILED_TESTS"
fi

# 计算通过率
if [ $TOTAL_TESTS -gt 0 ]; then
    local pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    log_info "通过率: $pass_rate%"
    
    if [ $pass_rate -ge 80 ]; then
        log_info -e "${GREEN}测试通过！${NC}"
        exit 0
    else
        log_error -e "${RED}测试未通过（通过率需≥80%）${NC}"
        exit 1
    fi
else
    log_warn "没有运行任何测试"
    exit 0
fi
