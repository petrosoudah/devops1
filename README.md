# Book Shop - Phase 2 CI/CD Pipelines

Docker Assignment Fathi Al Azzawi 20220830 & Petro Soudah 20220996

Repository: `https://github.com/petrosoudah/devops1`

This repository contains the Phase 1 Dockerized Django `book_shop` application and the Phase 2 GitHub Actions CI/CD pipelines.

## Pipeline Design

The Phase 2 design follows the CI/CD pipeline lecture idea: every pipeline must decide what artifact moves toward production.

| Branch | Pipeline Philosophy | What Ships |
| --- | --- | --- |
| `dev` | Artifact-first | A committed application archive from `artifacts/` |
| `test` | Image-first | A fresh Docker image pushed to Docker Hub |
| `prod` | Promotion only | An existing tested Docker image tag |

## Group Choice

This setup is for a group of 2 students.

- Registry: Docker Hub
- Deployment: direct `docker compose` commands on EC2
- EC2 strategy: dev, test, and prod run on the same EC2 instance using different compose projects and ports

## Branch 1: `dev` Artifact-First

Workflow: `.github/workflows/dev.yml`

Trigger: every push to `dev`.

The dev pipeline:

1. Packages the source code into `artifacts/app-<commit-sha>.tar.gz`.
2. Commits the artifact back to the `dev` branch.
3. Copies the committed artifact to EC2.
4. Builds the Docker image from the committed artifact.
5. Deploys the dev environment.

This proves that the deployed container contains exactly what was packaged. The `Dockerfile` copies and extracts the archive using `APP_ARTIFACT`; it does not copy the repo source tree directly.

## Branch 2: `test` Image-First

Workflow: `.github/workflows/test.yml`

Trigger: every push to `test`.

The test pipeline:

1. Builds a fresh artifact inside the workflow from the `test` branch source.
2. Builds a Docker image from that fresh artifact.
3. Pushes the image to Docker Hub using the commit SHA as the tag.
4. Deploys to EC2 by pulling the image from Docker Hub.

This proves the app can be rebuilt reproducibly from source. It does not reuse the artifact committed by the `dev` workflow.

## Branch 3: `prod` Promotion Only

Workflow: `.github/workflows/prod.yml`

Trigger: every push or merge to `prod`.

The prod pipeline:

1. Reads the production version from the GitHub repository variable `IMAGE_VERSION`.
2. Pulls that existing Docker image from Docker Hub.
3. Deploys it to EC2.

The prod workflow does not build, package, or tag an image. Production only promotes a tested version.

## EC2 Coexistence

All branches deploy to the same EC2 instance. They do not conflict because each branch uses a separate compose project name and different host ports.

| Environment | Compose Project | App Port | PostgreSQL Host Port |
| --- | --- | --- | --- |
| dev | `bookshop_dev` | `8001` | `5433` |
| test | `bookshop_test` | `8002` | `5434` |
| prod | `bookshop_prod` | `8003` | `5435` |

Example URLs:

```text
http://EC2_HOST:8001  dev
http://EC2_HOST:8002  test
http://EC2_HOST:8003  prod
```

## GitHub Variables

Configure these in `Settings -> Secrets and variables -> Actions -> Variables`.

| Name | Purpose |
| --- | --- |
| `IMAGE_VERSION` | The image tag promoted to production |
| `EC2_HOST` | EC2 public IP or DNS name |
| `EC2_USER` | EC2 SSH username, usually `ubuntu` |
| `IMAGE_NAME` | Docker Hub image repository name, for example `book-shop` |

## GitHub Secrets

Configure these in `Settings -> Secrets and variables -> Actions -> Secrets`.

| Name | Purpose |
| --- | --- |
| `EC2_SSH_KEY` | Private SSH key for EC2 deployment |
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `SECRET_KEY` | Django secret key |
| `POSTGRES_PASSWORD` | PostgreSQL password |

Secrets must never be committed to the repository.

## Promotion Process

To promote a tested image to production:

1. Open the successful `test` workflow run.
2. Copy the commit SHA image tag pushed to Docker Hub.
3. Set the repository variable `IMAGE_VERSION` to that tag.
4. Push or merge to the `prod` branch.

The prod workflow then pulls that exact version and deploys it without rebuilding.

## Original Local Run

For the original Phase 1 local run, use the pre-pipeline setup with `.env` and `docker compose up --build`. For Phase 2 deployment, `docker-compose.yml` uses `image:` instead of `build:` because the deployed service must run a specific pipeline image.
