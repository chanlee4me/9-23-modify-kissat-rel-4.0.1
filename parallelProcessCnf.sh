#!/bin/bash

# 需要修改的路径
CNF_DIR="/home/wgf/chenli/SAT/2022cnf"
OUTPUT_DIR="/home/wgf/chenli/SAT/9-23-modify-kissat-rel-4.0.1"
CADICAL_PATH="/home/wgf/chenli/SAT/9-23-modify-kissat-rel-4.0.1/build/kissat"

# 结果文件的位置
PROCESSED_FILES="$OUTPUT_DIR/2022cnf.csv"
# 处理的cnf文件个数
TOTAL_FILES=400
# 获取系统的CPU核心数
NUM_CORES=$(nproc)

# 切换到CNF文件目录
cd "$CNF_DIR"

# 生成未处理文件的列表
find . -name "*.cnf" | while read file; do
    if ! grep -q "$(readlink -f "$file")" "$PROCESSED_FILES"; then
        echo "$file"
    fi
done > /tmp/unprocessed_files.txt

# 处理文件的函数
process_file() {
    file="$1"
    str=$(readlink -f "$file")
    echo "开始处理文件: $str"
    
    temp_file=$(mktemp)
    printf "%s," "$str" >> "$temp_file"
    
    output_file=$(mktemp)
    
    # 使用timeout命令限制程序执行时间
    timeout -s SIGTERM 3600 "$CADICAL_PATH" "$str" > "$output_file" 2>&1
    if [ $? -eq 124 ]; then
        echo "文件处理超时: $str"
    else
        echo "文件处理完成: $str"
    fi
    
    # 提取UNSATISFIABLE、SATISFIABLE、UNKNOWN
    status=$(grep -Eo "UNSATISFIABLE|SATISFIABLE|UNKNOWN" "$output_file")
    
    # 如果没有检测到状态，则标记为 TIMEOUT
    if [ -z "$status" ]; then
        status="TIMEOUT"
    fi
    
    echo "$status" >> "$temp_file"
    
    # 提取process-time所在行
    grep "process-time" "$output_file" >> "$temp_file"
    
    printf "\n" >> "$temp_file"
    
    mv "$temp_file" "$OUTPUT_DIR/2022cnf.csv.$BASHPID"
    rm "$output_file"  # 删除临时输出文件
}

export -f process_file
export CADICAL_PATH
export OUTPUT_DIR

# 使用xargs命令并行处理文件
head -n $TOTAL_FILES /tmp/unprocessed_files.txt | xargs -n 1 -P $NUM_CORES -I {} bash -c 'process_file "{}"'

# 合并所有临时文件到一个csv文件中
for tmp_file in "$OUTPUT_DIR"/2022cnf.csv.*; do
    cat "$tmp_file" >> "$PROCESSED_FILES"
    rm "$tmp_file" # 删除临时文件
done

echo "所有文件处理完成"