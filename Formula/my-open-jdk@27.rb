class MyOpenJdkAT27 < Formula
  desc "My personal formula: Eclipse Temurin distribution of OpenJDK 27"

  homepage "https://github.com/dgroomes/my-software"

  url "https://github.com/adoptium/temurin27-binaries/releases/download/jdk-27%2B18-ea-beta/OpenJDK-jdk_aarch64_mac_hotspot_27_18-ea.tar.gz"

  version "0.0.1"

  keg_only "Linking is not desired. Ideally this should be :versioned_formula but see https://github.com/orgs/Homebrew/discussions/6741"

  sha256 "0ef61c5fc056df4e25bd37b234a737efbff2cc6838b92ff8a0ceb5751fedb0fc"

  def install
    libexec.install "Contents"
    bin.install_symlink Dir[libexec/"Contents/Home/bin/*"]
  end
end
