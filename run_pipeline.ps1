# NOTE: This script is intended for local testing/demo purposes only. Do not use in production.

param(
  [string]$ModelId      = 'microsoft/phi-2',
  [string]$ModelName    = 'phi-2',
  [string]$DownloadDir  = ".\models\$ModelName",
  [string]$LlamaCppDir  = ".\llama.cpp",
  [string]$QuantizeType = 'Q4_K_M'
)

Write-Host "=== Build llama.cpp ==="
.\build_llama_cpp.ps1 -LlamaCppDir $LlamaCppDir

Write-Host "`n=== Convert & Quantize Model ==="
.\convert_model.ps1 `
    -ModelId      $ModelId `
    -ModelName    $ModelName `
    -DownloadDir  $DownloadDir `
    -LlamaCppDir  $LlamaCppDir `
    -QuantizeType $QuantizeType

Write-Host "`nAll steps finished."
