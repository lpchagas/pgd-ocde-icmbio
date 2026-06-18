"""Public sanitized runner for I01."""
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from lib.monthly_runner import run_i01


if __name__ == "__main__":
    run_i01()
