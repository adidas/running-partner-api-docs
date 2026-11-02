# Webhooks

Webhooks allow you to be notified of events that occur in Running App, like when a user finishes an sport activity.

## Entities

There are three classes of entities which power the webhooks ecosystem:

* Receiver
* Subscription
* Notification

The next sections describe those entities in detail.

> All data representing dates in this document, are based on UTC Timestamps. When being rendered as an HTTP Response, it will be formatted as follows: `yyyy-mm-dd hh:mm:ss`.

### Receiver

The Receiver entity holds the URL (also known as the "webhook URL") that will receive `POST` requests with updates regarding an associated user.

It is possible to have multiple receivers, although having just one should be enough for most use cases.
</br>
```yaml json_schema
title: Receiver
type: object
properties:
  webhook_url:
    type: string
    format: uri
    pattern: ^https
    example: 'https://www.example.com'
    description: URL to where the notifications will be sent via HTTPS POST
  state:
    type: string
    enum:
      - active
      - deactivated
      - failure
    description: Current state of the receiver
  api_version:
    type: integer
    description: API this webhook is using. Currently only `0` available.
    example: 0
  failure_reason:
    type:
      - string
      - 'null'
    description: 'When the state of the webhooks is `failure`, this field will contain the reason the webhook failed to be executed.'
  signing_secret:
    type: string
    example: k7xkKLrM1RVjO4G7OgEeAC3OdnBlsxpoCInupCQEBoc=
    description: Secret used to sign webhook payload. This property will only be returned by the create endpoint!
  created_at:
    type: string
    format: date-time
    example: '2021-01-14T06:19:41Z'
    description: Date and time of creation
  updated_at:
    type: string
    format: date-time
    example: '2021-01-14T06:19:41Z'
    description: Date and time of the most recent update
required:
  - webhook_url
  - state
  - api_version
  - signing_secret
  - created_at
  - updated_at
examples:
  - webhook_url: 'https://www.example.com'
    state: active
    api_version: 0
    failure_reason: null
    signing_secret: k7xkKLrM1RVjO4G7OgEeAC3OdnBlsxpoCInupCQEBoc=
    created_at: '2021-01-14T06:19:41Z'
    updated_at: '2021-01-14T06:19:41Z'

```

#### Security considerations

Webhook URLs must be HTTPS. That is, TLS is a must.

TLS version 1.2 or above should be used. Version 1.1 is still allowed, but will be eventually be dropped out. Versions below 1.1 are not allowed and will cause the webhook delivery to fail.

A valid certificate is also required. Self-signed certificates won't be accepted and will cause a webhook delivery to fail.

#### Receivers lifecycle

A receiver is directly related to many notifications, which contain the data that will be sent via POST request to the webhook URL.

<!-- theme: warning -->
>If a notification fails to be delivered multiple times, the associated Receiver will have its state switched to `failure`, which means that new notifications won't be delivered until the Receiver is re-activated. Check [Notifications lifecycle](#notifications-lifecycle).

When a receiver is not active, the associated notifications won't be sent immediately. Once the receiver switches from the `failure` state to the `active` state all the pending notifications **from the last 30 days** will be sent.

It's possible to re-activate a receiver via the [Update Receiver API](../../reference/index.md).

### Subscription

A Subscription binds a list of event types (also known as "topics") from a specific user to a Receiver. A Receiver entity will likely have several Subscription entities bound to it.
</br>
```yaml json_schema
title: Subscription
type: object
properties:
  receiver_id:
    type: string
    format: uuid
    description: The ID of the Receiver bound to this entity
  user_id:
    type: string
    format: uuid
    description: The ID of the user whose events will be listened to
  topics:
    type: array
    description: A set of event types that will trigger this webhook
    items:
      type: string
      example: 'activity:created'
      enum:
        - 'activity:created'
        - 'access_grant:deleted'
  created_at:
    type: string
    format: date-time
    description: Date and time of creation
  updated_at:
    type: string
    format: date-time
    description: Date and time of the most recent update
required:
  - receiver_id
  - user_id
  - topics
  - created_at
  - updated_at
examples:
  - receiver_id: b45de99a-9158-413b-a559-77a398e208f3
    user_id: a169451c-8525-4352-b8ca-070dd449a1a5
    topics:
      - 'activity:created'
    created_at: '2019-08-24T14:15:22Z'
    updated_at: '2019-08-24T14:15:22Z'
```

