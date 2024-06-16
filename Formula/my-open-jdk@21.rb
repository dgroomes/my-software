require "fileutils"

class MyOpenJdkAT21 < Formula
  desc "My personal formula of the Eclipse Temurin distribution of OpenJDK 21"

  homepage "https://github.com/dgroomes/my-config"

  url "https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.3%2B9/OpenJDK21U-jdk_aarch64_mac_hotspot_21.0.3_9.tar.gz"

  version "0.0.0"

  keg_only :versioned_formula

  sha256 "b6be6a9568be83695ec6b7cb977f4902f7be47d74494c290bc2a5c3c951e254f"

  def install
    openjdk_dir = libexec/"openjdk"
    openjdk_dir.mkpath
    contents_dir = Pathname.new(Dir.pwd)/"Contents"
    FileUtils.mv contents_dir, openjdk_dir

    # Create symlinks for all executables in the bin directory
    bin.install_symlink Dir[openjdk_dir/"Contents/Home/bin/*"]
  end
end
