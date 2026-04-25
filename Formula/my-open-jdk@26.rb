class MyOpenJdkAT26 < Formula
  desc "My personal formula: Eclipse Temurin distribution of OpenJDK 26"

  homepage "https://github.com/dgroomes/my-software"

  url "https://github.com/adoptium/temurin26-binaries/releases/download/jdk-26%2B35/OpenJDK26U-jdk_aarch64_mac_hotspot_26_35.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "596ba026474808b75e934aa8c32cf9b340fafc455d06f366ede4f2932f206eb1"

  def install
    libexec.install "Contents"
    bin.install_symlink Dir[libexec/"Contents/Home/bin/*"]
  end
end
