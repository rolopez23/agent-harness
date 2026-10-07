from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.ext.asyncio import AsyncSession

from database import get_db
from schemas import HealthOut
from services.health import database_is_reachable

router = APIRouter(prefix="/health", tags=["health"])


@router.get("", response_model=HealthOut, responses={503: {"model": HealthOut}})
async def health(response: Response, db: AsyncSession = Depends(get_db)) -> HealthOut:
    if await database_is_reachable(db):
        return HealthOut(status="ok", database="ok")
    response.status_code = status.HTTP_503_SERVICE_UNAVAILABLE
    return HealthOut(status="degraded", database="unreachable")
