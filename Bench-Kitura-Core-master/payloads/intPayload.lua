-- example HTTP POST script which demonstrates setting the
-- HTTP method, body, and adding a header

wrk.method = "POST"
wrk.body   = [[
{
  "3": 1234,
  "4": 1234,
  "2": 1234,
  "6": 1234,
  "9": 1234,
  "10": 1234,
  "8": 1234,
  "7": 1234,
  "1": 1234,
  "5": 1234
}
]]
wrk.headers["Content-Type"] = "application/raw"
