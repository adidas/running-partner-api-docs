# Partner API documentation

This folder is the self-contained source for the adidas Running App Partner API reference and integration guides. Partner API endpoints use `v0`; the account service and authentication documentation use `v1`.

## Run locally

Prerequisites: Podman and a Podman Compose provider.

```shell
podman compose up --build
```

- Guides: http://localhost:8000
- Swagger Editor: http://localhost:8081

Stop the services with `podman compose down`.

Override occupied host ports when starting the stack:

```shell
DOCS_PORT=8001 SWAGGER_PORT=8082 podman compose up --build
```

Links embedded in the local documentation use the default ports.

## Generate and validate

```shell
podman compose run --rm generate
podman compose --profile tools run --rm validate
```

The OpenAPI source is under `openapi/source`. The committed `openapi/generated/partner-api.v0.yaml` file is generated and must not be edited directly. Generation and validation do not use sibling repositories or remote schema references.

The neighboring `runpapi-partner-api-openapi` and `runpapi-public-api-docs` folders are migration provenance only and remain unchanged.