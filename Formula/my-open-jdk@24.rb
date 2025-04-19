class MyOpenJdkAT24 < Formula
  desc "My personal formula: Eclipse Temurin distribution of OpenJDK 24"

  homepage "https://github.com/dgroomes/my-software"

  url "https://github.com/adoptium/temurin24-binaries/releases/download/jdk-24.0.1%2B9/OpenJDK24U-jdk_aarch64_mac_hotspot_24.0.1_9.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "e3b1fe4cd3da335d07d62f335ae958f5a43c594be1ba333a06a03a49d2212cd4"

  def install
    libexec.install "Contents"
    bin.install_symlink Dir[libexec/"Contents/Home/bin/*"]
  end
end
