import pytest

HEALTHY = {"status": "ok", "database": "ok"}
DEGRADED = {"status": "degraded", "database": "unreachable"}


async def test_health_ok_when_db_reachable(client, db_up):
    resp = await client.get("/api/health")
    assert resp.status_code == 200
    assert resp.json() == HEALTHY


async def test_health_503_when_db_unreachable(client, db_down):
    resp = await client.get("/api/health")
    assert resp.status_code == 503
    assert resp.json() == DEGRADED


async def test_health_503_when_db_hangs(client, monkeypatch):
    import asyncio

    import services.health as health_service
    from database import get_db
    from main import app

    class HangingSession:
        async def execute(self, *a, **kw):
            await asyncio.sleep(60)

    async def _get_db():
        yield HangingSession()

    monkeypatch.setattr(health_service, "PING_TIMEOUT_SECONDS", 0.05)
    app.dependency_overrides[get_db] = _get_db
    resp = await client.get("/api/health")
    assert resp.status_code == 503
    assert resp.json() == DEGRADED


async def test_cors_preflight_allows_frontend_origin(client, db_up):
    resp = await client.options(
        "/api/health",
        headers={
            "Origin": "http://localhost:3000",
            "Access-Control-Request-Method": "GET",
        },
    )
    assert resp.status_code == 200
    assert resp.headers["access-control-allow-origin"] == "http://localhost:3000"


async def test_cors_rejects_unknown_origin(client, db_up):
    resp = await client.get("/api/health", headers={"Origin": "http://evil.example"})
    assert "access-control-allow-origin" not in resp.headers


@pytest.mark.integration
async def test_health_ok_against_real_postgres(client, real_db):
    resp = await client.get("/api/health")
    assert resp.status_code == 200
    assert resp.json() == HEALTHY
