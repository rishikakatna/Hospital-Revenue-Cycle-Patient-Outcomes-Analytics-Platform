from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()


@dataclass(frozen=True)
class Settings:
    postgres_host: str = os.getenv("POSTGRES_HOST", "localhost")
    postgres_port: int = int(os.getenv("POSTGRES_PORT", "5432"))
    postgres_db: str = os.getenv("POSTGRES_DB", "hospital_rcm")
    postgres_user: str = os.getenv("POSTGRES_USER", "postgres")
    postgres_password: str = os.getenv("POSTGRES_PASSWORD", "postgres")
    data_root: Path = Path(os.getenv("DATA_ROOT", "./data"))
    bronze_dir: Path = Path(os.getenv("BRONZE_DIR", "./data/bronze"))
    silver_dir: Path = Path(os.getenv("SILVER_DIR", "./data/silver"))
    gold_dir: Path = Path(os.getenv("GOLD_DIR", "./data/gold"))

    @property
    def sqlalchemy_url(self) -> str:
        return (
            f"postgresql+psycopg2://{self.postgres_user}:{self.postgres_password}"
            f"@{self.postgres_host}:{self.postgres_port}/{self.postgres_db}"
        )


SETTINGS = Settings()
