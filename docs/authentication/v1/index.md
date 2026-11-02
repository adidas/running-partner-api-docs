# Authentication

Accessing the Running App Partner API endpoints requires authentication. This is performed by sending
along an access token in the requests following the [OAuth2 RFC](https://tools.ietf.org/html/rfc6749).

This token can refer [only to Partner](partner.md) or
[to a Partner on behalf of a User](partner_in_behalf_of_user.md).

## Application credentials

For authentication, you will need a `CLIENT_ID` along with a corresponding `CLIENT_SECRET`. You
should already have those. If you don't, or if you need assistance with that, you can contact us
through [partnerapi.digitalsports@adidas.com](mailto:partnerapi.digitalsports@adidas.com).

A `CLIENT_ID` represents an app that interacts with the API. Usually you will have only one, which
represents your app. Unless you have more apps, there should be no reason to have more than one `CLIENT_ID`.

## Security considerations

The `CLIENT_ID` can be exposed and shared. However, the `CLIENT_SECRET` **must** be kept in secret in
a safe place. If someone gets access to the `CLIENT_SECRET`, they would be able to issue OAuth 2.0
access tokens on behalf of your app.

In case the `CLIENT_SECRET` gets leaked or stolen, it is very important that you communicate us,
preferrably through the [partnerapi.digitalsports@adidas.com](mailto:partnerapi.digitalsports@adidas.com) email
address so that we can cancel that secret.

## Checklist
The following flows need to be implemented:
* User can connect to adidas running
* User can disconnect from adidas running (All refresh tokens of users that disconnect need to be revoked using our API)