Check [how to retrieve the `user_id` when issuing access tokens](../../authentication/v1/partner_in_behalf_of_user.md#openid-scope).

### Notification

Notification is the entity that holds the information that will be sent via webhooks. Besides the payload itself, it also handles how many times it tried to be delivered and also what was the response received from the `Receiver` URL.

#### Notification delivery

The delivery of a webhook is performed via an HTTP POST request. The usage of TLS with a valid certificate is a must.

Every time an event of type "X" occurs for a user with ID "Y", the webhooks system will match all `Subscription` entities that contain "X" in the `topics` attribute and whose `user_id` attribute equals "Y". For all matches, a `Notification` entity will be created.

Each Subscription entity fires one webhook with the `Notification` info for each event that triggered it. An exception to this rule is that when the delivery of the HTTP request fails, it will be retried a few more times, thus generating more requests.

The webhook request must respond with the correct HTTP response code and in a timely manner. If it doesn't, the delivery will be considered unsuccessful. See the [Notifications lifecycle](#notifications-lifecycle) section for more information on that and also on how the retry scheme works.

#### Request body

All webhooks carry a payload with a fixed format. The MIME type is always `application/json` with UTF-8 encoding. The root object is always a JSON object with the following attributes:
</br>
```yaml json_schema
title: Notification body
type: object
properties:
  id:
    type: string
    format: uuid
    example: 5f46acc2-2ee2-44b8-aee1-d8fccb77613f
    description: The unique identifier for the Notification being delivered
  occurred_at:
    type: string
    description: The timestamp of when the notification was generated
    format: date-time
    example: '2021-05-17T09:01:14.000+00:00'
  topic:
    type: string
    enum:
      - 'activity:created'
      - 'access_grant:deleted'
    example: 'activity:created'
    description: The kind of event that triggered the notification
  user_id:
    type: string
    format: uuid
    example: dd594643-4aba-4411-92a9-5e5d0fbb3e48
    description: The ID of the user associated with this notification
  data:
    oneOf:
      - properties:
          notification_id:
            type: string
            format: uuid
            example: 2426a1cc-5930-45f7-8345-eba1d4ddb1eb
          user_id:
            type: string
            example: dd594643-4aba-4411-92a9-5e5d0fbb3e48
            format: uuid
          activity_id:
            type: string
            format: uuid
            example: 3f007e97-727a-4eff-aafb-817460055019
            description: required if topic is activity:created
    description: Information that varies accordingly to the given topic
    type: object
required:
  - id
  - occurred_at
  - topic
  - data
examples:
  - id: 5f46acc2-2ee2-44b8-aee1-d8fccb77613f
    occurred_at: '2021-05-17T09:01:14.000+00:00'
    topic: 'activity:created'
    user_id: dd594643-4aba-4411-92a9-5e5d0fbb3e48
    data:
      notification_id: 2426a1cc-5930-45f7-8345-eba1d4ddb1eb
      user_id: dd594643-4aba-4411-92a9-5e5d0fbb3e48
      activity_id: 3f007e97-727a-4eff-aafb-817460055019

```

In case of `activity:created` you can fetch the information about the performed activity by extracting the `data.activity_id` and use Get Activity API endpoint to fetch that information.

#### Request headers

The following HTTP headers are sent along in every request:
```yaml json_schema
title: Request headers
type: object
properties:
  Runtastic-Retry-Count:
    type: integer
    minimum: 0
    maximum: 5
    example: 0
    description: It represents how many times this notification failed to be sent
  Runtastic-Api-Version:
    type: integer
    example: 0
    minimum: 0
    description: The API version that was used to create the Subscription
  Runtastic-Signature:
    type: string
    description: The signature to check the authenticity of the request
    example: t=1621242074; sha256=8ea998ab1b348fcdd7878646713a2476442b5121177e1f5529d6b9973a916a6e
required:
  - Runtastic-Retry-Count
  - Runtastic-Api-Version
  - Runtastic-Signature
```

#### Verifying the request authenticity

To verify the message authenticity, you first have to extract the `t` and `sha256` values off the `Runtastic-Signature` header of the request.

```
Runtastic-Signature: t={UNIX_TIMESTAMP}; sha256={SHA256_HMAC_MESSAGE}
```

`t` represents the time when the request was made in UTC time (unix timestamp)

<!-- theme: warning -->
> ##### Mitigate replay attacks
>You should compare the timestamp value to the current time when you receive the request. If the values differ by more than one minute, the request should be rejected (we suggest returning `403 Forbidden` HTTP response for this case).

`sha256` is the result of the SHA-256 HMAC encryption of the webhook payload and the `t` using the `signing_secret` from the related Receiver

To perform the verification, you first need to build the payload for the HMAC function. This payload is the concatenation of three components:

1. The timestamp `t`
2. A dot character (`.`)
3. The body of the request, untransformed

The calculation of the signature is given by performing a SHA-256 HMAC on the payload described above and using the `signing_secret` from its `Receiver` as the key.

<!-- theme: warning -->
> ##### Reject inauthentic webhooks
>If the received `sha256` doesn't match the calculated sha256 message, the request must be rejected (we suggest returning `403 Forbidden` HTTP response for this case).

##### Example

Let's say that you have a Receiver entity with the following `signing_secret`:

```
WBq7ifFlji9TIFuV6cXAnkGSNot5EL9yj2uSzeJF5l3bUhDxo4DNzRZfd8xuWbwo
```

and you receive the following webhook request:

```http
POST /webhook_endpoint HTTP/1.1
Host: webhooks.example.com
Date: Fri, 06 Dec 2019 09:13:14 -0000
Content-Type: application/json
Content-Length: 19
Runtastic-Retry-Count: 0
Runtastic-Api-Version: 0
Runtastic-Signature: t=1575623594; sha256=813771868026829c936de06d7efdd131eb9f0bab09ae49501d7f8cfdb6da0f24

{"api":"runtastic"}
```

Extracting the `t` value from the `Runtastic-Signature` will give you `1575623594`. The payload for the HMAC function will be the following:

```
1575623594.{"api":"runtastic"}
```

Supposing the HMAC function signature is `HMAC(algorithm, key, payload)`, it would be called like

```ruby
HMAC(
  'SHA-256',
  'WBq7ifFlji9TIFuV6cXAnkGSNot5EL9yj2uSzeJF5l3bUhDxo4DNzRZfd8xuWbwo',
  '1575623594.{"api":"runtastic"}'
)
```

and would return the string
```
813771868026829c936de06d7efdd131eb9f0bab09ae49501d7f8cfdb6da0f24
```
which matches the received `sha256` from the `Runtastic-Signature` header.

Then, in this scenario, the request is authentic.

#### Notifications lifecycle

A notification can fail to be delivered due to a few reasons. Among them are DNS failure, TCP/IP failures (connection errors), TLS negotiation failure _etc_. Those are mostly errors related to the underlying transport mechanism.

Another type of failure is when the webhook request doesn't respond as it should.

<!-- theme: warning -->
>All webhook requests must respond in **a maximum of 15 seconds** with status code **200**, **201** or **204**. Any other status codes (including 3XX) will be considered a delivery failure.

If you need to perform some processing that could take longer than that, you should perform the processing asynchronously.

In case the delivery fails, due to any reason (e.g. transport failure, wrong status code, request timeout _etc_), the delivery will be retried.

> Each notification will try to be delivered **25 times**, with the following interval retry rule (in seconds): `(retry_count**4) + 15 + (rand(30) * (retry_count + 1))`

If a notification fails to be delivered all the 25 times, the Receiver directly related to it will switch its state to `failure`, which means that new notifications won't be sent until it is re-activated.
