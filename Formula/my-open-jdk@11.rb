class MyOpenJdkAT11 < Formula
  desc "My personal formula: Eclipse Temurin distribution of OpenJDK 11"

  homepage "https://github.com/dgroomes/my-software"

  url "https://github.com/adoptium/temurin11-binaries/releases/download/jdk-11.0.24%2B8/OpenJDK11U-jdk_aarch64_mac_hotspot_11.0.24_8.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "8bcbb98e293fb3c4d5cae3539f240ed478fae85962311fccd4c628ebad3a90e4"

  def install
    libexec.install "Contents"
    bin.install_symlink Dir[libexec/"Contents/Home/bin/*"]
  end
end
