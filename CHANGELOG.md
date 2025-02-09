# Change log

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this
project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). See [MAINTAINERS.md](./MAINTAINERS.md)
for instructions to keep up to date.

## 1.4.8

### Fixed

* Fixed a bug in `substreams-tier1` and `substreams-tier2` which caused "live" blocks to be sent while the stream previously received block(s) were historic.

### Added

* Added a check for readiness of the `dauth` provider when answering "/healthz" on firehose and substreams


### Changed

* Changed `--substreams-tier1-debug-request-stats` to `--substreams-tier1-request-stats` which enabled request stats logging on Substreams Tier1
* Changed `--substreams-tier2-debug-request-stats` to `--substreams-tier2-request-stats` which enabled request stats logging on Substreams Tier2

## v1.4.7

* Fixed an occasional panic in substreams-tier1 caused by a race condition
* Fixed the grpc error codes for substreams tier1: Unauthenticated on bad auth, Canceled (endpoint is shutting down, please reconnect) on shutdown
* Fixed the grpc healthcheck method on substreams-tier1 (regression)
* Fixed the default value for flag `common-auth-plugin`: now set to 'trusted://' instead of panicking on removed 'null://'

## v1.4.6

### Changed

* Substreams (@v1.1.6) is now out of the `firehose` app, and must be started using `substreams-tier1` and `substreams-tier2` apps!
* Most substreams-related flags have been changed:
  * common: `--substreams-rpc-cache-chunk-size`,`--substreams-rpc-cache-store-url`,`--substreams-rpc-endpoints`,`--substreams-state-bundle-size`,`--substreams-state-store-url`
  * tier1: `--substreams-tier1-debug-request-stats`,`--substreams-tier1-discovery-service-url`,`--substreams-tier1-grpc-listen-addr`,`--substreams-tier1-max-subrequests`,`--substreams-tier1-subrequests-endpoint`,`--substreams-tier1-subrequests-insecure`,`--substreams-tier1-subrequests-plaintext`,`--substreams-tier1-subrequests-size`
  * tier2: `--substreams-tier2-discovery-service-url`,`--substreams-tier2-grpc-listen-addr`
* Some auth plugins have been removed, the new available plugins for `--common-auth-plugins` are `trust://` and `grpc://`. See https://github.com/streamingfast/dauth for details
* Metering features have been added, the available plugins for `--common-metering-plugin` are `null://`, `logger://`, `grpc://`. See https://github.com/streamingfast/dmetering for details

### Added

