from app import app


def test_homepage_returns_welcome_message():
    response = app.test_client().get("/")
    assert response.status_code == 200
    assert response.json["status"] == "running"
    assert "Welcome" in response.json["message"]


def test_health_endpoint_reports_healthy():
    response = app.test_client().get("/health")
    assert response.status_code == 200
    assert response.json == {"status": "healthy"}
