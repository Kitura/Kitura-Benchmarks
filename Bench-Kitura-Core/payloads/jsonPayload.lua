-- example HTTP POST script which demonstrates setting the
-- HTTP method, body, and adding a header

wrk.method = "POST"
wrk.body   = [[{
  "3": 1234.1,
  "4": 1234.1,
  "2": 1234.1,
  "6": 1234.1,
  "9": 1234.1,
  "10": 1234.1,
  "8": 1234.1,
  "7": 1234.1,
  "1": 1234.1,
  "5": 1234.1
}]]
wrk.headers["Content-Type"] = "application/json"
