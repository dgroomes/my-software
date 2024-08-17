# Copy the Nushell binary from a local clone.
#
# This is virtually a "do nothing" formula. I just find it convenient to store executables in the Homebrew prefix, and
# to get the benefit of Homebrew's uninstall/install mechanism. This formula assumes that the nu binary is already built
# at the hardcoded path.
class MyNushell < Formula
  desc "My personal formula: my local build of Nushell from source"

  homepage "https://github.com/dgroomes/my-software"

  url "file:///Users/dave/repos/opensource/nushell/target/release/nu"

  version "0.0.0"

  sha256 "f4cad6a6d5311d2c08b0a27d0b6564030e7db1561e556f62b04bb29465bac17d"

  def install
    bin.install "nu"
  end
end
