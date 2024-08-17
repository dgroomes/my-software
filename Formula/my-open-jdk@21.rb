class MyOpenJdkAT21 < Formula
  desc "My personal formula: Eclipse Temurin distribution of OpenJDK 21"

  homepage "https://github.com/dgroomes/my-software"

  url "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.3%2B9/OpenJDK21U-jdk_aarch64_mac_hotspot_21.0.3_9.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "b6be6a9568be83695ec6b7cb977f4902f7be47d74494c290bc2a5c3c951e254f"

  def install
    libexec.install "Contents"
    bin.install_symlink Dir[libexec/"Contents/Home/bin/*"]
  end
end
