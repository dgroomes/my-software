class MyOpenJdkAT21 < Formula
  desc "My personal formula: Eclipse Temurin distribution of OpenJDK 21"

  homepage "https://github.com/dgroomes/my-software"

  url "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.9%2B10/OpenJDK21U-jdk_aarch64_mac_hotspot_21.0.9_10.tar.gz"

  version "0.0.1"

  keg_only "Linking is not desired. Ideally this should be :versioned_formula but see https://github.com/orgs/Homebrew/discussions/6741"

  sha256 "55a40abeb0e174fdc70f769b34b50b70c3967e0b12a643e6a3e23f9a582aac16"

  def install
    libexec.install "Contents"
    bin.install_symlink Dir[libexec/"Contents/Home/bin/*"]
  end
end
