# Bench-Kitura-SwiftMetrics
Performance benchmarks for Kitura

## Descriptions of benchmarks (targets)

### HelloWorld

A simple benchmark which responds to:
- http://localhost:8080/plaintext with `Hello, World!`
- http://localhost:8080/json with `{ "message": "Hello, World!" }`

HeliumLogger is enabled (`.info` level).

### HelloWorldSwiftMetrics and HelloWorldSwiftMetricsHTTP

These workloads are copies of HelloWorld, which enable the SwiftMetrics monitoring:
https://github.com/RuntimeTools/SwiftMetrics

Both enable the periodic collection of metrics (low overhead). The 'HTTP' variant adds HTTP per-request monitoring.
