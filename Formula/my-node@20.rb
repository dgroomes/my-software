require "fileutils"

class MyNodeAT20 < Formula
  desc "My personal formula: Node.js 20 pre-built binaries"

  homepage "https://github.com/dgroomes/my-software"

  url "https://nodejs.org/dist/v20.17.0/node-v20.17.0-darwin-arm64.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "476324108c4361935465631eec47df1c943ba2c87bc050853385b1d1c71f0b1f"

  def install
    libexec.mkpath
    Dir.glob("*") do |file|
      FileUtils.mv file, libexec
    end
    bin.install_symlink Dir[libexec/"bin/*"]
  end
end
