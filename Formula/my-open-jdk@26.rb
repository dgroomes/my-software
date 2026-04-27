class MyOpenJdkAT26 < Formula
  desc "My personal formula: Eclipse Temurin distribution of OpenJDK 26"

  homepage "https://github.com/dgroomes/my-software"

  url "https://github.com/adoptium/temurin26-binaries/releases/download/jdk-26%2B35/OpenJDK26U-jdk_aarch64_mac_hotspot_26_35.tar.gz"

  version "0.0.0"

  # We should be able to use ':versioned_formula' here but I started noticing an issue on 2026-04-26 (HomeBrew version
  # 5.1.7) where when I install this formula, HomeBrew acutally does link it, but in the same "install" output, it even
  # says the normal "keg-only, which means it was not symlinked into /opt/homebrew".
  #
  # I found this discussion https://github.com/orgs/Homebrew/discussions/6741 which seems like the same issue. And the
  # suggestion was to use a string value for the argument to key_only. I also can't sense of the lineage of the changes
  # linked from the discussion because it was a "revert of a revert of a change" and it all happened within 2 days, and
  # that was over a month ago. So I'm confused why I'm affected a month later.
  keg_only "My external tooling is responsible for locating any and all versions of installed 'my-open-jdk' formula. Linking is not desired."

  sha256 "596ba026474808b75e934aa8c32cf9b340fafc455d06f366ede4f2932f206eb1"

  def install
    libexec.install "Contents"
    bin.install_symlink Dir[libexec/"Contents/Home/bin/*"]
  end
end
