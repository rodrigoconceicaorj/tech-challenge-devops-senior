import os
import sys
import json
import types
import pytest
from flask import Flask

# Ensure project root is on PYTHONPATH for 'api' package resolution
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..")))
from api.app import app as flask_app, get_db_connection


class DummyCursor:
    def __init__(self, rows=None, insert_id=1, created_at="2024-01-01T00:00:00Z"):
        self.rows = rows or []
        self.insert_id = insert_id
        self.created_at = created_at
        self.closed = False

    def execute(self, query, params=None):
        pass

    def fetchone(self):
        return [self.insert_id, self.created_at]

    def fetchall(self):
        return self.rows

    def close(self):
        self.closed = True


class DummyConn:
    def __init__(self, rows=None):
        self.rows = rows or []
        self.closed = False
        self.cursor_obj = DummyCursor(rows=self.rows)

    def cursor(self):
        return self.cursor_obj

    def commit(self):
        pass

    def close(self):
        self.closed = True


@pytest.fixture
def client():
    flask_app.config["TESTING"] = True
    with flask_app.test_client() as client:
        yield client


def test_health_success(monkeypatch, client):
    monkeypatch.setattr("api.app.get_db_connection", lambda: DummyConn())
    resp = client.get("/health")
    assert resp.status_code == 200
    body = resp.get_json()
    assert body["status"] == "ok"
    assert body["database"] == "connected"


def test_health_failure(monkeypatch, client):
    def raise_error():
        raise Exception("db down")
    monkeypatch.setattr("api.app.get_db_connection", raise_error)
    resp = client.get("/health")
    assert resp.status_code == 503


def test_create_comment_success(monkeypatch, client):
    monkeypatch.setattr("api.app.get_db_connection", lambda: DummyConn())
    payload = {"email": "user@example.com", "comment": "hello", "content_id": "123"}
    resp = client.post("/api/comment/new", data=json.dumps(payload), content_type="application/json")
    assert resp.status_code == 201
    body = resp.get_json()
    assert body["email"] == "user@example.com"
    assert body["comment"] == "hello"
    assert body["content_id"] == "123"


def test_create_comment_validation(client):
    resp = client.post("/api/comment/new", data=json.dumps({}), content_type="application/json")
    assert resp.status_code == 400


def test_list_comments(monkeypatch, client):
    rows = [
        [1, "a@a.com", "c1", "42", "2024-01-02T00:00:00Z"],
        [2, "b@b.com", "c2", "42", "2024-01-03T00:00:00Z"],
    ]
    monkeypatch.setattr("api.app.get_db_connection", lambda: DummyConn(rows=rows))
    resp = client.get("/api/comment/list/42")
    assert resp.status_code == 200
    body = resp.get_json()
    assert isinstance(body, list)
    assert len(body) == 2
