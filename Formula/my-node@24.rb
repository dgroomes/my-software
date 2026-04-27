require "fileutils"

class MyNodeAT24 < Formula
  desc "My personal formula: Node.js 24 pre-built binaries"

  homepage "https://github.com/dgroomes/my-software"

  url "https://nodejs.org/dist/v24.15.0/node-v24.15.0-darwin-arm64.tar.gz"

  version "0.0.0"

  keg_only "Linking is not desired. Ideally this should be :versioned_formula but see https://github.com/orgs/Homebrew/discussions/6741"

  sha256 "372331b969779ab5d15b949884fc6eaf88d5afe87bde8ba881d6400b9100ffc4"

  def install
    libexec.mkpath
    Dir.glob("*") do |file|
      FileUtils.mv file, libexec
    end
    bin.install_symlink Dir[libexec/"bin/*"]
  end
end
