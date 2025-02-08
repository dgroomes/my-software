require "fileutils"

class MyNodeAT23 < Formula
  desc "My personal formula: Node.js 23 pre-built binaries"

  homepage "https://github.com/dgroomes/my-software"

  url "https://nodejs.org/dist/v23.7.0/node-v23.7.0-darwin-arm64.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "0dac0de3308a87f84cb14bab349a3f0ae5f6cdb8da32600459ee407236f9cebc"

  def install
    libexec.mkpath
    Dir.glob("*") do |file|
      FileUtils.mv file, libexec
    end
    bin.install_symlink Dir[libexec/"bin/*"]
  end
end
