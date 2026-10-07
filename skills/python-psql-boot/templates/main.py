import logging
import os
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import APIRouter, FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import AsyncSessionLocal, engine
from routers import health
from services.health import database_is_reachable

load_dotenv()

logger = logging.getLogger("uvicorn.error")

FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:3000")


async def startup_db_check() -> bool:
    async with AsyncSessionLocal() as session:
        return await database_is_reachable(session)


def _db_required_at_startup() -> bool:
    return os.getenv("DB_REQUIRED_AT_STARTUP", "false").lower() in {"1", "true", "yes"}


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Default: log loudly but keep serving, so /api/health can report 503 (contract).
    # Set DB_REQUIRED_AT_STARTUP=true to fail fast instead (e.g. in production).
    if not await startup_db_check():
        if _db_required_at_startup():
            raise RuntimeError("Database unreachable at startup (DB_REQUIRED_AT_STARTUP=true)")
        logger.error("DATABASE UNREACHABLE at startup; /api/health will return 503 until it is up.")
    yield
    await engine.dispose()


app = FastAPI(title="{{APP_NAME}} API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in FRONTEND_URL.split(",") if o.strip()],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

api = APIRouter(prefix="/api")
api.include_router(health.router)
app.include_router(api)
