# Kitura-Bench-TechEmpower
This project contains a number of Kitura-based implementations of the TechEmpower benchmarks using different database connectors.

The majority of the source is a replica of https://github.com/TechEmpower/FrameworkBenchmarks/tree/master/frameworks/Swift/kitura and should be kept in sync whenever that upstream project is updated.

This project implements the 6 benchmarks specified by the FrameworkBenchmarks project (https://github.com/TechEmpower/FrameworkBenchmarks/wiki/Project-Information-Framework-Tests-Overview).

- `TechEmpower`: an implementation of the simple `/plaintext` and `/json` benchmarks (that do not involve DB interaction).
- `TechEmpowerPostgres`: an implementation of the DB benchmarks on Kitura, using the Swift-Kuery-PostgreSQL database connector. There is no use of the ORM, therefore this is considered a 'raw' implementation.
- `TechEmpowerPostgresORM`: Equivalent to `TechEmpowerPostgres`, but uses Swift-Kuery-ORM.
- `TechEmpowerPostgresORMCodable`: Equivalent to `TechEmpowerPostgresORM`, but uses Codable routing where possible (`/db`, `/queries` and `/updates`). Fortunes uses raw routing as it is not (currently) possible to return HTML from a Codable route.
- `TechEmpowerMongoKitten`: an alternate implementation of `TechEmpowerPostgres`, talking to MongoDB using MongoKitten.
- `TechEmpowerCouch`: A (stale) implementation using Kitura-CouchDB. Note that CouchDB is not a DB backend that TechEmpower supports.


The `TechEmpowerPostgres` (et al) targets require a database, for which you can follow the steps below.

# Initial Setup

## Install Postgres

```
apt-get install postgresql
```

### Clone the TechEmpower FrameworkBenchmarks project

```
git clone https://github.com/TechEmpower/FrameworkBenchmarks.git
```

### Create the hello_world database

After this point, you can use the provided `postgres_ramdisk.sh` script to set everything up a ramdisk for you (usage: `postgres_ramdisk.sh start | stop | status`).  Make sure to read the comments at the top of the script first and customize if required.

Alternatively, follow the steps below:

### Set up benchmark userid and database

This script from the TechEmpower project will create the `benchmarkdbuser`, and create and populate the `hello_world` database:
```
cd FrameworkBenchmarks/toolset/setup/linux/databases/postgresql
sudo su - postgres -c "psql -f $PWD/create-postgres-database.sql"
psql -U benchmarkdbuser -f create-postgres.sql hello_world
```

### Set up remote access (optional)

To allow remote connections from the benchmark DB user, edit `/etc/postgresql/xx/main/pg_hba.conf`
Add an entry to enable access from a specific host or subnet, for example:

```
# host  DATABASE     USER             ADDRESS         METHOD      [OPTIONS]
host    hello_world  benchmarkdbuser  192.168.0.0/24  password
```

## Install workload driver

Install the build dependencies:
```
sudo apt-get install gcc make
```
Clone and build:
```
git clone https://github.com/wg/wrk.git
cd wrk
make
```

This will build the `wrk` tool. You may want to add the wrk executable to your path or to `/usr/local/bin`:
```
sudo cp wrk /usr/local/bin
```

## Install Swiftenv (optional)

Swiftenv makes it easy to obtain the Swift binary which has been tested with this project.
See: https://github.com/kylef/swiftenv

### Install Swift binary

```
swiftenv install
```

## Build Kitura application

Install dependencies:
```
sudo apt-get install libcurl4-openssl-dev libssl-dev libpq-dev
```
Build the Swift applications with release optimizations:
```
swift build -c release
```

# Driving Benchmark

In separate terminal windows, start Kitura, and then start the workload driver:
```
env DB_HOST="localhost" DB_PORT="5432" .build/release/TechEmpowerPostgres
wrk -c128 -t4 -d30s http://127.0.0.1:8080/db
```
This example exercises the Single Database Query test against the local Postgres database.

## Database configuration

The database hostname and port can be set with the `DB_HOST` and `DB_PORT` environment variables, as per the example above.

These values, as well as the database name, username and password can also be set in the `config.json` file at the top level of the project.

An alternative location for this configuration file can be specified by setting the `TFB_DB_CONFIG` environment variable, which can either be an absolute path, or relative to the current working directory.

## TechEmpower tests

Below are the driver commands which approximate the TechEmpower benchmark suite:

### Test 1 (JSON)
```
wrk -H 'Host: localhost' -H 'Accept: application/json,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7' -H 'Connection: keep-alive' --latency -d 15 -c 8 --timeout 8 -t 2 http://127.0.0.1:8080/json
```
This runs the workload driver with 8 concurrent connections (`-c 8`). TechEmpower tests with 8, 16, 32, 64, 128 and 256 connections.

### Test 2 (DB)
```
wrk -H 'Host: localhost' -H 'Accept: application/json,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7' -H 'Connection: keep-alive' --latency -d 15 -c 8 --timeout 8 -t 2 http://127.0.0.1:8080/db
```
This runs the workload driver with 8 concurrent connections (`-c 8`). TechEmpower tests with 8, 16, 32, 64, 128 and 256 connections.

### Test 3 (Queries)
```
wrk -H 'Host: localhost' -H 'Accept: application/json,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7' -H 'Connection: keep-alive' --latency -d 15 -c 256 --timeout 8 -t 2 http://127.0.0.1:8080/queries?queries=1
```
This runs the workload driver with 256 concurrent connections, and a single DB query per request (`?queries=1`). TechEmpower tests with 1, 5, 10, 15 and 20 queries per request.

### Test 5 (Updates)
```
wrk -H 'Host: localhost' -H 'Accept: application/json,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7' -H 'Connection: keep-alive' --latency -d 15 -c 256 --timeout 8 -t 2 http://127.0.0.1:8080/updates?queries=1
```
This runs the workload driver with 256 concurrent connections, and a single DB query/update operation per request (`?queries=1`). TechEmpower tests with 1, 5, 10, 15 and 20 queries per request.

### Test 6 (Plaintext)
```
wrk -H 'Host: localhost' -H 'Accept: text/plain,text/html;q=0.9,application/xhtml+xml;q=0.9,application/xml;q=0.8,*/*;q=0.7' -H 'Connection: keep-alive' --latency -d 15 -c 256 --timeout 8 -t 2 http://127.0.0.1:8080/plaintext -s ~/pipeline.lua -- 16
```
This runs the workload driver with 256 concurrent connections (`-c 256`). TechEmpower tests with 256, 1024, 4096 and 16384 concurrent connections.

Note, TechEmpower uses HTTP Pipelining for the Plaintext test. This is implemented in a LUA script which can be downloaded here: 
https://github.com/TechEmpower/FrameworkBenchmarks/blob/master/toolset/wrk/pipeline.lua
