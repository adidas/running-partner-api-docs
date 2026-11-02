# Changelog

This pages describes relevant changes in the Partner API.

## 2024-07
- Changed contact email address to the current one.

## 2023-12
- Increased webhook notification delivery attempts
- Clarified that it is mandatory to revoke all refresh tokens of a user when that user disconnects from adidas running

## 2023-11

- Added OAuth scopes **pa_activity_write** and **pa_activity_read** to Activity API
- Deprecated OAuth scope pa_activity for Activity API: Please use pa_activity_write or pa_activity_read instead as specified in the respective endpoint documentation.

## 2021-06

- Moved documentation to Stoplight

## 2020-06

- Add CRUDI endpoints for receivers `GET|POST|PATCH|DELETE /v0/webhooks/receivers`

## 2020-04-23

- Updated import activities endpoint to receive param `description`

## Initial version

- Features available:

  - Import activities with FIT or GPX files (`POST /v0/activities`)
  - Retrieve activity (`GET /v0/activities/{activity_id}`)
  - Retrieve GPX trace from activity (`GET /v0/activities/{activity_id}/traces/gpx`)
  - Create subscription for webhooks (`POST /v0/webhooks/subscriptions`)
  - Send webhooks to partners when subscribed user creates a new activity

- Authentication features (OAuth2 flow):

  - Get authorization code from the user
  - Issuing the access token and refresh token through code
  - Issuing access tokens through refresh tokens

- Global validations:
  - Rate Limiting
  - Request Size Limiting
