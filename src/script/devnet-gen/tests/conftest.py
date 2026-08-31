import sys
from pathlib import Path

# Add the devnet-gen package root so `import adapters`, `import devnet`, `import writer` work.
ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