* Support for firehose protocol 2.3 (for parallel processing of transactions, added to polygon 'bor' v0.4.0

### Removed

* Removed the `tools upgrade-merged-blocks` command. Normalization is now part of consolereader within 'codec', not the 'types' package, and cannot be done a posteriori.
* Updated metering to fix dependencies

## v1.4.5

* Updated metering (bumped versions of `dmetering`, `dauth`, and `firehose` libraries.)
* Fixed firehose service healthcheck on shutdown
* Fixed panic on download-blocks-from-firehose tool

## v1.4.4

#### Operators

* When upgrading a substreams server to this version, you should delete all existing module caches to benefit from deterministic output

### Substreams changes

* Switch default engine from `wasmtime` to `wazero`
* Prevent reusing memory between blocks in wasm engine to fix determinism
* Switch our store operations from bigdecimal to fixed point decimal to fix determinism
* Sort the store deltas from `DeletePrefixes()` to fix determinism
* Implement staged module execution within a single block.
* "Fail fast" on repeating requests with deterministic failures for a "blacklist period", preventing waste of resources
* SessionInit protobuf message now includes resolvedStartBlock and MaxWorkers, sent back to the client

## v1.4.3

### Highlights

* This release brings an update to `substreams` to `v1.1.4` which includes the following:
  - Changes the module hash computation implementation to allow reusing caches accross substreams that 'import' other substreams as a dependency.
  - Faster shutdown of requests that fail deterministically
  - Fixed memory leak in RPC calls

### Note for Operators

> **Note** This upgrade procedure is applies if your Substreams deployment topology includes both `tier1` and `tier2` processes. If you have defined somewhere the config value `substreams-tier2: true`, then this applies to you, otherwise, if you can ignore the upgrade procedure.

The components should be deployed simultaneously to `tier1` and `tier2`, or users will end up with backend error(s) saying that some partial file are not found. These errors will be resolved when both tiers are upgraded.

### Added

* Added substreams scheduler tracing support. Enable tracing by setting the ENV variables `SF_TRACING` to one of the following:
  - stdout://
  - cloudtrace://[host:port]?project_id=<project_id>&ratio=<0.25>
  - jaeger://[host:port]?scheme=<http|https>
  - zipkin://[host:port]?scheme=<http|https>
  - otelcol://[host:port]

## v1.4.2

### Highlights

* This release brings an update to `substreams` to `v1.1.3` which includes the following:
  - Fixes an important bug that could have generated corrupted store state files. This is important for developers and operators.
  - Fixes for race conditions that would return a failure when multiple identical requests are backprocessing.
  - Fixes and speed/scaling improvements around the engine.

### Note for Operators

> **Note** This upgrade procedure is applies if your Substreams deployment topology includes both `tier1` and `tier2` processes. If you have defined somewhere the config value `substreams-tier2: true`, then this applies to you, otherwise, if you can ignore the upgrade procedure.

This release includes a small change in the internal RPC layer between `tier1` processes and `tier2` processes. This change requires an ordered upgrade of the processes to avoid errors.

The components should be deployed in this order:
1. Deploy and roll out `tier1` processes first
2. Deploy and roll out `tier2` processes in second

If you upgrade in the wrong order or if somehow `tier2` processes start using the new protocol without `tier1` being aware, user will end up with backend error(s) saying that some partial file are not found. Those will be resolved only when `tier1` processes have been upgraded successfully.

## v1.4.1

### Fixed

* Substreams running without a specific tier2 `substreams-client-endpoint` will now expose tier2 service `sf.substreams.internal.v2.Substreams` so it can be used internally.

> **Warning**
> If you don't use dedicated tier2 nodes, make sure that you don't expose `sf.substreams.internal.v2.Substreams` to the public (from your load-balancer or using a firewall)


### Breaking changes

* flag `substreams-partial-mode-enabled` renamed to `substreams-tier2`
* flag `substreams-client-endpoint` now defaults to empty string, which means it is its own client-endpoint (as it was before the change to protocol V2)

## v1.4.0

### Substreams RPC protocol V2

Substreams protocol changed from `sf.substreams.v1.Stream/Blocks` to `sf.substreams.rpc.v2.Stream/Blocks` for client-facing service. This changes the way that substreams clients are notified of chain reorgs.
All substreams clients need to be upgraded to support this new protocol.

See https://github.com/streamingfast/substreams/releases/tag/v1.1.1 for details.

### Added

* `firehose-client` tool now accepts `--limit` flag to only send that number of blocks. Get the latest block like this: `fireeth tools firehose-client <endpoint> --limit=1 -- -1 0`

## v1.3.8

### Highlights

This is a bug fix release for node operators that are about to upgrade to Shanghai release. The Firehose instrumented `geth` compatible with Shanghai release introduced a new message `CANCEL_BLOCK`. It seems in some circumstances, we had a bug in the console reader that was actually panicking but the message was received but no block was actively being assembled.

This release fix this bogus behavior by simply ignoring `CANCEL_BLOCK` message when there is no active block which is harmless. Every node operators that upgrade to https://github.com/streamingfast/go-ethereum/releases/tag/geth-v1.11.5-fh2.2 should upgrade to this version.

> **Note** There is no need to update the Firehose instrumented `geth` binary, only `fireeth` needs to be bumped if you already are at the latest `geth` version.

### Fixed

* Fixed a bug on console reader when seeing `CANCEL_BLOCK` on certain circumstances.

### Changed

* Now using Golang 1.20 for building releases.

* Changed default value of flag `substreams-sub-request-block-range-size` from `1000` to `10000`.

## v1.3.7

### Fixed

* Fixed a bug in data normalization for Polygon chain which would cause panics on certain blocks.

### Added

* Support for gcp `archive` types of snapshots

## v1.3.6

### Highlights

* This release implements the new `CANCEL_BLOCK` instruction from Firehose protocol 2.2 (`fh2.2`), to reject blocks that failed post-validation.
* This release fixes polygon "StateSync" transactions by grouping the calls inside an artificial transaction.

If you had previous blocks from a Polygon chain (bor), you will need to reprocess all your blocks from the node because some StateSync transactions may be missing on some blocks.

#### Operators

This release now supports the new Firehose node exchange format 2.2 which introduced a new exchanged message `CANCEL_BLOCK`. This has an implication on the Firehose instrumented `Geth` binary you can use with the release.

- If you use Firehose instrumented `Geth` binary tagged `fh2.2` (like `geth-v1.11.4-fh2.2-1`), you must use `firehose-ethereum` version `>= 1.3.6`
- If you use Firehose instrumented `Geth` binary tagged `fh2.1` (like `geth-v1.11.3-fh2.1`), you can use `firehose-ethereum` version `>= 1.0.0`

New releases of Firehose instrumented `Geth` binary for all chain will soon all be tagged `fh2.2`, so upgrade to `>= 1.3.6` of `firehose-ethereum` will be required.

## v1.3.5

### Highlights

This release is required if you run on Goerli and is mostly about supporting the upcoming Shanghai fork that has been activated on Goerli on March 14th.

### Changed

* Added support for `withdrawal` balance change reason in block model, this is required for running on most recent Goerli Shanghai hard fork.
* Added support for `withdrawals_root` on `Header` in the block model, this will be populated only if the chain has activated Shanghai hard fork.
* `--substreams-max-fuel-per-block-module` will limit the number of wasmtime instructions for a single module in a single block.

## v1.3.4

### Highlights

#### Fixed the 'upgrade-merged-blocks' from v2 to v3

Blocks that were migrated from v2 to v3 using the 'upgrade-merged-blocks' should now be considered invalid.
The upgrade mechanism did not correctly fix the "caller" on DELEGATECALLs when these calls were nested under another DELEGATECALL.

You should run the `upgrade-merged-blocks` again if you previously used 'v2' blocks that were upgraded to 'v3'.

#### Backoff mechanism for bursts

This mechanism uses a leaky-bucket mechanism, allowing an initial burst of X connections, allowing a new connection every Y seconds or whenever an existing connection closes.

Use `--firehose-rate-limit-bucket-size=50` and `--firehose-rate-limit-bucket-fill-rate=1s` to allow 50 connections instantly, and another connection every second.
Note that when the server is above the limit, it waits 500ms before it returns codes.Unavailable to the client, forcing a minimal back-off.

### Fixed

* Substreams `RpcCall` object are now validated before being performed to ensure they are correct.
* Substreams `RpcCall` JSON-RPC code `-32602` is now treated as a deterministic error (invalid request).
* `tools compare-blocks` now correctly handle segment health reporting and properly prints all differences with `-diff`.
* `tools compare-blocks` now ignores 'unknown fields' in the protobuf message, unless `--include-unknown-fields=true`
* `tools compare-blocks` now ignores when a block bundle contains the 'last block of previous bundle' (a now-deprecated feature)

### Added

* support for "requester pays" buckets on Google Storage in url, ex: `gs://my-bucket/path?project=my-project-id`
* substreams were also bumped to current March 1st develop HEAD

## v1.3.3

### Changed

* Increased gRPC max received message size accepted by Firehose and Substreams gRPC endpoints to 25 MiB.

### Removed

* Command `fireeth init` has been removed, this was a leftover from another time and the command was not working anyway.

### Added

* flag `common-auto-max-procs` to optimize go thread management using github.com/uber-go/automaxprocs
* flag `common-auto-mem-limit-percent` to specify GOMEMLIMIT based on a percentage of available memory

## v1.3.2

### Updated

* Updated to Substreams version `v0.2.0` please refer to [release page](https://github.com/streamingfast/substreams/releases/tag/v0.2.0) for further info about Substreams changes.

### Changed

* **Breaking** Config value `substreams-stores-save-interval` and `substreams-output-cache-save-interval` have been merged together as a single value to avoid potential bugs that would arise when the value is different for those two. The new configuration value is called `substreams-cache-save-interval`.

    *  To migrate, remove usage of `substreams-stores-save-interval: <number>` and `substreams-output-cache-save-interval: <number>` if defined in your config file and replace with `substreams-cache-save-interval: <number>`, if you had two different value before, pick the biggest of the two as the new value to put. We are currently setting to `1000` for Ethereum Mainnet.

### Fixed

* Fixed various issues with `fireeth tools check merged-blocks`
    * The `stopWalk` error is not reported as a real `error` anymore.
    * `Incomplete range` should now be printed more accurately.

## v1.3.1

* Release made to fix our building workflows, nothing different than [v1.3.0](#v130).

## v1.3.0

### Changed

* Updated to Substreams `v0.1.0`, please refer to [release page](https://github.com/streamingfast/substreams/releases/tag/v0.1.0) for further info about Substreams changes.

    > **Warning** The state output format for `map` and `store` modules has changed internally to be more compact in Protobuf format. When deploying this new version and using Substreams feature, previous existing state files should be deleted or deployment updated to point to a new store location. The state output store is defined by the flag `--substreams-state-store-url` flag.

### Added

* New Prometheus metric `console_reader_trx_read_count` can be used to obtain a transaction rate of how many transactions were read from the node over a period of time.

* New Prometheus metric `console_reader_block_read_count` can be used to obtain a block rate of how many blocks were read from the node over a period of time.

* Added `--header-only` support on `fireeth tools firehose-client`.

* Added `HeaderOnly` transform that can be used to return only the Block's header a few top-level fields `Ver`, `Hash`, `Number` and `Size`.

* Added `fireeth tools firehose-prometheus-exporter` to use as a client-side monitoring tool of a Firehose endpoint.

### Deprecated

* **Deprecated** `LightBlock` is deprecated and will be removed in the next major version, it's goal is now much better handled by `CombineFilter` transform or `HeaderOnly` transform if you required only Block's header.

## v1.2.2

* Hotfix 'nil pointer' panic when saving uninitialized cache.

## v1.2.1

### Substreams improvements

#### Performance

* Changed cache file format for stores and outputs (faster with vtproto) -- requires removing the existing state files.
* Various improvements to scheduling.

#### Fixes

* Fixed `eth_call` handler not flagging `out of gas` error as deterministic.
* Fixed Memory leak in wasmtime.

### Merger fixes

* Removed the unused 'previous' one-block in merged-blocks (99 inside bundle:100).
* Fix: also prevent rare bug of bundling "very old" one-blocks in merged-blocks.

## v1.2.0

### Added

* Added `sf.firehose.v2.Fetch/Block` endpoint on firehose, allows fetching single block by num, num+ID or cursor.
* Added `tools firehose-single-block-client` to call that new endpoint.

### Changed

* Renamed tools `normalize-merged-blocks` to `upgrade-merged-blocks`.

### Fixed

* Fixed `common-blocks-cache-dir` flag's description.
* Fixed `DELEGATECALL`'s `caller` (a.k.a `from`). -> requires upgrade of blocks to `version: 3`
* Fixed `execution aborted (timeout = 5s)` hard-coded timeout value when detecting in Substreams if `eth_call` error response was deterministic.

### Upgrade Procedure

Assuming that you are running a firehose deployment v1.1.0 writing blocks to folders `/v2-oneblock`, `/v2-forked` and `/v2`,
you will deploy a new setup that writes blocks to folders `/v3-oneblock`, `v3-forked` and `/v3`

This procedure describes an upgrade without any downtime. With proper parallelization, it should be possible to complete this upgrade within a single day.

1. Launch a new reader with this code, running instrumented geth binary: https://github.com/streamingfast/go-ethereum/releases/tag/geth-v1.10.25-fh2.1
   (you can start from a backup that is close to head)
2. Upgrade your merged-blocks from `version: 2` to `version: 3` using `fireeth tools upgrade-merged-blocks /path/to/v2 /path/to/v3 {start} {stop}`
   (you can run multiple upgrade commands in parallel to cover the whole blocks range)
3. Create combined indexes from those new blocks with `fireeth start combined-index-builder`
   (you can run multiple commands in parallel to fill the block range)
4. When your merged-blocks have been upgraded and the one-block-files are being produced by the new reader, launch a merger
5. When the reader, merger and combined-index-builder caught up to live, you can launch the relayer(s), firehose(s)
6. When the firehoses are ready, you can now switch traffic to them.

## v1.1.0

### Added

* Added 'SendAllBlockHeaders' param to CombinedFilter transform when we want to prevent skipping blocks but still want to filter out trxs.

### Changed

* Reduced how many times `reader read statistics` is displayed down to each 30s (previously each 5s) (and re-wrote log to `reader node statistics`).

### Fixed

* Fix `fireeth tools download-blocks-from-firehose` tool that was not working anymore.
* Simplify `forkablehub` startup performance cases.
* Fix relayer detection of a hole in stream blocks (restart on unrecoverable issue).
* Fix possible panic in hub when calls to one-block store are timing out.
* Fix merger slow one-block-file deletions when there are more than 10000 of them.

## v1.0.0

### BREAKING CHANGES

#### Project rename

* The binary name has changed from `sfeth` to `fireeth` (aligned with https://firehose.streamingfast.io/references/naming-conventions)
* The repo name has changed from `sf-ethereum` to `firehose-ethereum`

#### Ethereum V2 blocks (with fh2-instrumented nodes)

* **This will require reprocessing the chain to produce new blocks**
* Protobuf Block model is now tagged `sf.ethereum.type.v2` and contains the following improvements:
  * Fixed Gas Price on dynamic transactions (post-London-fork on ethereum mainnet, EIP-1559)
  * Added "Total Ordering" concept, 'Ordinal' field on all events within a block (trx begin/end, call, log, balance change, etc.)
  * Added TotalDifficulty field to ethereum blocks
  * Fixed wrong transaction status for contract deployments that fail due to out of gas on pre-Homestead transactions (aligned with status reported by chain: SUCCESS -- even if no contract code is set)
  * Added more instrumentation around AccessList and DynamicFee transaction, removed some elements that were useless or could not be derived from other elements in the structure, ex: gasEvents
  * Added support for finalized block numbers (moved outside the proto-ethereum block, to firehose bstream v2 block)
* There are *no more "forked blocks"* in the merged-blocks bundles:
  * The merged-blocks are therefore produced only after finality passed (before The Merge, this means after 200 confirmations).
  * One-block-files close to HEAD stay in the one-blocks-store for longer
  * The blocks that do not make it in the merged-blocks (forked out because of a re-org) are uploaded to another store (common-forked-blocks-store-url) and kept there for a while (to allow resolving cursors)

#### Firehose V2 Protocol

* **This will require changes in most firehose clients**
* A compatibility layer has been added to still support `sf.firehose.v1.Stream/Blocks` but only for specific values for 'ForkSteps' in request: 'irreversible' or 'new+undo'
* The Firehose Blocks protocol is now under `sf.firehose.v2` (bumped from `sf.firehose.v1`).
  * Step type `IRREVERSIBLE` renamed to `FINAL`
  * `Blocks` request now only allows 2 modes regarding steps: `NEW,UNDO` and `FINAL` (gated by the `final_blocks_only` boolean flag)
  * Blocks that are sent out can have the combined step `NEW+FINAL` to prevent sending the same blocks over and over if they are already final

#### Block Indexes

* Removed the Irreversible indices completely (because the merged-blocks only contain final blocks now)
* Deprecated the "Call" and "log" indices (`xxxxxxxxxx.yyy.calladdrsig.idx` and `xxxxxxxxxx.yyy.logaddrsig.idx`), now replaced by "combined" index
* Moved out the `sfeth tools generate-...` command to a new app that can be launched with `sfeth start generate-combined-index[,...]`

#### Flags and environment variables

* All config via environment variables that started with `SFETH_` now starts with `FIREETH_`
* All logs now output on *stderr* instead of *stdout* like previously
* Changed `config-file` default from `./sf.yaml` to `""`, preventing failure without this flag.
* Renamed `common-blocks-store-url` to `common-merged-blocks-store-url`
* Renamed `common-oneblock-store-url` to `common-one-block-store-url` *now used by firehose and relayer apps*
* Renamed `common-blockstream-addr` to `common-live-blocks-addr`
* Renamed the `mindreader` application to `reader`
* Renamed all the `mindreader-node-*` flags to `reader-node-*`
* Added `common-forked-blocks-store-url` flag *used by merger and firehose*
* Changed `--log-to-file` default from `true` to `false`
* Changed default verbosity level: now all loggers are `INFO` (instead of having most of them to `WARN`). `-v` will now activate all `DEBUG` logs
* Removed `common-block-index-sizes`, `common-index-store-url`
* Removed `merger-state-file`, `merger-next-exclusive-highest-block-limit`, `merger-max-one-block-operations-batch-size`, `merger-one-block-deletion-threads`, `merger-writers-leeway`
* Added `merger-stop-block`, `merger-prune-forked-blocks-after`, `merger-time-between-store-pruning`
* Removed `mindreader-node-start-block-num`, `mindreader-node-wait-upload-complete-on-shutdown`, `mindreader-node-merge-and-store-directly`, `mindreader-node-merge-threshold-block-age`
* Removed `firehose-block-index-sizes`,`firehose-block-index-sizes`, `firehose-irreversible-blocks-index-bundle-sizes`, `firehose-irreversible-blocks-index-url`, `firehose-realtime-tolerance`
* Removed `relayer-buffer-size`, `relayer-merger-addr`, `relayer-min-start-offset`

### MIGRATION

#### Clients

* If you depend on the proto file, update `import "sf/ethereum/type/v1/type.proto"` to `import "sf/ethereum/type/v2/type.proto"`
* If you depend on the proto file, update all occurrences of `sf.ethereum.type.v1.<Something>` to `sf.ethereum.type.v2.<Something>`
* If you depend on `sf-ethereum/types` as a library, update all occurrences of `github.com/streamingfast/firehose-ethereum/types/pb/sf/ethereum/type/v1` to `github.com/streamingfast/firehose-ethereum/types/pb/sf/ethereum/type/v2`.

### Server-side

#### Deployment

* The `reader` requires Firehose-instrumented Geth binary with instrumentation version *2.x* (tagged `fh2`)
* Because of the changes in the ethereum block protocol, an existing deployment cannot be migrated in-place.
* You must deploy firehose-ethereum v1.0.0 on a new environment (without any prior block or index data)
* You can put this new deployment behind a GRPC load-balancer that routes `/sf.firehose.v2.Stream/*` and `/sf.firehose.v1.Stream/*` to your different versions.
* Go through the list of changed "Flags and environment variables" and adjust your deployment accordingly.
  * Determine a (shared) location for your `forked-blocks`.
  * Make sure that you set the `one-block-store` and `forked-blocks-store` correctly on all the apps that now require it.
  * Add the `generate-combined-index` app to your new deployment instead of the `tools` command for call/logs indices.
* If you want to reprocess blocks in batches while you set up a "live" deployment:
  * run your reader node from prior data (ex: from a snapshot)
  * use the `--common-first-streamable-block` flag to a 100-block-aligned boundary right after where this snapshot starts (use this flag on all apps)
  * perform batch merged-blocks reprocessing jobs
  * when all the blocks are present, set the `common-first-streamable-block` flag to 0 on your deployment to serve the whole range

#### Producing merged-blocks in batch

* The `reader` requires Firehose-instrumented Geth binary with instrumentation version *2.x* (tagged `fh2`)
* The `reader` *does NOT merge block files directly anymore*: you need to run it alongside a `merger`:
  * determine a `start` and `stop` block for your reprocessing job, aligned on a 100-blocks boundary right after your Geth data snapshot
  * set `--common-first-streamable-block` to your start-block
  * set `--merger-stop-block` to your stop-block
  * set `--common-one-block-store-url` to a local folder accessible to both `merger` and `mindreader` apps
  * set `--common-merged-blocks-store-url` to the final (ex: remote) folder where you will store your merged-blocks
  * run both apps like this `fireeth start reader,merger --...`
* You can run as many batch jobs like this as you like in parallel to produce the merged-blocks, as long as you have data snapshots for Geth that start at this point

#### Producing combined block indices in batch

* Run batch jobs like this: `fireeth start generate-combined-index --common-blocks-store-url=/path/to/blocks --common-index-store-url=/path/to/index --combined-index-builder-index-size=10000 --combined-index-builder-start-block=0 [--combined-index-builder-stop-block=10000] --combined-index-builder-grpc-listen-addr=:9000`

### Other (non-breaking) changes

#### Added tools and apps

* Added `tools firehose-client` command with filter/index options
* Added `tools normalize-merged-blocks` command to remove forked blocks from merged-blocks files (cannot transform ethereum blocks V1 into V2 because some fields are missing in V1)
* Added substreams server support in firehose app (*alpha*) through `--substreams-enabled` flag

#### Various

* The firehose GRPC endpoint now supports requests that are compressed using `gzip` or `zstd`
* The merger does not expose `PreMergedBlocks` endpoint over GRPC anymore, only HealthCheck. (relayer does not need to talk to it)
* Automatically setting the flag `--firehose-genesis-file` on `reader` nodes if their `reader-node-bootstrap-data-url` config value is sets to a `genesis.json` file.
* Note to other Firehose implementors: we changed all command line flags to fit the required/optional format referred to here: https://en.wikipedia.org/wiki/Usage_message
* Added prometheus boolean metric to all apps called 'ready' with label 'app' (firehose, merger, mindreader-node, node, relayer, combined-index-builder)

## v0.10.2

* Removed `firehose-blocks-store-urls` flag (feature for using multiple stores now deprecated -> causes confusion and issues with block-caching), use `common-blocks-sture-url` instead.

## v0.10.2

* Fixed problem using S3 provider where the S3 API returns empty filename (we ignore at the consuming time when we receive an empty filename result).

## v0.10.1

* Fixed an issue where the merger could panic on a new deployment

## v0.10.0

* Fixed an issue where the `merger` would get stuck when too many (more than 2000) one-block-files were lying around, with block numbers below the current bundle high boundary.

## v0.10.0-rc.5

#### Changed

* Renamed common `atm` 4 flags to `blocks-cache`:
  `--common-blocks-cache-{enabled|dir|max-recent-entry-bytes|max-entry-by-age-bytes}`

#### Fixed

* Fixed `tools check merged-blocks` block hole detection behavior on missing ranges (bumped `sf-tools`)
* Fixed a deadlock issue related to s3 storage error handling (bumped `dstore`)

#### Added

* Added `tools download-from-firehose` command to fetch blocks and save them as merged-blocks files locally.
* Added `cloud-gcp://` auth module (bumped `dauth`)

## v0.10.0-rc.4

#### Added

* substreams-alpha client
* gke-pvc-snapshot backup module

#### Fixed
* Fixed a potential 'panic' in `merger` on a new chain

## v0.10.0

#### Fixed
* Fixed an issue where the `merger` would get stuck when too many (more than 2000) one-block-files were lying around, with block numbers below the current bundle high boundary.

## v0.10.0-rc.5

### Changed

* Renamed common `atm` 4 flags to `blocks-cache`:
  `--common-blocks-cache-{enabled|dir|max-recent-entry-bytes|max-entry-by-age-bytes}`

#### Fixed

* Fixed `tools check merged-blocks` block hole detection behavior on missing ranges (bumped `sf-tools`)

#### Added

* Added `tools download-from-firehose` command to fetch blocks and save them as merged-blocks files locally.
* Added `cloud-gcp://` auth module (bumped `dauth`)

## v0.10.0-rc.4

### Changed

* The default text `encoder` use to encode log entries now emits the level when coloring is disabled.
* Default value for flag `--mindreader-node-enforce-peers` is now `""`, this has been changed because the default value was useful only in development when running a local `node-manager` as either the miner or a peering node.

## v0.10.0-rc.1

#### Added

* Added block data file caching (called `ATM`), this is to reduce the memory usage of component keeping block objects in memory.
* Added transforms: LogFilter, MultiLogFilter, CallToFilter, MultiCallToFilter to only return transaction traces that match logs or called addresses.
* Added support for irreversibility indexes in firehose to prevent replaying reorgs when streaming old blocks.
* Added support for log and call indexes to skip old blocks that do not match any transform filter.

### Changed

* Updated all Firehose stack direct dependencies.
* Updated confusing flag behavior for `--common-system-shutdown-signal-delay` and its interaction with `gRPC` connection draining in `firehose` component sometimes preventing it from shutting down.
* Reporting an error is if flag `merge-threshold-block-age` is way too low (< 30s).

#### Removed

* Removed some old components that are not required by Firehose stack directly, the repository is as lean as it ca now.

#### Fixed

* Fixed Firehose gRPC listening address over plain text.
* Fixed automatic merging of files within the `mindreader` is much more robust then before.
