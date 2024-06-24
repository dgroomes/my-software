require "fileutils"

class MyOpenJdkAT22 < Formula
  desc "My personal formula: Eclipse Temurin distribution of OpenJDK 22"

  homepage "https://github.com/dgroomes/my-config"

  url "https://github.com/adoptium/temurin22-binaries/releases/download/jdk-22.0.1%2B8/OpenJDK22U-jdk_aarch64_mac_hotspot_22.0.1_8.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "80d6fa75e87280202ae7660139870fe50f07fca9dc6c4fbd3f2837cbd70ec902"

  def install
    openjdk_dir = libexec/"openjdk"
    openjdk_dir.mkpath
    contents_dir = Pathname.new(Dir.pwd)/"Contents"
    FileUtils.mv contents_dir, openjdk_dir

    # Create symlinks for all executables in the bin directory
    bin.install_symlink Dir[openjdk_dir/"Contents/Home/bin/*"]
  end
end
