# Pinned copy of homebrew-core's rocksdb 8.10.2 (core revision e7c143656817,
# 2024-02-21). Convex pins rocksdb because the `librocksdb-sys` crate ships
# bindings generated against a specific rocksdb version (currently
# librocksdb-sys 0.16.0+8.10.0, i.e. rocksdb 8.10.0); homebrew-core's current
# rocksdb has moved several majors ahead and is ABI-incompatible. 8.10.2 is the
# closest homebrew-core bottle to the 8.10.0 the bindings target, and matches the
# 8.x rocksdb used on Linux (apt librocksdb-dev / the bundled librocksdb-sys build).
#
# The bottle block is copied unchanged from core, and root_url points back at
# core's ghcr registry, so `brew install get-convex/tap/rocksdb` pours the exact
# upstream bottle — no building from source, nothing for us to host. The newest
# bottle tag here is arm64_sonoma; on newer macOS Homebrew's :or_later behavior
# reuses it (e.g. on Tahoe).
class Rocksdb < Formula
  desc "Embeddable, persistent key-value store for fast storage"
  homepage "https://rocksdb.org/"
  url "https://github.com/facebook/rocksdb/archive/refs/tags/v8.10.2.tar.gz"
  sha256 "44b6ec2f4723a0d495762da245d4a59d38704e0d9d3d31c45af4014bee853256"
  license any_of: ["GPL-2.0-only", "Apache-2.0"]

  bottle do
    root_url "https://ghcr.io/v2/homebrew/core"
    sha256 cellar: :any,                 arm64_sonoma:   "b4e43b7c6d3d3ebe13353378d5f3c7777d090410dcdc014e4ea38b16d8cd8541"
    sha256 cellar: :any,                 arm64_ventura:  "0dc411a0bc256d7dc36205f8c9da0322940eeed3d6a8ea3da51527ad1d323878"
    sha256 cellar: :any,                 arm64_monterey: "0282a3cc582db00285ae441ce01c38c9a0014bbccb7d0611fbbcac4a53bc9479"
    sha256 cellar: :any,                 sonoma:         "3c78993c76675819ac2589848e268bcdec45406697475fc9bb9702166db1a15b"
    sha256 cellar: :any,                 ventura:        "0ed958d53c38776682eacdf20b4c58de6226afb5a94738d09211ca8397782d71"
    sha256 cellar: :any,                 monterey:       "2771b3e3d92705a6bdb8484d45f5f1939a09949914f6930b7b5e4b72ccf002d2"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "8114387d178b6834a02da9eb5077aea74330d042d16f2356499c6443e7c0fc66"
  end

  depends_on "cmake" => :build
  # Qualified to this tap so installing rocksdb pulls our pinned gflags 2.2.2
  # (whose libgflags.2.2.dylib this bottle links against) rather than core's
  # current 2.3.0. Without this, an unqualified "gflags" resolves to core and
  # re-breaks the link.
  depends_on "get-convex/tap/gflags"
  depends_on "lz4"
  depends_on "snappy"
  depends_on "zstd"

  uses_from_macos "bzip2"
  uses_from_macos "zlib"

  fails_with :gcc do
    version "6"
    cause "Requires C++17 compatible compiler. See https://github.com/facebook/rocksdb/issues/9388"
  end

  def install
    args = %W[
      -DPORTABLE=ON
      -DUSE_RTTI=ON
      -DWITH_BENCHMARK_TOOLS=OFF
      -DWITH_BZ2=ON
      -DWITH_LZ4=ON
      -DWITH_SNAPPY=ON
      -DWITH_ZLIB=ON
      -DWITH_ZSTD=ON
      -DROCKSDB_BUILD_SHARED=ON
      -DCMAKE_EXE_LINKER_FLAGS=-Wl,-rpath,#{rpath}
    ]
    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    cd "build/tools" do
      bin.install "sst_dump" => "rocksdb_sst_dump"
      bin.install "db_sanity_test" => "rocksdb_sanity_test"
      bin.install "write_stress" => "rocksdb_write_stress"
      bin.install "ldb" => "rocksdb_ldb"
      bin.install "db_repl_stress" => "rocksdb_repl_stress"
      bin.install "rocksdb_dump"
      bin.install "rocksdb_undump"
    end
    bin.install "build/db_stress_tool/db_stress" => "rocksdb_stress"
  end

  test do
    (testpath/"test.cpp").write <<~EOS
      #include <assert.h>
      #include <rocksdb/options.h>
      #include <rocksdb/memtablerep.h>
      using namespace rocksdb;
      int main() {
        Options options;
        return 0;
      }
    EOS

    extra_args = []
    if OS.mac?
      extra_args << "-stdlib=libc++"
      extra_args << "-lstdc++"
    end
    system ENV.cxx, "test.cpp", "-o", "db_test", "-v",
                                "-std=c++17",
                                *extra_args,
                                "-lz", "-lbz2",
                                "-L#{lib}", "-lrocksdb",
                                "-L#{Formula["snappy"].opt_lib}", "-lsnappy",
                                "-L#{Formula["lz4"].opt_lib}", "-llz4",
                                "-L#{Formula["zstd"].opt_lib}", "-lzstd"
    system "./db_test"

    assert_match "sst_dump --file=", shell_output("#{bin}/rocksdb_sst_dump --help 2>&1")
    assert_match "rocksdb_sanity_test <path>", shell_output("#{bin}/rocksdb_sanity_test --help 2>&1", 1)
    assert_match "rocksdb_stress [OPTIONS]...", shell_output("#{bin}/rocksdb_stress --help 2>&1", 1)
    assert_match "rocksdb_write_stress [OPTIONS]...", shell_output("#{bin}/rocksdb_write_stress --help 2>&1", 1)
    assert_match "ldb - RocksDB Tool", shell_output("#{bin}/rocksdb_ldb --help 2>&1")
    assert_match "rocksdb_repl_stress:", shell_output("#{bin}/rocksdb_repl_stress --help 2>&1", 1)
    assert_match "rocksdb_dump:", shell_output("#{bin}/rocksdb_dump --help 2>&1", 1)
    assert_match "rocksdb_undump:", shell_output("#{bin}/rocksdb_undump --help 2>&1", 1)

    db = testpath / "db"
    %w[no snappy zlib bzip2 lz4 zstd].each_with_index do |comp, idx|
      key = "key-#{idx}"
      value = "value-#{idx}"

      put_cmd = "#{bin}/rocksdb_ldb put --db=#{db} --create_if_missing --compression_type=#{comp} #{key} #{value}"
      assert_equal "OK", shell_output(put_cmd).chomp

      get_cmd = "#{bin}/rocksdb_ldb get --db=#{db} #{key}"
      assert_equal value, shell_output(get_cmd).chomp
    end
  end
end
