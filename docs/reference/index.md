# API reference

Open the interactive [Partner API reference in Swagger Editor](http://localhost:8081).

The Partner API endpoints use version `v0`. Authentication is provided by the version `v1` account service, so the authentication guide remains under `authentication/v1`.

## Authentication by endpoint

| Endpoint group | OAuth flow | Guide |
| --- | --- | --- |
| Activities | Authorization Code, on behalf of a user | [Partner on behalf of User](../authentication/v1/partner_in_behalf_of_user.md) |
| Webhook receivers | Client Credentials, for the partner | [Partner Authentication](../authentication/v1/partner.md) |
| Webhook subscriptions | Authorization Code, on behalf of a user | [Partner on behalf of User](../authentication/v1/partner_in_behalf_of_user.md) |

The generated standalone specification is available at `openapi/generated/partner-api.v0.yaml` in this repository.