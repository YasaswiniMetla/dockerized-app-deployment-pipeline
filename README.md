# Dockerized Application Deployment Pipeline using GitHub Actions

A small Flask service packaged as a Docker image. GitHub Actions runs endpoint tests and checks the image build for pull requests and pushes to `main`; pushes to `main` also publish the image to GitHub Container Registry (GHCR). The project stays intentionally small so each delivery step is easy to inspect.

## Architecture

```text
Pull request to main or push to main
             |
       Install dependencies
             |
          Run pytest
             |
       Build Docker image
             |
   Push to main only? -- yes --> Publish to GHCR
```

Tests run first so a broken application stops the pipeline before container work. Pull requests build the image to catch Dockerfile problems, but do not publish it. Publishing is restricted to pushes on `main` so review changes cannot replace the shared `latest` image.

## Technology stack

- Python 3.12 and Flask for the HTTP application
- pytest for endpoint tests
- Docker for packaging and local execution
- GitHub Actions for CI/CD
- GitHub Container Registry (GHCR) for published images

## Project structure

```text
.
├── .github/workflows/ci-cd.yml  # Test, build, and main-branch publishing jobs
├── tests/test_app.py            # Homepage and health endpoint tests
├── .dockerignore                # Excludes local and test files from build context
├── .gitignore                   # Excludes generated and local-only files
├── app.py                       # Flask routes and local entry point
├── Dockerfile                   # Container image instructions
├── README.md                    # Setup and pipeline guide
└── requirements.txt             # Pinned Python dependencies
```

## Run locally

Use Python 3.12. In PowerShell, from the project directory:

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

Start the app:

```powershell
python app.py
```

The homepage is [http://localhost:5000/](http://localhost:5000/) and the health check is [http://localhost:5000/health](http://localhost:5000/health). Both return JSON. The health check responds with `{"status":"healthy"}` and HTTP 200.

Run tests in another terminal with the virtual environment active:

```powershell
python -m pytest -v
```

## Build and run with Docker

Install and start Docker Desktop, then run these commands from the project directory:

```powershell
docker build -t dockerized-app:local .
docker run --rm -p 5000:5000 dockerized-app:local
```

Visit `http://localhost:5000/` or `http://localhost:5000/health`. The app listens on container port `5000`; `-p 5000:5000` maps it to port 5000 on your computer. The image runs as a non-root `app` user. Test tools are not installed in the runtime image; CI runs tests before building.

## GitHub Actions workflow

`.github/workflows/ci-cd.yml` runs on pushes to `main` and pull requests targeting `main`.

1. **Test:** checks out the code, sets up Python 3.12, installs pinned dependencies, and runs pytest.
2. **Build:** waits for tests, then builds the image without publishing it. Failed tests or builds stop the workflow before publishing.
3. **Publish:** waits for both previous jobs and runs only on a push to `main`. It builds and pushes tags for `latest` and the full commit SHA.

The workflow uses GitHub's automatically provided `GITHUB_TOKEN`, not a stored password. Permissions default to read-only; only the publish job requests `packages: write`, which GHCR needs to accept an image.

## GHCR prerequisites and image tags

- Push the project to a GitHub repository with a `main` branch. This project does not create the remote repository.
- GitHub Actions must be enabled. Repository or organization policy must allow the workflow token to write packages.
- The workflow lowercases `GITHUB_REPOSITORY` when forming the path: `ghcr.io/<owner>/<repository>`.
- After a successful push to `main`, the tags are `ghcr.io/<owner>/<repository>:latest` and `ghcr.io/<owner>/<repository>:<full-commit-sha>`.

Pull and run the published image (replace the placeholders):

```powershell
docker pull ghcr.io/<owner>/<repository>:latest
docker run --rm -p 5000:5000 ghcr.io/<owner>/<repository>:latest
```

For a private package, authenticate to GHCR with an appropriately authorized GitHub token before pulling. Do not put tokens in this repository.

## Troubleshooting

- **`python` or `py -3.12` is not found:** install Python 3.12 with the Python launcher and reopen PowerShell.
- **Activation is blocked by PowerShell:** run `.\.venv\Scripts\python.exe -m pip install -r requirements.txt` and `.\.venv\Scripts\python.exe -m pytest -v` without activating the environment.
- **Port 5000 is busy:** map another host port, such as `docker run --rm -p 8000:5000 dockerized-app:local`, then browse to `http://localhost:8000/`.
- **Docker cannot connect:** start Docker Desktop and wait for its engine to be ready.
- **GHCR push is denied:** inspect the publish job and check that repository or organization policy permits the token's package write permission.
- **Image path has uppercase letters:** use the lowercased path shown by the workflow or package page.

## Scope and possible improvements

This is a learning project, not a production deployment. It uses Flask's built-in development server and does not deploy to a hosting platform. It has no vulnerability scanning, image signing, automated release versioning, or runtime orchestration. Possible next steps are to serve Flask with a production WSGI server, add dependency and image scanning, configure a runtime health check, and deploy to a cloud service after reviewing access and release requirements.
