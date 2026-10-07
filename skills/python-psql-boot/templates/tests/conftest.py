"""Shared fixtures.

Unit tests override `get_db` with fakes so they run without Postgres.
Integration tests (marked `integration`) use a real session on TEST_DATABASE_URL
and skip with a clear reason when that database is unreachable.
"""

import asyncio
import os
from collections.abc import AsyncIterator

import pytest
from dotenv import load_dotenv
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

load_dotenv()

from database import get_db  # noqa: E402
from main import app  # noqa: E402

TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL", "postgresql+asyncpg://app:app@localhost:5432/app_test"
)


class FakeSession:
    """Minimal stand-in for AsyncSession: `execute` succeeds or raises."""

    def __init__(self, error: Exception | None = None):
        self.error = error

    async def execute(self, *args, **kwargs):
        if self.error is not None:
            raise self.error
        return None


def _override_db(session):
    async def _get_db():
        yield session

    return _get_db


@pytest.fixture
async def client() -> AsyncIterator[AsyncClient]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        yield ac
    app.dependency_overrides.clear()


@pytest.fixture
def db_up():
    app.dependency_overrides[get_db] = _override_db(FakeSession())


@pytest.fixture
def db_down():
    app.dependency_overrides[get_db] = _override_db(
        FakeSession(error=OSError("connection refused"))
    )


@pytest.fixture(scope="session")
async def test_engine():
    engine = create_async_engine(TEST_DATABASE_URL, connect_args={"timeout": 3})
    try:
        async with engine.connect() as conn:
            await asyncio.wait_for(conn.execute(text("SELECT 1")), timeout=3)
    except Exception as exc:  # noqa: BLE001 - any failure means "no test DB"
        await engine.dispose()
        pytest.skip(
            f"Postgres test DB unreachable at TEST_DATABASE_URL "
            f"({type(exc).__name__}: {exc}). Start it with `docker compose up -d db`."
        )
    yield engine
    await engine.dispose()


@pytest.fixture
async def real_db(test_engine):
    """Route `get_db` to a real session on the test database, rolled back after."""
    async with test_engine.connect() as conn:
        trans = await conn.begin()
        session = AsyncSession(bind=conn, expire_on_commit=False)
        app.dependency_overrides[get_db] = _override_db(session)
        yield session
        await session.close()
        await trans.rollback()
