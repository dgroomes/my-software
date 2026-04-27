require "fileutils"

class MyNodeAT20 < Formula
  desc "My personal formula: Node.js 20 pre-built binaries"

  homepage "https://github.com/dgroomes/my-software"

  url "https://nodejs.org/dist/v20.20.2/node-v20.20.2-darwin-arm64.tar.gz"

  version "0.0.1"

  keg_only "Linking is not desired. Ideally this should be :versioned_formula but see https://github.com/orgs/Homebrew/discussions/6741"

  sha256 "466e05f3477c20dfb723054dfebffe55bc74660ee77f612166fca121dacb65b6"

  def install
    libexec.mkpath
    Dir.glob("*") do |file|
      FileUtils.mv file, libexec
    end
    bin.install_symlink Dir[libexec/"bin/*"]
  end
end
