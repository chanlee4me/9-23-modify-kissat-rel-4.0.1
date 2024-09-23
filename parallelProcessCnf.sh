#!/bin/bash

#updated by cl 2024/9/4 
cd /home/wgf/chenli/SAT/2022cnf
#结果文件的位置
processed_files="/home/wgf/chenli/SAT/9-23-modify-kissat-rel-4.0.1/2022cnf.csv"
#处理的cnf文件个数
total_files=400
# 错误日志文件的位置
error_log="/home/wgf/chenli/SAT/9-23-modify-kissat-rel-4.0.1/error.log"
# 信息文件的位置
info_file="/home/wgf/chenli/SAT/9-23-modify-kissat-rel-4.0.1/info"

# 获取系统的CPU核心数
num_cores=$(nproc)

# 生成未处理文件的列表
find . -name "*.cnf" | while read file; do
    if ! grep -q "$(readlink -f "$file")" "$processed_files"; then
        echo "$file"
    fi
done > /tmp/unprocessed_files.txt

# 只处理指定数量的文件，使用系统核心数作为并行数
head -n $total_files /tmp/unprocessed_files.txt | xargs -n 1 -P $num_cores -I {} bash -c '
    file="{}"
    str=$(readlink -f "$file")
    echo "begin $str"
    
    temp_file=$(mktemp)
    printf "%s," "$str" >> "$temp_file"
    result=$(timeout 3600 /home/wgf/chenli/SAT/9-23-modify-kissat-rel-4.0.1/build/kissat "$str" 2>>'"$error_log"')
    echo "$result" | awk -F "[{}]" "/statistics/{flag1=1;next} flag1{print \$0; if(++n1==29) flag1=0} /resources/{flag2=1;next} flag2{print \$0; if(++n2==6) exit}" >> "$temp_file"
    
    # 提取结果状态
    status=$(echo "$result" | grep -oE "SATISFIABLE|UNSATISFIABLE|UNKNOWN")
    
    # 如果没有检测到状态，则标记为 TIMEOUT
    if [ -z "$status" ]; then
        status="TIMEOUT"
    fi
    
    # 检查状态是否已经存在于文件中
    if ! grep -q "$status" "$temp_file"; then
        # 如果状态不存在，则添加到文件末尾
        echo "$status" >> "$temp_file"
    fi
    
    printf "\n" >> "$temp_file"
    echo "end $str"
    
    mv "$temp_file" "/home/wgf/chenli/SAT/9-23-modify-kissat-rel-4.0.1/2022cnf.csv.$BASHPID"
    
    # 提取并输出信息到 info 文件
    echo "$result" | grep -E "htab.capacity = [0-9]+, (idx = [0-9]+|max_var = [0-9]+)" >> '"$info_file"'
'

# 合并所有临时文件到一个csv文件中
for tmp_file in /home/wgf/chenli/SAT/9-23-modify-kissat-rel-4.0.1/2022cnf.csv.*; do
    cat "$tmp_file" >> "/home/wgf/chenli/SAT/9-23-modify-kissat-rel-4.0.1/2022cnf.csv"
    rm "$tmp_file" # 删除临时文件
done