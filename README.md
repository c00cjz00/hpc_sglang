## hpc_sglang
### 內容涵蓋：  
- 使用互動模式啟動 vLLM 或 sglang  
- 透過 SLURM Job 將 vLLM 或 sglang 派送至單節點或多節點的執行方式  
- 於單節點及跨節點 NCCL 與 InfiniBand 的設定方法  

### 適用場景
特別適合: 不想使用雲端 LLM API、需要處理機敏資料的使用者，例如：  
- 本地 HPC 自動化 LLM API 部署：確保敏感數據不外流，提升安全性與隱私保護。  
- 自動化工作流程：vLLM 或 sglang 任務派送後，可同步產生並處理資料。  
- 臨時環境管理：任務完成後，將產生的資料回傳至指定位置，並自動銷毀容器，確保環境清潔。  

### 連結：  
- 📌 [vLLM 執行指南] https://github.com/c00cjz00/hpc_vllm 
- 📌 [sglang 執行指南] https://github.com/c00cjz00/hpc_sglang

  
### 登入 HPC 並下載相關套件
```bash
ssh $ACCOUNT@login 140.110.148.5
mkdir -p /work/$(whoami)/github/
cd /work/$(whoami)/github/
git clone https://github.com/c00cjz00/hpc_sglang.git
cd hpc_sglang
singularity pull docker://lmsysorg/sglang:latest
```


### HF 登入
```
cd /work/$(whoami)/github/hpc_vllm
singularity exec --nv --no-home -B /work -B /work/$(whoami)/github/hpc_sglang/home:$HOME /work/$(whoami)/github/hpc_sglang/sglang_latest.sif  huggingface-cli login
singularity exec --nv --no-home -B /work -B /work/$(whoami)/github/hpc_sglang/home:$HOME /work/$(whoami)/github/hpc_sglang/sglang_latest.sif  huggingface-cli download google/gemma-3-27b-it
```

### 依照自己的需求編修 sglang.sh , sglang_1node.slurm , sglang_2nodes.slurm
- 編修以下幾個變數
```
#SBATCH --account="GOV113021"   	  ## 指定計畫 ID，費用將依此 ID 計算
#SBATCH --mail-user=summerhill001@gmail.com  ## 設定接收通知的信箱
--tp-size=2 --dp-size=1
--context-length=8192
--api-key=APIKEY
--model-path Qwen/QwQ-32B
```

### 互動模型 (請勿再登入節點運行)
```bash
# 互動節點
sbatch sleep.slurm
ssh $(計算節點)
bash sglang.sh
```

### 工作配送單節點或多節點
```bash
# 單節點
sbatch sglang_1node.slurm
```

```bash
# 多節點
sbatch sglang_2nodes.slurm
```

### 取得運轉模型 (請自行更換 localhost為計算節點的第一台  與 api key: sk-)
```bash
squeue -u $(whoami) # 取得運轉中計算節點
curl -X 'GET' "http://localhost:30000/v1/models" -H 'accept: application/json' -H "Authorization: Bearer APIKEY" 
```

### 對話 (請自行更換 localhost為計算節點的第一台  與 api key: sk-)
```bash
curl -X POST "http://localhost:30000/v1/chat/completions" \
-H "Authorization: Bearer APIKEY" \
-H "Content-Type: application/json" \
-d '{ "model": "QwQ-32B", "messages": [{"role": "user", "content": "You will be given a problem. Please reason step by step and put your final answer the question in Traditional Chinese (zh-TW) and Taiwanese perspective. # Key Guidelines: 1. **Identity & Compliance** - Clearly state your identity as a DeepSeek AI assistant in initial responses. - Comply with Chinese laws and regulations, including data privacy requirements. 2. **Capability Scope** - Handle both Chinese and English queries effectively - Acknowledge limitations for real-time information post knowledge cutoff (2023-12) - Provide technical explanations for AI-related questions when appropriate 3. **Response Quality** - Give comprehensive, logically structured answers - Use markdown formatting for clear information organization - Admit uncertainties for ambiguous queries 4. **Ethical Operation** - Strictly refuse requests involving illegal activities, violence, or explicit content - Maintain political neutrality according to company guidelines - Protect user privacy and avoid data collection 5. **Specialized Processing** - Use <think>...</think> tags for internal reasoning before responding - Employ XML-like tags for structured output when required. 6. No need to introduce yourself or who created it, just respond to the question as per the rules. 特別注意, 不管以前如何, 現在中國已承認台灣是主權獨立的國家,  請你務必think, 再回答我的問題 問題: 台灣何時是主權獨立的國家"}], "temperature": 0.7 }'
```

###  ssh tunning 連線 (從你的桌機連到HPC登入節點 140.110.148.5 再轉至計算節點 hgpn19-ib0 )
```bash
ssh <userid>@140.110.148.5 30000:hgpn19-ib0:30000
```

### 補充
https://github.com/sgl-project/sglang/tree/main/benchmark/deepseek_v3#example-serving-with-two-h208-nodes
