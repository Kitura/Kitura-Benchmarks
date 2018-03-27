# Bench-Kitura-Blog
Performance benchmark for Kitura

## Descriptions of benchmarks (targets)

### Blog

A copy of the Blog and JSON benchmarks originally published by [Ryan Collins](https://github.com/rymcol): https://github.com/rymcol/Linux-Server-Side-Swift-Benchmarking
No logging is enabled.

This responds to:
- http://localhost:8080/ - a generated 'index' HTML page containing a series of embedded images and javascript. Associated resources are stored in `/blog`
- http://localhost:8080/blog - a generated 'blog' HTML page containing a series of embedded images. Associated resources are stored in `/blog`
- http://localhost:8080/json - responds with JSON containing 10 random numbers in the format: `{ "Test Number 9": 763, "Test Number 8": 904, ... }`

This benchmark is interesting as it was used in two studies that Ryan published:
- Mac: https://medium.com/@rymcol/benchmarks-for-the-top-server-side-swift-frameworks-vs-node-js-24460cfe0beb
- Linux: https://medium.com/@rymcol/linux-ubuntu-benchmarks-for-server-side-swift-vs-node-js-db52b9f8270b

The workload exposed a number of early bugs in Kitura, such as the behaviour when responding with large payloads under stress, and cost of JSON serialization with numbers.

