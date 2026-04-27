class MyOpenJdkAT17 < Formula
  desc "My personal formula: Eclipse Temurin distribution of OpenJDK 17"

  homepage "https://github.com/dgroomes/my-software"

  url "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.18%2B8/OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.18_8.tar.gz"

  version "0.0.1"

  # This formula is "keg-only" because multiple versions of the JDK are typically installed at the same time. We must
  # rely on a dynamic switching mechanism instead of the Homebrew mechanism of symlinking executables into
  # "/opt/homebrew/bin".
  #
  # For a long time I was using 'keg_only :versioned_formula' here but I started noticing an issue on 2026-04-26
  # (Homebrew version 5.1.7) where when I install this formula, Homebrew acutally does link it! Confusingly, in the
  # same "brew install ..." output, it even says the normal "... keg-only, which means it was not symlinked into /opt/homebrew".
  # So it contradicts itself.
  #
  # I don't get this behavior, but I found a workaround in this discussion https://github.com/orgs/Homebrew/discussions/6741.
  # The suggestion is to use a string value for the argument to key_only. I also can't make sense of the lineage of the
  # changes linked from the discussion because it was a "revert of a revert of a change" and it all happened within 2
  # days, and that was over a month ago. It's not clear that the linked change even made it into the mainline, but this
  # workaround works for me.
  #
  keg_only "Linking is not desired. Ideally this should be :versioned_formula but see https://github.com/orgs/Homebrew/discussions/6741"

  sha256 "d81de06d938384fe76c4aa3c13395933aa11e2d19b0428743f810db06b05e312"

  def install
    # The tar ball should extract exactly one top-level file, which is a directory named as the version number of
    # OpenJDK (e.g. "jdk-17.0.11+9"). Interestingly, at this point, Homebrew seems to have automatically changed the
    # current directory into that top-level directory. That's quite strange, because a tar ball could have multiple
    # files and directories in the top-level, right? After some quick searching, I can't find any documentation that
    # describes this behavior, so maybe I'm just interpreting something wrong.

    libexec.install "Contents"
    bin.install_symlink Dir[libexec/"Contents/Home/bin/*"]
  end
end
