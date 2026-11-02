# Partner in behalf of User Authentication

The user's consent is required to access their Running App information. To do so, the
[Authorization Code Grant flow](https://tools.ietf.org/html/rfc6749#section-4.1) must be implemented
from the Partner side.

## Getting an access token

In order to perform any request to the API, you will need an access token.
Remember that all requests **from this section** are performed in behalf of a Running App user and
the access token is tied to the user.

There are a few steps for the whole authentication flow. The following sections
describe the necessary steps. The following sequence diagram illustrates the whole process:

![Partner authorization code flow](../../assets/images/partner_in_behalf_of_user_auth.png)

<!--
sequenceDiagram
Partner Website->>Running App Auth Server: Sends user to consent page
Note right of Partner Website: CLIENT_ID
Running App Auth Server->>Running App Auth Server: User performs authentication
Running App Auth Server->>Running App Auth Server: User consents to the asked scopes
Running App Auth Server- ->>Partner Website: Redirects to redirect_uri
Note left of Running App Auth Server: CODE
Partner Website->>Running App Auth Server: Requests access token for the user
Note right of Partner Website: CODE, CLIENT_ID, CLIENT_SECRET
Running App Auth Server- ->>Partner Website: Returns access token
Note left of Running App Auth Server: ACCESS_TOKEN, REFRESH_TOKEN
-->

### Get authorization from the user

To get the OAuth 2.0 Authorization Code Grant flow started, the first step is to get the user to the
following page:

```
https://accounts.runtastic.com/v1/as/authorization.oauth2
?client_id={CLIENT_ID}
&response_type=code
&scope={SPACE_SEPARATED_SCOPES}
&pfidpadapterid=refid
&redirect_uri={YOUR_APP_CALLBACK_URL}
&state={OPTIONAL_CUSTOM_DATA}
```
Linebreaks were added for clarity only; that is supposed to be one full URL.

The minimum required scopes are `pa_identity` and `openid` plus one of our activity scopes (`pa_activity_read` or `pa_activity_write`)

This will likely be a link in your app that will get the user to that URL via a
web browser. That page will take care of having the user log in the Running App
system and display a consent screen asking for permission so that your app
may access the user's data. The pieces of data that will be asked for are the ones
that you include in the "scope" parameter of the URL above.
You should always ask for the most restricted set of scopes that are needed for
your app to work. Do not ask for data that won't be used by your app.

Note: The web browser is necessary since OAuth 2.0 is designed with it in
mind. There is no way around it.

<!-- theme: warning -->

> ##### Do not use webviews
> Webviews block pop-ups, meaning that users that use social logins (Google / Apple / Facebook) won't be able to login as the pop-up to enter credentials will not be shown. Thus always open the flow in the users native browser.

The placeholders in the query string parameters should be filled in with the
appropriate values. The parameters are described as follows:

- **client\_id**: This must have the `client_id` that we provided for your app
- **response\_type**: It must be the string `code`
- **scope**: A list with the scopes the user will give your app consent. The list items are separated by space. Besides `pa_identity` and `openid`, which always need to be requested, the following scopes can be used*:
  - `pa_activity_read`: The user grants your app the permission to read all of the users activities
  - `pa_activity_write`: The user grants your app the permission to create new activities
- **pfidpadapterid**: It must be the string `refid`
- **redirect\_uri**: The URL the user will be redirected to when the OAuth flow is finished. See notes below on how to use this parameter
- **state**: This parameter is optional. You can send any data here and it will be sent along in the **redirect\_uri**

**If made available to you via our contract*

<!-- theme: warning -->

> Never send the `client_secret` value in the URL above, as doing so would publicy expose the secret

Note that the value of the `redirect_uri` parameter must exactly match one of
the URLs you sent us when requesting access to the API. Thus, this value is
whitelisted. Also note that you must not include any query string in this
URL (i.e. no `?` in the URL). Rather than using the query string, you should
use the `state` parameter as it will be appended as a parameter when redirecting
the user to the URL in `redirect_uri`.

In case the user denies access in the consent screen, the redirect to the
`redirect_uri` will still occur. However, the `code` parameter will not be
included and instead, the parameters `error_description` and `error` will be
set. The value of `error` will be `access_denied`, and `error_description`
will include a textual description of the error.

### Issuing the access token and refresh token

When the OAuth flow is finished and consent has been successfully granted, the user will
be redirected, in the web browser, to the URL you provided in the `redirect_uri`
parameter in the URL above. The redirect will add a query string parameter
named `code` that will be exchanged for the access token and refresh token.

If you sent a `state` attribute to the authorization URL, it will be sent along
with the same name, as a query parameter, in this redirect. Its value is left
untouched and it is opaque to us, so the value you provided won't be modified
in any way.

The backend behind the `redirect_uri` must be under your control. It must
immediately exchange the authorization code (that is, the `code` parameter)
with the access token by performing a POST HTTP request to the URL
`https://accounts.runtastic.com/v1/as/token.oauth2`.

The contents of the request must be encoded as in the `application/x-www-form-urlencoded` MIME type ([see more](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods/POST)).

The parameters to be sent in the body are the following:

- **grant_type**: It must be the string `authorization_code`
- **client_id**: The `client_id` of your app
- **client_secret**: The `client_secret` of your app
- **code**: The authorization code you received in the redirect URL
- **redirect_uri**: The `redirect_uri` that you used in the authorization URL
(the one in the first step of the OAuth flow)

> This call must be performed from the server side, never from a
web browser or mobile client, as that would expose the client_secret value.

The response will be a JSON encoded object. An example response is as follows:

```json
{
  "access_token": "abfWbvNnG8jhbYBt1eABoi",
  "refresh_token": "3yDbEc22RjJDBTJHwnnyPFwFzVOqjKk4V0A47RwhwdRjkdJFFkLI2E1GtbBmHzqm2MlhJZmf4B4RIJTnaGL7Ln2SZSzKx0c2Px7lb5iW0txIPhGcRV2elF7IZtn6jMzr",
  "token_type": "Bearer",
  "expires_in": 7199
}
```

The `access_token` and `refresh_token` attributes contain the access and refresh tokens, respectively. You must store these in a safe place and they
must never be shared. The `expires_in` attribute tells how long, in seconds, until the access token expires. In the example above, it is valid within the
next 120 minutes from when the request was performed.

It can also be that the response includes an `id_token` attribute. Its content
is a [JWT](https://jwt.io/) which includes information regarding the user.
The `sub` claim of the JWT corresponds to the user ID. The user ID is useful
to identify the user when receiving [webhooks](../../API/v0/webhooks.md).

At this point you can already perform API calls using the access token.

See the following sections for information on how to use the access token and
how the expiry time and refresh tokens should be dealt with.

#### OpenID scope

In order to retrieve information from the user associated with the access token, the scope
`openid` must be added in the `SPACE_SEPARATED_SCOPES`.

If that's done, the requests to issue access tokens will return the attribute `id_token`, which is
a [JWT](https://jwt.io/) with information regarding the user in its payload, eg.:

```json
{
    "access_token": "DAwD8r2mL91Z7J6aAp9JFEHj9Q8aD20Fl0xAazwg7SsIabdqQC1lzHGWVFGMyhp7tVgSbUnKKe8sWDrfvqo0JYZQwqYdZMB4qRNZzdOBtR<EXAMPLE>",
    "refresh_token": "23DF5LuLI5WGyo9zoRFoD3RhbSkdo1aXJiQ36ZCCbmU0waufafOl2pVTMwOwxDL201eE7n91jBO0HlTVKAuSwmIVxmNwoueLDE02AsaD<EXAMPLE>",
    "id_token": "eyJhbGciOiJSUzI1NiIsImtpZC2RHBBck9iUmRSSVcifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzL0vdjEiLCJpYXQiOjE2MTU5MTA2OTUsImV4cCI6MTY0NzQ0NjY5NSwiYXVkIjoicGFwaV9wYXJ0bmVyIiwic3ViIjoiQUxEQzRNTjEyRURBQjlHSCJ9.h3RoExoZgwCQO16QUJFGaG9GluRXxuYib3HKBPuJR-oTl-3AlzgpgpZsbHkaCPvRDlaQNsgZDXMXCY3Aq4GAgUYjzXE2-2FaLw1eQu1anSahKiiW4z7R0nAmjoTwfwhIVSg6d0ourNA8f-ahNu8A2PXQvx2sbGQPKdMSeeA05f_1f-7nDXKEpIrW9qAdgwFNw-4nnk_fl1Nqq6Qni4D6XIcZAdIDT6dnP_uNVMAInAnqAJcDtT8bIxxsbJfe8-5tu7ko_HMu3yM6TZr_cA<EXAMPLE>",
    "token_type": "Bearer",
    "expires_in": 899
}
```

The decoded JWT payload results in:

```json
{
  "sub": "ALDC4MN12EDAB9GH",
  "aud": "papi_partner",
  "jti": "eEym4uPLXgGc4f<EXAMPLE>",
  "iss": "https://accounts.runtastic.com/v1",
  "iat": 1615897609,
  "exp": 1615897909
}
```

> The `sub` attribute represents the `user_id`.

### Issuing access tokens through refresh tokens

The section above demonstrates how to issue an access token given that you have
the authorization code. This section extends that one, but applies to the case
where you don't have the authorization code anymore (since it is used only once)
and want to issue a new access token.

To perform that, the same rules as for the previous section apply. That is the same
URL (`https://accounts.runtastic.com/v1/as/token.oauth2`) and format is to be used here.

What is changed is the body payload. In this case, the authentication itself occurs with the refresh token rather than the authorization code. The body
payload for the HTTP request takes the following attributes:

- **grant_type**: Its value must be the string `refresh_token`
- **client_id**: The `client_id` of your app
- **client_secret**: The `client_secret` of your app
- **refresh_token**: The refresh token that you previously received
- **redirect_uri**: The `redirect_uri` that you used in the authorization URL
(the one in the first step of the OAuth flow)

The response payload will look like the following:

```json
{
  "access_token": "3ShyuHkKPsWUwFq4<EXAMPLE>",
  "token_type": "Bearer",
  "expires_in": 7199
}
```

## Performing authenticated API requests

Once you have the access token, you can perform authenticated API requests.

Just add the `Authorization` header to every API request. It takes the following
form:

```
Authorization: Bearer {ACCESS_TOKEN}
```

For instance, if your access token is `sbfWbvBnG8jhbYBt1eJAoi`, then just add
the following header to your requests:

```
Authorization: Bearer sbfWbvBnG8jhbYBt1eJAoi
```

Although the authentication is very simple, there are a few gotchas due to the
fact that OAuth 2.0 access tokens have an expiry time. Please see the next
section for more details on how to handle expired access tokens and best
practices.

## Revoking a token

It is possible to revoke a token, be it a refresh token or an access token.
The revocation endpoint is implemented as specified in
[RFC 7009](https://tools.ietf.org/html/rfc7009). It is located at
`https://accounts.runtastic.com/v1/as/revoke_token.oauth2`.

<!-- theme: warning -->

> In the case that the user requests that their account gets disconnected from adidas Running App, it is mandatory that you call this endpoint to revoke all refresh tokens of this user.

The contents of the request must be encoded as in the
application/x-www-form-urlencoded MIME type.

> When a refresh token is revoked, all access tokens issued by it are automatically revoked as well.

To revoke a token, just issue a POST request to that endpoint passing
in the following parameters:

- **client_id**: The `client_id` of your app
- **client_secret**: The `client_secret` of your app
- **token**: The token to be revoked

On success, the response will have an empty body with a 200 status code.

## Access token best practices

Since OAuth 2.0 is rather complex, due to the inherent complexity of having a
secure software system, this section aims to avoid issues when dealing with
access token expiry times and refresh tokens.

### Access token expiration

Access tokens will have a short expiration time. Usually not more than a few
hours. Once an access token is expired, calling the API with it will yield
the same results as calling it with an invalid token. That is because the
token has, in fact, been invalidated.

The access token may also expire before its expiry date. However, that should
be considered an edge case and unlikely to happen often.

See the "handling expired tokens" section below on how to handle token
expiration.

### Refresh token expiration

The refresh token does not expire.

In general, this means the refresh token does not change. However, it can be
revoked if it gets compromised (see [revoking a token](#revoking-a-token)).

### Handling expired tokens

An API call with an invalid or expired access token will result in a "401
Unauthorized" response with the following JSON body payload:

```json
{
  "error": "invalid_token",
  "error_description": "The access token is invalid or has expired"
}
```

Your app must be prepared to handle expired access tokens at any time.
In order to recover from an expired access token, your app has to request a new
access token by using the refresh token. Remember that the refresh token does not expire. See section
[Issuing access tokens through refresh tokens](#issuing-access-tokens-through-refresh-tokens)
for how to issue a new access token using the refresh token.

It is possible to have more than one valid access token at the same time.
This fact should make it easier to manage the access token. However, your app
must not issue access tokens without any form of control in place, as that
could negatively  impact our infrastructure. For instance, the app should not
issue a new access token at the very beginning of an operation and then
discard it after the operation has finished.

<!-- theme: warning -->

> Your app **must not** issue access tokens without any form of control in place.

Your app should try and keep only one valid access token at a time. Although
this is not a strict requirement, it should be done in a best effort
manner.
