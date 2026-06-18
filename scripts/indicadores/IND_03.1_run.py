"""Public sanitized runner for I03."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib.monthly_runner import run_sql_indicator


if __name__ == "__main__":
    run_sql_indicator("03", "docs/06.2.2-i03.md", "taxa_cumprimento_temporal")
