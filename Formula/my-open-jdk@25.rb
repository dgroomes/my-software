class MyOpenJdkAT25 < Formula
  desc "My personal formula: Eclipse Temurin distribution of OpenJDK 25"

  homepage "https://github.com/dgroomes/my-software"

  url "https://github.com/adoptium/temurin25-binaries/releases/download/jdk-25%2B36/OpenJDK25U-jdk_aarch64_mac_hotspot_25_36.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "6630ea0f19db61843a8fa84a84b2c71cd120c4155bb5a0e42a74593b0d70fee4"

  def install
    libexec.install "Contents"
    bin.install_symlink Dir[libexec/"Contents/Home/bin/*"]
  end
end
