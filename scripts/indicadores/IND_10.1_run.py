"""Public sanitized runner for I10."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib.monthly_runner import run_sql_indicator


if __name__ == "__main__":
    run_sql_indicator("10", "docs/06.4.2-i10.md", "perc_inadequado_pt", period_type="pt")
