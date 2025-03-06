class MyOpenJdkAT8 < Formula
  desc "My personal formula: Eclipse Temurin distribution of OpenJDK 8"

  homepage "https://github.com/dgroomes/my-software"

  url "https://github.com/adoptium/temurin8-binaries/releases/download/jdk8u442-b06/OpenJDK8U-jdk_x64_mac_hotspot_8u442b06.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "2f70725e032fe55629a2659d53646b14c538b12cdcedc2d3c9fa342e1b401cf1"

  def install
    libexec.install "Contents"
    bin.install_symlink Dir[libexec/"Contents/Home/bin/*"]
  end
end
