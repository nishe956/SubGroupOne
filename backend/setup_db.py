import psycopg2
from psycopg2 import sql
import os
from dotenv import load_dotenv

load_dotenv()

def setup_database():
    # Database credentials from .env
    dbname = os.getenv('DB_NAME', 'lunettes_db')
    user = os.getenv('DB_USER', 'postgres')
    password = os.getenv('DB_PASSWORD', 'postgres')
    host = os.getenv('DB_HOST', 'localhost')
    port = os.getenv('DB_PORT', '5432')

    # Connect to default 'postgres' database to create the new one
    try:
        conn = psycopg2.connect(
            dbname='postgres',
            user=user,
            password=password,
            host=host,
            port=port
        )
        conn.autocommit = True
        cur = conn.cursor()

        # Check if database exists
        cur.execute(f"SELECT 1 FROM pg_catalog.pg_database WHERE datname = %s", (dbname,))
        exists = cur.fetchone()

        if not exists:
            print(f"Creating database {dbname}...")
            cur.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(dbname)))
            print(f"Database {dbname} created successfully.")
        else:
            print(f"Database {dbname} already exists.")

        cur.close()
        conn.close()

    except Exception as e:
        print(f"Error connecting to PostgreSQL: {e}")
        print("Please ensure PostgreSQL is running and credentials in .env are correct.")

if __name__ == "__main__":
    setup_database()
