# Request Size Limiting

All the APIs will accept requests with maximum body size of **15 Megabytes**.

If the request body exceeds this size, the Partner API will return a `413` response, eg:

```http
HTTP/1.1 413 Request Entity Too Large
Connection: keep-alive
Content-Length: 41
Content-Type: application/json; charset=utf-8
Date: Thu, 12 Mar 2020 14:15:38 GMT
Server: kong/1.3.0.1-enterprise-edition

{
    "message": "Request size limit exceeded"
}
```

> If the request exceeds the maximum size, it won't affect the [request rates](rate_limiting.md) of the Partner
