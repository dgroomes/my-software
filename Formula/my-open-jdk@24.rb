class MyOpenJdkAT24 < Formula
  desc "My personal formula: Eclipse Temurin distribution of OpenJDK 24"

  homepage "https://github.com/dgroomes/my-software"

  url "https://github.com/adoptium/temurin24-binaries/releases/download/jdk-24%2B36-ea-beta/OpenJDK24U-jdk_aarch64_mac_hotspot_24_36-ea.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "8b8f79907ca9f13be8a40a87b79685fd1d38bab6d0911f6611d5f2ada9071fcc"

  def install
    libexec.install "Contents"
    bin.install_symlink Dir[libexec/"Contents/Home/bin/*"]
  end
end
