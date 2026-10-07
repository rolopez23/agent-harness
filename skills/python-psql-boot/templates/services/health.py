import asyncio
import logging

from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)

PING_TIMEOUT_SECONDS = 3.0


async def database_is_reachable(db: AsyncSession) -> bool:
    """Run `SELECT 1`; any error or timeout means unreachable."""
    try:
        await asyncio.wait_for(db.execute(text("SELECT 1")), timeout=PING_TIMEOUT_SECONDS)
    except Exception as exc:  # noqa: BLE001 - health check must never raise
        logger.warning("Database ping failed: %s: %s", type(exc).__name__, exc)
        return False
    return True
