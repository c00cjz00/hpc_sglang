#!/bin/bash
#SBATCH --job-name=qwq02    ## 設定作業名稱
#SBATCH --nodes=2                ## 申請 41個計算節點
#SBATCH --ntasks-per-node=1      ## 每個節點運行 1 個 srun task
#SBATCH --cpus-per-task=12        ## 每個 srun task 申請 4 個 CPU 核心
#SBATCH --gres=gpu:1             ## 每個節點申請 1 張 GPU
#SBATCH --time=01:00:00          ## 設定最長執行時間為 60 分鐘
#SBATCH --account="GOV114013"   ## 指定計畫 ID，費用將依此 ID 計算
#SBATCH --partition=GRPO        ## 選擇計算資源的 queue (gp2d 最長執行 2 天)
#SBATCH --output=logs/job-%j.out    ## 設定標準輸出檔案 (%j 代表作業 ID)
#SBATCH --error=logs/job-%j.err     ## 設定錯誤輸出檔案 (%j 代表作業 ID)
#SBATCH --mail-type=END,FAIL        ## 設定郵件通知類型 (作業結束或失敗時通知)
#SBATCH --mail-user=summerhill001@gmail.com  ## 設定接收通知的信箱


set -ex  ## 使腳本在執行錯誤時立即終止，並顯示執行的命令

#ml singularity

echo "SLURM_JOB_ID: $SLURM_JOB_ID"
echo "SLURM_JOB_NODELIST: $SLURM_JOB_NODELIST"

# 取得計算節點名稱
nodes=$(scontrol show hostnames "$SLURM_JOB_NODELIST")
nodes_array=($nodes)
# 初始化 IP 地址陣列
nodes_ip_address_array=()

# 查詢每個節點的 IP 地址，並存入陣列
for node in "${nodes_array[@]}"; do
    ip_address=$(srun --nodes=1 --ntasks=1 -w "$node" hostname -i | awk '{print $1}')
    nodes_ip_address_array+=("$ip_address")
done

# 輸出每個節點對應的 IP 地址
for i in "${!nodes_array[@]}"; do
    echo "Node: ${nodes_array[$i]}, IP: ${nodes_ip_address_array[$i]}"
done

# 取得 Head 節點的 IP 地址
head_node=${nodes_array[0]}
head_node_ip=$(srun --nodes=1 --ntasks=1 -w "$head_node" hostname --ip-address)

# 取得 Head 節點的 IB IP 地址
head_node_ib0=${head_node}-ib0
head_node_ib0_ip=$(cat /etc/hosts | grep gn0308-ib0 | awk '{print $1}')

echo "IB0: $head_node_ib0"
echo "IB0_ip: $head_node_ib0_ip"

sleep infinity

