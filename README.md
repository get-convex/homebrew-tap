# get-convex/homebrew-tap

Version-pinned Homebrew formulae for Convex local dev.

`rocksdb` (8.10.2) and `gflags` (2.2.2) are pinned to match the `librocksdb-sys` crate bindings (`0.16.0+8.10.0`); homebrew-core's `latest` drifts ahead and breaks the rocksdb→gflags dylib link. The formulae reuse the prebuilt upstream core bottles, so installs pour binaries — nothing is built or hosted here.

    brew install get-convex/tap/rocksdb
