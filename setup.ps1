[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Invoke-CheckedCommand {
    param(
        [Parameter(Mandatory)]
        [string]$Command,
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    & $Command @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed with exit code ${LASTEXITCODE}: $Command $($Arguments -join ' ')"
    }
}

if ($env:OS -ne "Windows_NT") {
    throw "This project setup script supports Windows only."
}

$projectRoot = $PSScriptRoot
$venvPath = Join-Path $projectRoot ".venv"
$venvPython = Join-Path $venvPath "Scripts\python.exe"
$requirementsPath = Join-Path $projectRoot "requirements.txt"

if (-not (Test-Path $requirementsPath)) {
    throw "requirements.txt was not found in $projectRoot."
}

$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if ($null -eq $pythonCommand) {
    throw "Python 3.12 (64-bit) is required. Install it, then run this script again."
}

$pythonVersion = (& $pythonCommand.Source -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')").Trim()
if ($LASTEXITCODE -ne 0 -or $pythonVersion -ne "3.12") {
    throw "Python 3.12 (64-bit) is required; 'python' currently resolves to Python $pythonVersion."
}

$pythonBits = (& $pythonCommand.Source -c "import struct; print(struct.calcsize('P') * 8)").Trim()
if ($LASTEXITCODE -ne 0 -or $pythonBits -ne "64") {
    throw "A 64-bit Python 3.12 installation is required."
}

$nvidiaSmi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if ($null -eq $nvidiaSmi) {
    throw "An NVIDIA GPU and current NVIDIA driver are required for this CUDA-configured project. 'nvidia-smi' was not found."
}

Write-Host "Detected NVIDIA GPU:" -ForegroundColor Cyan
Invoke-CheckedCommand $nvidiaSmi.Source "--query-gpu=name,driver_version" "--format=csv,noheader"

if (-not (Test-Path $venvPython)) {
    Write-Host "Creating Python virtual environment..." -ForegroundColor Cyan
    Invoke-CheckedCommand $pythonCommand.Source "-m" "venv" $venvPath
}

Write-Host "Installing pinned project dependencies..." -ForegroundColor Cyan
Invoke-CheckedCommand $venvPython "-m" "pip" "install" "--upgrade" "pip"
Invoke-CheckedCommand $venvPython "-m" "pip" "install" "--requirement" $requirementsPath

Write-Host "Checking installed dependencies..." -ForegroundColor Cyan
Invoke-CheckedCommand $venvPython "-m" "pip" "check"

Write-Host "Verifying CUDA access..." -ForegroundColor Cyan
Invoke-CheckedCommand $venvPython "-c" "import torch; assert torch.cuda.is_available(), 'PyTorch cannot access CUDA'; print(f'PyTorch {torch.__version__} using {torch.cuda.get_device_name(0)}')"

Write-Host "Verifying Docling configuration..." -ForegroundColor Cyan
Invoke-CheckedCommand $venvPython "-c" "from docling.datamodel.base_models import InputFormat; from src.process import build_converter; options = build_converter().format_to_options[InputFormat.PDF].pipeline_options; assert options.accelerator_options.device == 'cuda'; assert options.ocr_options.lang == ['iso:en-Latn']; print('Docling CUDA and English OCR configuration OK')"

Write-Host "`nSetup complete." -ForegroundColor Green
Write-Host "Put PDF files in data\raw, then run:" -ForegroundColor Green
Write-Host "  .\.venv\Scripts\python.exe src\process.py" -ForegroundColor Yellow
