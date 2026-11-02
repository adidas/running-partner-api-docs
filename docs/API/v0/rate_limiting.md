# Rate Limiting

The APIs offered by Running App in the Partner API have specific rate limits for different time windows that are shared among all the endpoints.

<!-- theme: warning -->

>All the endpoints in the Partner API have rate limiting of **10,000 requests per hour** and **200 requests per minute**. Note that this configuration is per-partner (not per Running App user) and can be subject to change without prior notice.

The requests with invalid credentials (expired/invalid access token or invalid authentication key) **will not affect** the remaining requests of any timeframe.

All the requests [successfully authenticated](../../authentication/v1/index.md) and with [valid request size](request_size_limiting.md) will return HTTP headers representing the maximum requests count and the remaining requests count for each timeframe following the pattern:

```
X-RateLimit-Limit-{TIMEFRAME}: {MAX}
X-RateLimit-Remaining-{TIMEFRAME}: {REMAINING}
```

*where `TIMEFRAME` can be: `second`, `minute`, `hour`, `day`, `month` and `year`*.

`MAX` represents the maximum number of requests that can be done in the given `TIMEFRAME`.

`REMAINING` represents the number of requests that can still be done inside the given `TIMEFRAME`.

When one of the limits is reached, a response with 429 status code will be returned with the following format:


<!-- title: Example with limits of 5 requests per hour and 1 request per second -->
```http
HTTP/1.1 429 Too Many Requests
Connection: keep-alive
Content-Length: 37
Content-Type: application/json; charset=utf-8
Date: Mon, 10 Feb 2020 17:15:55 GMT
Server: kong/1.4.2
X-Kong-Response-Latency: 2
X-RateLimit-Limit-hour: 5
X-RateLimit-Limit-second: 1
X-RateLimit-Remaining-hour: 3
X-RateLimit-Remaining-second: 0

{
    "message": "API rate limit exceeded"
}
```

It's possible to identify which timeframe limit was reached based on the response headers. In the example above, the value of the header `X-RateLimit-Remaining-second`  is `0`.

