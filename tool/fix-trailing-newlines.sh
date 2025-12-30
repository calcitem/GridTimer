#!/bin/bash
# 修复文本文件末尾的空行，确保每个文件末尾只有一个空行

set -e

# 定义要处理的文件扩展名
FILE_EXTENSIONS=(
    "*.dart"
    "*.md"
    "*.yaml"
    "*.yml"
    "*.sh"
    "*.kt"
    "*.gradle"
    "*.properties"
    "*.json"
    "*.xml"
    "*.arb"
    "*.txt"
)

# 定义要排除的目录
EXCLUDE_DIRS=(
    ".git"
    ".dart_tool"
    "build"
    ".idea"
    "node_modules"
    ".gradle"
    "android/build"
    "ios/Pods"
)

# 构建 find 命令的排除参数
EXCLUDE_ARGS=()
for dir in "${EXCLUDE_DIRS[@]}"; do
    EXCLUDE_ARGS+=(-path "*/$dir" -prune -o)
done

# 构建 find 命令的文件类型参数
EXTENSION_ARGS=()
for ext in "${FILE_EXTENSIONS[@]}"; do
    if [ ${#EXTENSION_ARGS[@]} -eq 0 ]; then
        EXTENSION_ARGS+=(-name "$ext")
    else
        EXTENSION_ARGS+=(-o -name "$ext")
    fi
done

# 统计变量
total_files=0
modified_files=0

echo "正在扫描文本文件..."

# 查找并处理文件
while IFS= read -r -d '' file; do
    total_files=$((total_files + 1))
    
    # 跳过空文件
    if [ ! -s "$file" ]; then
        continue
    fi
    
    # 读取文件最后一个字符
    last_char=$(tail -c 1 "$file")
    
    # 创建临时文件
    temp_file=$(mktemp)
    
    # 移除文件末尾的所有空行
    sed -e :a -e '/^\s*$/d;N;ba' "$file" > "$temp_file"
    
    # 添加一个换行符到末尾（如果文件不为空）
    if [ -s "$temp_file" ]; then
        # 检查是否需要添加换行符
        if [ -n "$(tail -c 1 "$temp_file")" ]; then
            echo "" >> "$temp_file"
        fi
    fi
    
    # 检查文件是否被修改
    if ! cmp -s "$file" "$temp_file"; then
        mv "$temp_file" "$file"
        modified_files=$((modified_files + 1))
        echo "✓ 已修复: $file"
    else
        rm "$temp_file"
    fi
    
done < <(find . "${EXCLUDE_ARGS[@]}" \( "${EXTENSION_ARGS[@]}" \) -type f -print0)

echo ""
echo "========================================="
echo "扫描完成！"
echo "总文件数: $total_files"
echo "修改文件数: $modified_files"
echo "========================================="

