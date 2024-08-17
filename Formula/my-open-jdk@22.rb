class MyOpenJdkAT22 < Formula
  desc "My personal formula: Eclipse Temurin distribution of OpenJDK 22"

  homepage "https://github.com/dgroomes/my-software"

  url "https://github.com/adoptium/temurin22-binaries/releases/download/jdk-22.0.1%2B8/OpenJDK22U-jdk_aarch64_mac_hotspot_22.0.1_8.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "80d6fa75e87280202ae7660139870fe50f07fca9dc6c4fbd3f2837cbd70ec902"

  def install
    libexec.install "Contents"
    bin.install_symlink Dir[libexec/"Contents/Home/bin/*"]
  end
end
