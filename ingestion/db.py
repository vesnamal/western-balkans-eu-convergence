import os
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

def get_engine():
    url = (
        f"postgresql+psycopg2://{os.environ['PGUSER']}:{os.environ['PGPASSWORD']}"
        f"@{os.environ['PGHOST']}:{os.environ['PGPORT']}/{os.environ['PGDATABASE']}"
    )
    return create_engine(url)

if __name__ == "__main__":
    with get_engine().connect() as conn:
        print("DB connection OK:", conn.execute(text("SELECT 1")).scalar())