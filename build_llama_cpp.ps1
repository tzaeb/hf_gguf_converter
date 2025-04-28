param(
    [string]$LlamaCppDir = ".\llama.cpp" # Path to the llama.cpp directory
)

# --- Prerequisites Check ---
Write-Host "------------------------------------------------------------------"
Write-Host "Build Prerequisites:"
Write-Host "1. CMake: Required for building llama.cpp."
Write-Host "   - Download from: https://cmake.org/download/"
Write-Host "   - During installation, ensure you select the option 'Add CMake to the system PATH for all users' or '...for current user'."
Write-Host "   - Verify installation by opening a *new* PowerShell window and typing: cmake --version"
Write-Host "2. C++ Build Environment: Required by CMake (e.g., Visual Studio Build Tools)."
Write-Host "   - Install Visual Studio (Community edition is free) or Visual Studio Build Tools."
Write-Host "   - Ensure the 'Desktop development with C++' workload is selected during installation."
Write-Host "   - You might need to run this script from a 'Developer Command Prompt for VS' if VS tools aren't automatically added to the PATH."
Write-Host "------------------------------------------------------------------"

Write-Host "Attempting to build llama.cpp in directory: $LlamaCppDir"

if (-not (Test-Path -Path $LlamaCppDir -PathType Container)) {
    Write-Host "llama.cpp directory not found at '$LlamaCppDir'. Cloning repository..."
    git clone https://github.com/ggerganov/llama.cpp $LlamaCppDir | Out-Default -ErrorAction Stop
}

Write-Host "NOTE: This requires CMake and a C++ Build Environment (e.g., Visual Studio Build Tools) installed and in PATH."

$BuildDir = "build"
$CurrentDir = Get-Location

try {
    # Navigate into llama.cpp directory
    Set-Location $LlamaCppDir

    # Configure and build llama.cpp
    Write-Host "Configuring llama.cpp into '$BuildDir'…"
    cmake -S .            -B $BuildDir `
      -G "Visual Studio 17 2022" -A x64 `
      -DLLAMA_CURL=OFF | Out-Default -ErrorAction Stop

    Write-Host "Building (Release)…"
    cmake --build $BuildDir --config Release | Out-Default -ErrorAction Stop

    Write-Host "llama.cpp build completed in '$BuildDir'."

    # Verify build outputs (optional)
    $QuantizeExe = Join-Path $BuildDir "bin\Release\llama-quantize.exe"
    $MainExe = Join-Path $BuildDir "bin\Release\llama-cli.exe"
    if (Test-Path $QuantizeExe -PathType Leaf) {
        Write-Host "Found: $QuantizeExe"
    } else {
        Write-Warning "Quantize executable not found at expected location: $QuantizeExe"
    }
     if (Test-Path $MainExe -PathType Leaf) {
        Write-Host "Found: $MainExe"
    } else {
        Write-Warning "Main executable not found at expected location: $MainExe"
    }

} catch {
    Write-Error "Error during llama.cpp build process: $($_.Exception.Message)"
    if ($_.Exception.Message -like "*cmake* wurde nicht als Name eines Cmdlet*erkannt*" -or $_.Exception.Message -like "*'cmake' is not recognized*") {
         Write-Error "This likely means CMake is not installed or not found in your system PATH."
         Write-Error "Please install CMake (https://cmake.org/download/) and ensure it's added to PATH during installation."
         Write-Error "You may need to restart PowerShell/your terminal after installing CMake."
    } else {
        Write-Error "Manual build might be required. Check CMake/Compiler setup and error messages above."
    }
    exit 1
} finally {
    # Ensure we return to the original directory
    Set-Location $CurrentDir
}

Write-Host "Build script finished."
