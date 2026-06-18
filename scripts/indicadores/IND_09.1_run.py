"""Public sanitized runner for I09."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib.monthly_runner import run_sql_indicator


if __name__ == "__main__":
    run_sql_indicator("09", "docs/06.4.1-i09.md", "media_avaliacao_pt", period_type="pt")
