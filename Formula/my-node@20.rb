require "fileutils"

class MyNodeAT20 < Formula
  desc "My personal formula: Node.js 20 pre-built binaries"

  homepage "https://github.com/dgroomes/my-config"

  url "https://nodejs.org/dist/v20.15.0/node-v20.15.0-darwin-arm64.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "2646c338d2c5ecabba4f745fc315d6fdfbb7e01b5badecc154ad27dda00325fc"

  def install
    libexec.mkpath
    Dir.glob("*") do |file|
      FileUtils.mv file, libexec
    end
    bin.install_symlink Dir[libexec/"bin/*"]
  end
end
