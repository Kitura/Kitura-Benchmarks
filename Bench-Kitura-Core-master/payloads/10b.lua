-- example HTTP POST script which demonstrates setting the
-- HTTP method, body, and adding a header

wrk.method = "POST"
wrk.body   = [[1234567890]]
wrk.headers["Content-Type"] = "application/raw"
