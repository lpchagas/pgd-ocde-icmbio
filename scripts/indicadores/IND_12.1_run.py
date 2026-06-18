"""Public sanitized runner for I12."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib.monthly_runner import run_sql_indicator


if __name__ == "__main__":
    run_sql_indicator("12", "docs/06.4.4-i12.md", "coerencia_pt_pe")
