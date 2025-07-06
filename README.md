# hf_gguf_converter

A small toolset to download, convert, and quantize Hugging Face models into GGUF format using llama.cpp.

## Prerequisites

- **CMake**
  - Download from: https://cmake.org/download/
  - During installation select “Add CMake to the system PATH”
  - Verify by running `cmake --version` in a new terminal

- **Visual Studio Build Tools (or full Visual Studio)**
  - Install the “Desktop development with C++” workload
  - Ensure `cl.exe` and other MSVC tools are in your PATH (run from a Developer Command Prompt if needed)

- **Hugging Face CLI**
  - Install via PowerShell/terminal:
    ```powershell
    pip install huggingface-hub huggingface-cli
    ```
  - Authenticate before converting models:
    ```powershell
    huggingface-cli login
    ```

## Setup & Build

1. Clone this repo and navigate into it:
   ```powershell
   git clone <repo-url>
   cd hf_gguf_converter
   ```
2. Clone llama.cpp repo:
   ```powershell
    git clone https://github.com/ggerganov/llama.cpp llama.cpp
   ```

3. Build llama.cpp:
   ```powershell
   .\build_llama_cpp.ps1 -LlamaCppDir ".\llama.cpp"
   ```
4. Convert & quantize your model (ensure you’re logged in via HF CLI):
   ```powershell
   .\convert_model.ps1 `
     -ModelId "microsoft/phi-2" `
     -ModelName "phi-2" `
     -DownloadDir ".\models\phi-2" `
     -LlamaCppDir ".\llama.cpp" `
     -QuantizeType "Q4_K_M"
   ```

## Pipeline (Azure DevOps)

See `azure-pipelines.yml` for automated CI/CD steps to build llama.cpp and run model conversion.

