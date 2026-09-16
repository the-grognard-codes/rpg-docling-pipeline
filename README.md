# RPG Docling Pipeline

Convert RPG rulebooks and other PDF books into machine-readable Markdown. The pipeline uses Docling with CUDA acceleration, English OCR, and accurate table reconstruction. It does not generate image descriptions or export page/picture images.

## What you need

This project is configured for a Windows computer with:

- Python 3.12 (64-bit)
- An NVIDIA CUDA-capable GPU and a current NVIDIA driver
- Internet access for the initial package and model downloads
- Several gigabytes of free disk space for the Python environment and cached models

Check that Windows can see the GPU before setup:

```powershell
nvidia-smi
```

The project is deliberately GPU-configured. The setup script stops with a clear error if CUDA is not available instead of silently falling back to a much slower CPU configuration.

## Setup

1. Download or clone this repository.
2. Open PowerShell in the repository folder.
3. Run:

   ```powershell
   powershell -ExecutionPolicy Bypass -File .\setup.ps1
   ```

The setup script creates `.venv`, installs the exact pinned packages (including CUDA-enabled PyTorch), confirms that PyTorch can use the GPU, and verifies the Docling configuration.

You do not need to install the full CUDA Toolkit separately. You do need a working, up-to-date NVIDIA driver.

## Convert PDFs

1. Copy one or more `.pdf` files into `data/raw`.
2. Run:

   ```powershell
   .\.venv\Scripts\python.exe src\process.py
   ```

Every PDF directly inside `data/raw` is converted. A Markdown file with the same base name is written to `data/processed`. Running the script again replaces a Markdown file with the same name.

The first conversion can take longer because Docling and RapidOCR may download and cache their models. During a conversion, run `nvidia-smi` in another PowerShell window to see GPU memory usage and activity.

## Processing configuration

The pipeline is tuned for English-language RPG books containing normal text, scanned pages, illustrations, and tables:

- CUDA is used for Docling and RapidOCR inference.
- RapidOCR uses English recognition at 216 DPI (`scale=3.0`).
- TableFormer uses accurate table reconstruction with cell matching.
- OCR uses Docling's default mixed-PDF mode: it preserves reliable embedded text and applies OCR to scanned/image regions.
- Image descriptions, picture classification, chart extraction, generated page/picture images, code extraction, and formula extraction are disabled to save time.

## Troubleshooting

**PowerShell says scripts are disabled**

Use the setup command shown above. `-ExecutionPolicy Bypass` applies only to that one command and does not change your computer's permanent policy.

**Setup says Python 3.12 is required**

Install the 64-bit Python 3.12 release, reopen PowerShell, and run `python --version` to confirm it reports `Python 3.12.x`.

**Setup cannot find `nvidia-smi` or CUDA**

Install or update the NVIDIA driver, reboot only if that driver installer asks you to, and verify `nvidia-smi` works before rerunning setup.

**A Python session was already open during setup**

Close and reopen that Python REPL, Jupyter kernel, or VS Code debug session. A normal new PowerShell command does not require a restart.

**Do not use `pip install --upgrade` to update individual packages.** The versions in `requirements.txt` are pinned to keep Docling, PyTorch, and CUDA compatible. Rerun `setup.ps1` to repair the environment instead.
