"""Public sanitized runner for I02."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib.monthly_runner import run_sql_indicator


if __name__ == "__main__":
    run_sql_indicator("02", "docs/06.2.1-i02.md", "taxa_cumprimento_temporal")
