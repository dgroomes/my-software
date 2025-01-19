export def min-contrast [bg: string fg: string] {
    let j = ./min-contrast.py $bg $fg
    let r = $j | from json
    print $'Was (ansi --escape { bg: $bg fg: $r.foreground})HELLO(ansi reset) now (ansi --escape { bg: $bg fg: $r.new_foreground})HELLO(ansi reset)'
    $r
}

export def generate-ls-colors [] {
    vivid generate vivid-ls-colors-theme.yml
}

export def --env preview-ls-colors [] {
    $env.LS_COLORS = ^vivid generate vivid-ls-colors-theme.yml
}
