class MyOpenJdkAT23 < Formula
  desc "My personal formula: An Early-Access version of OpenJDK 23 distributed by OpenJDK"

  homepage "https://github.com/dgroomes/my-config"

  url "https://download.java.net/java/early_access/jdk23/35/GPL/openjdk-23-ea+35_macos-aarch64_bin.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "a34eedb0dd62a451c673d14dc0e30340c1ad91490d3c0fd3d4f770e9c0e6ddda"

  def install
    libexec.install "Contents"
    bin.install_symlink Dir[libexec/"Contents/Home/bin/*"]
  end
end
