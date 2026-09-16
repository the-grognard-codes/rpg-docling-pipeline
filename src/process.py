from pathlib import Path

from docling.datamodel.accelerator_options import AcceleratorOptions
from docling.datamodel.base_models import InputFormat
from docling.datamodel.pipeline_options import (
    OcrMode,
    PdfPipelineOptions,
    RapidOcrOptions,
    TableFormerMode,
    TableStructureOptions,
)
from docling.document_converter import DocumentConverter, PdfFormatOption


RAW_DIR = Path("data/raw")
PROCESSED_DIR = Path("data/processed")


def build_converter() -> DocumentConverter:
    pipeline_options = PdfPipelineOptions(
        accelerator_options=AcceleratorOptions(device="cuda", num_threads=4),
        do_ocr=True,
        ocr_options=RapidOcrOptions(
            backend="torch",
            lang=["iso:en"],
            mode=OcrMode.DEFAULT,
            scale=3.0,
        ),
        do_table_structure=True,
        table_structure_options=TableStructureOptions(
            mode=TableFormerMode.ACCURATE,
            do_cell_matching=True,
        ),
        do_picture_classification=False,
        do_picture_description=False,
        do_chart_extraction=False,
        generate_page_images=False,
        generate_picture_images=False,
        generate_table_images=False,
        do_code_enrichment=False,
        do_formula_enrichment=False,
    )

    return DocumentConverter(
        format_options={
            InputFormat.PDF: PdfFormatOption(pipeline_options=pipeline_options)
        }
    )


def run_conversion(
    pdf_path: str | Path,
    output_dir: str | Path,
    converter: DocumentConverter | None = None,
) -> Path:
    source_path = Path(pdf_path)
    if source_path.suffix.lower() != ".pdf":
        raise ValueError(f"Expected a PDF file, got: {source_path}")
    if not source_path.is_file():
        raise FileNotFoundError(f"PDF file not found: {source_path}")

    destination_dir = Path(output_dir)
    destination_dir.mkdir(parents=True, exist_ok=True)

    print(f"Processing: {source_path}")
    result = (converter or build_converter()).convert(source_path)

    out_path = destination_dir / f"{source_path.stem}.md"
    out_path.write_text(result.document.export_to_markdown(), encoding="utf-8")
    print(f"Saved conversion to {out_path}")
    return out_path


def process_raw_pdfs(
    raw_dir: str | Path = RAW_DIR,
    output_dir: str | Path = PROCESSED_DIR,
) -> list[Path]:
    source_dir = Path(raw_dir)
    if not source_dir.is_dir():
        raise FileNotFoundError(f"Raw input directory not found: {source_dir}")

    pdf_paths = sorted(
        path
        for path in source_dir.iterdir()
        if path.is_file() and path.suffix.lower() == ".pdf"
    )
    if not pdf_paths:
        print(f"No PDF files found in {source_dir}")
        return []

    converter = build_converter()
    return [run_conversion(path, output_dir, converter) for path in pdf_paths]


if __name__ == "__main__":
    process_raw_pdfs()
