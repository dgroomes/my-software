class MyGradle < Formula
  desc "My personal formula: Gradle distribution"

  homepage "https://github.com/dgroomes/my-software"

  url "https://services.gradle.org/distributions/gradle-9.7.0-bin.zip"

  version "0.0.0"

  sha256 "84fbba45c7f4c64abc77460e1c00f541e9f960e3c7ed2538f1ede19eacd873ae"

  def install
    libexec.install "lib"
    libexec.install "bin"
    bin.install_symlink libexec/"bin/gradle"
  end
end
