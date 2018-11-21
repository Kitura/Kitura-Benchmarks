-- example HTTP POST script which demonstrates setting the
-- HTTP method, body, and adding a header

wrk.method = "POST"
wrk.body   = "\27\0\0\0\2value\0\11\0\0\0Hello BSON\0\0"
wrk.headers["Content-Type"] = "application/bson"
wrk.headers["Accept"] = "application/bson"
