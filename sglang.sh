#!/bin/bash
export GLOO_SOCKET_IFNAME=ib0  # 設定 GLOO 使用 InfiniBand 網絡接口
export NCCL_IB_DISABLE=0  # 啟用 InfiniBand，讓 NCCL 使用 IB 來進行更高效的 GPU 之間通信
export NCCL_P2P_DISABLE=0 # 啟用 P2P，讓 GPU 直接溝通
export NCCL_SHM_DISABLE=0 # 啟用共享記憶體，加速 GPU 之間的通訊
export NCCL_SOCKET_IFNAME=ib0,ib1  # 設定 InfiniBand 網卡，讓 NCCL 使用 InfiniBand 網絡進行通信

ml singularity
mkdir -p /work/$(whoami)/github/hpc_sglang/home
singularity exec --nv --no-home -B /work -B /work/$(whoami)/github/hpc_sglang/home:$HOME /work/$(whoami)/github/hpc_sglang/sglang_latest.sif \
bash -c 'echo "\n"; hostname; \
	python3 -m sglang.launch_server \
	--model-path Qwen/QwQ-32B \
	--tp-size=2 --dp-size=1 \
	--port=30000 --host=0.0.0.0 \
	--random-seed=1234 \
	--context-length=8192 --api-key=APIKEY \
	--trust-remote-code; 
'