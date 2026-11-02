# OpenAPI source maintenance

The files under `openapi/source` are the maintained API contract. Run `ruby bin/generate_oas.rb` after editing them. Do not edit `openapi/generated/partner-api.v0.yaml` directly.

## Migration provenance

The initial endpoint contract and models came from the committed `runpapi-public-api-docs/reference/partners.v0.yaml` reference. The older `runpapi-partner-api-openapi` specification was used to compare endpoint coverage and recover shared response and pagination shapes. Neither original folder is needed to generate or serve this documentation.

The former public reference depended on unavailable service repositories and remote Stoplight schemas. The local bad-request, not-found, conflict, unauthorized, rate-limit, request-size-limit, pagination, and links schemas were reconstructed from committed examples and the older local shared components. Review these local schemas against authoritative service contracts when those sources become available.

## Source layout

- `openapi/source/base.yaml`: API metadata and server information.
- `openapi/source/paths`: activity and webhook operations.
- `openapi/source/components/common.yaml`: parameters, headers, security schemes, and reusable responses.
- `openapi/source/models`: API resource, request, and response schemas.
- `openapi/source/schemas`: reconstructed shared error and JSON:API schemas.
- `openapi/source/manifest.yaml`: deterministic assembly order.

The generator rejects duplicate paths and components, external references, unresolved sources, and unexpected path or operation counts.