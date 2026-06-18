"""Public sanitized runner for I11."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib.monthly_runner import run_sql_indicator


if __name__ == "__main__":
    run_sql_indicator("11", "docs/06.4.3-i11.md", "perc_excepcional_pt", period_type="pt")
