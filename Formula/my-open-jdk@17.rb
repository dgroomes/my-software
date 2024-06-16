require "fileutils"

class MyOpenJdkAT17 < Formula
  desc "My personal formula of the Eclipse Temurin distribution of OpenJDK 17"

  homepage "https://github.com/dgroomes/my-config"

  url "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.11%2B9/OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.11_9.tar.gz"

  version "0.0.0"

  # This formula is "keg-only" because multiple versions of the JDK are typically installed at the same time. We must
  # rely on a dynamic switching mechanism instead of the Homebrew mechanism of symlinking executables into
  # "/opt/homebrew/bin".
  keg_only :versioned_formula

  sha256 "09a162c58dd801f7cfacd87e99703ed11fb439adc71cfa14ceb2d3194eaca01c"

  def install
    # The tar ball should extract exactly one top-level file, which is a directory named as the version number of
    # OpenJDK (e.g. "jdk-17.0.11+9"). Interestingly, at this point, Homebrew seems to have automatically changed the
    # current directory into that top-level directory. That's quite strange, because a tar ball could have multiple
    # files and directories in the top-level. After some quick searching, I can't find any documentation that describes
    # this behavior, so maybe I'm just interpreting something wrong. But this is actually annoying because I can't just
    # `libexec.install Dir["jdk*"].first => "openjdk"`. Instead, I need to build a containing directory and then move
    # "Contents" into it.
    openjdk_dir = libexec/"openjdk"
    openjdk_dir.mkpath
    contents_dir = Pathname.new(Dir.pwd)/"Contents"
    FileUtils.mv contents_dir, openjdk_dir

    # Create symlinks for all executables in the bin directory
    bin.install_symlink Dir[openjdk_dir/"Contents/Home/bin/*"]
  end
end
