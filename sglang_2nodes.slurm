#!/bin/bash
#SBATCH --job-name=2nodes_sglang    ## 設定作業名稱
#SBATCH --nodes=2                	## 申請 2個計算節點
#SBATCH --ntasks-per-node=1      	## 每個節點運行 1 個 srun task
#SBATCH --cpus-per-task=12        	## 每個 srun task 申請 12 個 CPU 核心
#SBATCH --gres=gpu:1             	## 每個節點申請 1 張 GPU
#SBATCH --time=01:00:00          	## 設定最長執行時間為 60 分鐘
#SBATCH --account="GOV114013"   	## 指定計畫 ID，費用將依此 ID 計算
#SBATCH --partition=GRPO        	## 選擇計算資源的 queue (gp2d 最長執行 2 天)
#SBATCH --output=logs/job-%j.out    ## 設定標準輸出檔案 (%j 代表作業 ID)
#SBATCH --error=logs/job-%j.err     ## 設定錯誤輸出檔案 (%j 代表作業 ID)
#SBATCH --mail-type=END,FAIL        ## 設定郵件通知類型 (作業結束或失敗時通知)
#SBATCH --mail-user=summerhill001@gmail.com  ## 設定接收通知的信箱

set -ex  ## 使腳本在執行錯誤時立即終止，並顯示執行的命令
echo "SLURM_JOB_ID: $SLURM_JOB_ID"
echo "SLURM_JOB_NODELIST: $SLURM_JOB_NODELIST"

# 取得計算節點名稱
nodes=$(scontrol show hostnames "$SLURM_JOB_NODELIST")
nodes_array=($nodes)

# 取得 Head 節點的 IP 地址
head_node=${nodes_array[0]}
head_node_ip=$(srun --nodes=1 --ntasks=1 -w "$head_node" hostname --ip-address)

# 取得 Head 節點的 IB IP 地址
head_node_ib0=${head_node}-ib0
head_node_ib0_ip=$(cat /etc/hosts | grep ${head_node_ib0} | awk '{print $1}')

# 宣告 網路
echo "Node0: $head_node"
echo "Node0_ip: $head_node_ip"
echo "IB0: $head_node_ib0"
echo "IB0_ip: $head_node_ib0_ip"

#export GLOO_SOCKET_IFNAME=ib0  # 設定 GLOO 使用 InfiniBand 網絡接口
export NCCL_IB_DISABLE=0  # 啟用 InfiniBand，讓 NCCL 使用 IB 來進行更高效的 GPU 之間通信
export NCCL_P2P_DISABLE=0 # 啟用 P2P，讓 GPU 直接溝通
export NCCL_SHM_DISABLE=0 # 啟用共享記憶體，加速 GPU 之間的通訊
export NCCL_SOCKET_IFNAME=ib0,ib1  # 設定 InfiniBand 網卡，讓 NCCL 使用 InfiniBand 網絡進行通信

ml singularity 
mkdir -p /work/$(whoami)/github/hpc_sglang/home
export head_node_ib0_ip=${head_node_ib0_ip}
srun singularity exec --nv --no-home -B /work -B /work/$(whoami)/github/hpc_sglang/home:$HOME /work/$(whoami)/github/hpc_sglang/sglang_latest.sif \
bash -c 'echo "\n"; hostname; \
	echo python3 -m sglang.launch_server \
	--model-path Qwen/QwQ-32B \
	--tp-size=2 --dp-size=1 \
	--port=30000 \
	--host=0.0.0.0 \
	--random-seed=1234 \
	--context-length=8192 --api-key=APIKEY \
	--dist-init-addr ${head_node_ib0_ip}:6379 \
	--nnodes ${SLURM_NNODES} \
	--node-rank  ${SLURM_PROCID} \
	--trust-remote-code; \
	python3 -m sglang.launch_server \
	--model-path Qwen/QwQ-32B \
	--tp-size=2 --dp-size=1 \
	--port=30000 --host=0.0.0.0 \
	--random-seed=1234 \
	--context-length=8192 --api-key=APIKEY \
	--dist-init-addr ${head_node_ib0_ip}:6379 \
	--nnodes ${SLURM_NNODES} \
	--node-rank  ${SLURM_PROCID} \
	--trust-remote-code;	
'



