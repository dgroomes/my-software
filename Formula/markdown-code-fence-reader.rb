# Install the 'markdown-code-fence-reader' program distribution from the 'java/markdown-code-fence-reader' subproject.
#
# This is virtually a "do nothing" formula. I just find it convenient to store executables in the Homebrew prefix, and
# to get the benefit of Homebrew's uninstall/install mechanism. This formula assumes that the
# 'markdown-code-fence-reader' program distribution is already built at the hardcoded path.
class MarkdownCodeFenceReader < Formula
  desc "My personal formula: my local build of 'markdown-code-fence-reader'"

  homepage "https://github.com/dgroomes/my-software"

  url "file:///Users/dave/repos/personal/my-software/java/markdown-code-fence-reader/build/distributions/markdown-code-fence-reader.tar"

  version "0.0.0"

  sha256 "45ab52fa9a8bbeb1789907f2938c30fe30abfd4a195849627d13431a6efbd96d"

  def install
    libexec.install "lib"
    libexec.install "bin"
    bin.install_symlink libexec/"bin/markdown-code-fence-reader"
  end
end
