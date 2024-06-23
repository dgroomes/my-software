class MyIdeaLightEdit < Formula
  desc "My personal formula: Launch Intellij IDEA's 'LightEdit' mode"

  homepage "https://github.com/dgroomes/my-config"

  url "file:///Users/dave/repos/personal/my-config/jetbrains/idea-light-edit.nu"

  version "0.0.0"

  sha256 "b1f4fa2461ecd9d6e18d74df6f92430779b2bdbd8461b44bf4a675c00c2f5462"

  def install
    bin.install "idea-light-edit.nu" => "idea-light-edit"
  end
end
