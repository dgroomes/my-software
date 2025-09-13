class MyOpenJdkAT24 < Formula
  desc "My personal formula: Eclipse Temurin distribution of OpenJDK 24"

  homepage "https://github.com/dgroomes/my-software"

  url "https://github.com/adoptium/temurin24-binaries/releases/download/jdk-24.0.2%2B12/OpenJDK24U-jdk_aarch64_mac_hotspot_24.0.2_12.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "db2ba6f72c19ad8b742303a504f58474bceeb94174a185de5f095c1d45577f1c"

  def install
    libexec.install "Contents"
    bin.install_symlink Dir[libexec/"Contents/Home/bin/*"]
  end
end
