import pytest

import main


async def test_startup_does_not_crash_when_db_down(monkeypatch, caplog):
    async def unreachable() -> bool:
        return False

    monkeypatch.setattr(main, "startup_db_check", unreachable)
    monkeypatch.delenv("DB_REQUIRED_AT_STARTUP", raising=False)
    async with main.lifespan(main.app):
        pass
    assert "unreachable" in caplog.text.lower()


async def test_startup_fails_fast_when_db_required(monkeypatch):
    async def unreachable() -> bool:
        return False

    monkeypatch.setattr(main, "startup_db_check", unreachable)
    monkeypatch.setenv("DB_REQUIRED_AT_STARTUP", "true")
    with pytest.raises(RuntimeError, match="unreachable"):
        async with main.lifespan(main.app):
            pass
