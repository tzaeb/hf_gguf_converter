param(
    [Parameter(Mandatory=$true)][string]$ModelId,
    [string]$DownloadDir,
    [string]$LlamaCppDir = ".\llama.cpp",
    [string]$QuantizeType = "Q4_K_M"
)

# Extract model name from ModelId (everything after the last '/')
$ModelName = $ModelId.Split('/')[-1]

# Set default download directory if not provided
if (-not $DownloadDir) {
    $DownloadDir = ".\models\$ModelName"
}

# derive outputs
$OutputGgufF16       = "${ModelName}-f16.gguf"
$OutputGgufQuantized = "$($ModelName)-$($QuantizeType).gguf"

# --- Ensure llama.cpp exists ---
if (-not (Test-Path -Path $LlamaCppDir -PathType Container)) {
    Write-Error "llama.cpp directory not found at '$LlamaCppDir'. Please run build_llama_cpp.ps1 to clone and build llama.cpp."
    exit 1
} else {
    Write-Host "llama.cpp directory found at '$LlamaCppDir'."
    # Optional: Add a check here to see if build outputs exist if the directory already existed.
    $QuantizeCheck = Join-Path $LlamaCppDir "build\bin\Release\llama-quantize.exe" # Standard build path
    if (-not (Test-Path $QuantizeCheck -PathType Leaf)) {
         Write-Warning "Build output 'llama-quantize.exe' not found in the expected location ($QuantizeCheck)."
         Write-Warning "Ensure llama.cpp has been built using '.\build_llama_cpp.ps1' or manually."
    }
}

# --- 1. Download Hugging Face Model ---
Write-Host "Downloading model: $ModelId"
$ParentDir = Split-Path -Path $DownloadDir -Parent
if (-not (Test-Path -Path $ParentDir -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $ParentDir | Out-Null
}
huggingface-cli download $ModelId --local-dir $DownloadDir --local-dir-use-symlinks False

# --- 2. Install llama.cpp Python Dependencies ---
Write-Host "Installing Python requirements for llama.cpp..."
pip install -r "$LlamaCppDir\requirements.txt"

# --- 3. Convert to GGUF (F16) ---
Write-Host "Converting model to GGUF (F16)..."
# Ensure the path is absolute to avoid cwd issues
$ConvertScriptPath = Join-Path (Resolve-Path $LlamaCppDir) "convert_hf_to_gguf.py"
if (-not (Test-Path $ConvertScriptPath -PathType Leaf)) {
    Write-Error "Conversion script not found at '$ConvertScriptPath'. Check the llama.cpp clone/repository structure."
    exit 1
}
# Execute Python script (ensure python is in PATH)
python $ConvertScriptPath "$DownloadDir\" --outfile "$OutputGgufF16"

# Check if conversion was successful
if (-not (Test-Path $OutputGgufF16 -PathType Leaf)) {
    Write-Error "Conversion failed. Output file '$OutputGgufF16' not found. Check python script output."
    exit 1
} else {
    Write-Host "F16 GGUF created: $OutputGgufF16"
}

# --- 4. Quantize the Model ---
Write-Host "Quantizing model to $QuantizeType..."
# Point to the expected build output location
$QuantizeExecutable = Join-Path $LlamaCppDir "build\bin\Release\llama-quantize.exe" # Standard build path

if (-not (Test-Path $OutputGgufF16 -PathType Leaf)) {
     Write-Error "F16 GGUF file '$OutputGgufF16' not found. Cannot quantize."
     exit 1
}

if (-not (Test-Path $QuantizeExecutable -PathType Leaf)) {
    Write-Error "Quantize executable not found at '$QuantizeExecutable'. Build llama.cpp first using '.\build_llama_cpp.ps1'."
    exit 1
}

# Execute quantization
& $QuantizeExecutable "$OutputGgufF16" "$OutputGgufQuantized" "$QuantizeType"

# Check if quantization was successful
if (-not (Test-Path $OutputGgufQuantized -PathType Leaf)) {
    Write-Error "Quantization failed. Output file '$OutputGgufQuantized' not found. Check quantize tool output."
    exit 1
} else {
    Write-Host "Quantized GGUF created: $OutputGgufQuantized"
}

# --- 5. Simple Verification ---
Write-Host "Running simple verification on the quantized model..."
$MainExecutable = Join-Path $LlamaCppDir "build\bin\Release\llama-cli.exe"

if (-not (Test-Path $OutputGgufQuantized -PathType Leaf)) {
    Write-Error "Quantized GGUF '$OutputGgufQuantized' missing. Cannot verify."
    exit 1
} elseif (-not (Test-Path $MainExecutable -PathType Leaf)) {
    Write-Error "Executable '$MainExecutable' not found. Cannot verify."
    exit 1
} else {
    $verification = & $MainExecutable -m "$OutputGgufQuantized" -n 128 -p "Test prompt:"
    Write-Host "`n--- Verification Output ---"
    Write-Host $verification
    Write-Host "--- End of Verification ---`n"
}

Write-Host "Script finished."
Write-Host "F16 GGUF: $OutputGgufF16"
Write-Host "Quantized GGUF: $OutputGgufQuantized"
