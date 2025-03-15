# Dependencies
from pytest import Session


def pytest_sessionfinish(session: Session, exitstatus: int) -> None:
    if exitstatus == 5:
        session.exitstatus = 0
