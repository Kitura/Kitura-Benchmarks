-- example HTTP POST script which demonstrates setting the
-- HTTP method, body, and adding a header

wrk.method = "POST"
wrk.body   = [[{"value":"Hello JSON"}]]
wrk.headers["Content-Type"] = "application/json"
wrk.headers["Accept"] = "application/json"
