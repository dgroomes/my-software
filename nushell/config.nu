$env.MY_DEBUG = false
let start = date now | into int

# Tell Nushell to find plugins in the same directory as the Nushell executable. For me, the executable is at
#
#     /opt/homebrew/bin/nu
#
# And official plugins that are distributed with Nushell are also located in that directory. For example:
#
#     /opt/homebrew/bin/nu_plugin_query
#     /opt/homebrew/bin/nu_plugin_formats
#     /opt/homebrew/bin/nu_plugin_polars
#     /opt/homebrew/bin/nu_plugin_gstat
#
# See https://www.nushell.sh/book/configuration.html#using-constants
#
# For some reason I'm not getting shell completion for commands like 'plugin add' but the commands do find the plugins.
const NU_PLUGIN_DIRS = [
  ($nu.current-exe | path dirname)
]

$env.PATH = $env.PATH | prepend ([
    ~/.local/bin
    /opt/homebrew/bin
    /opt/homebrew/sbin
    `~/Library/Application Support/JetBrains/Toolbox/scripts`
    `/Applications/Sublime Text.app/Contents/SharedSupport/bin`
    ~/.cargo/bin
    ~/.docker/bin
    ~/go/bin
    ~/.local/npm/bin
] | each { path expand })

# Reproduce the same effect of "brew shellenv". We can't use "brew shellenv" because it doesn't support Nushell so we
# can just hardcode the values here. Easy.
#
# TODO consider adding Homebrew manpath/infopath stuff. I don't super care about that.
$env.HOMEBREW_PREFIX = "/opt/homebrew"
$env.HOMEBREW_CELLAR = "/opt/homebrew/Cellar"
$env.HOMEBREW_REPOSITORY = "/opt/homebrew"

# I don't need Homebrew auto-updates. I don't want the hint noise. Don't send telemetry.
$env.HOMEBREW_NO_AUTO_UPDATE = 1
$env.HOMEBREW_NO_ENV_HINTS = 1
$env.HOMEBREW_NO_ANALYTICS = 1

# Disable the "Use 'docker scan'" message on every Docker build. For reference, see this GitHub issue discussion: https://github.com/docker/scan-cli-plugin/issues/149#issuecomment-823969364
$env.DOCKER_SCAN_SUGGEST = false

use bash-completer.nu *
use file-set.nu *
use lib.nu *
use node.nu *
use open-jdk.nu *
use postgres.nu *
use work-trees.nu *
use zdu.nu *

# I don't really understand the essential coverage, or purpose, of the directories added to the PATH by the macOS
# "/usr/libexec/path_helper" tool. But, at the least, I know it adds "/usr/local/bin" to the PATH and I need that.
# I'm not going to dig into this further. I just vaguely know about /etc/paths and /etc/paths.d and today I learned
# or maybe re-learned about /etc/profile and /etc/bashrc.
$env.PATH = ($env.PATH | append "/usr/local/bin")

$env.config.buffer_editor = "subl"

export alias clc = cp-last-cmd
export alias ll = ls -l
export alias la = ls -a

# Copy and Paste.
#
# 'pbcopy' and 'pbpaste' are too long to type for frequent use. 'pbpaste' I especially struggle with for some reason.
# Because this is my own system, I can squat on prime real estate when it comes to aliases and command names. Let's try
# out the single character aliases 'c' and 'p'. I thought about using 'cc' and 'cv' because it's reminiscent of
# "Cmd + C" and "Cmd + V" but 'cc' is the clang C/C++/Objective-C compiler.
export alias c = pbcopy
export alias p = pbpaste

export alias f = file-name

# Git aliases
export alias gsdp = git-switch-default-pull
export alias gs = git st
export alias gl = git lg

alias wt = work-tree
alias "wt ls" = work-tree list
alias "wt switch" = work-tree switch
alias "wt add" = work-tree add

# Docker aliases
export alias dcl = docker container ls
## This is what I'll call a "hard restart" version of the "up" command. It forces the containers to be created fresh
## instead of being reused and it does the same for anonymous volumes. This is very convenient for the development process
## where you frequently want to throw everything away and start with a clean slate. I use this for stateful workloads like
## Postgres and Kafka.
export alias dcuf = docker-compose up --detach --force-recreate --renew-anon-volumes
export alias dcd = docker-compose down --remove-orphans

# Miscellaneous aliases
export alias psql_local = psql --username postgres --host localhost

$env.config.completions.external = {
  enable: true
  completer: { |spans| bash-complete $spans }
}

export alias cdr = cd-repo
export alias rfr = run-from-readme

# Discover keg installations of OpenJDK and make them available (i.e. "advertise") as version-specific "JAVA_HOME"
# environment variables.
#
# For example, for a Java 17 OpenJDK keg installed at "/opt/homebrew/opt/my-open-jdk@17" then set the environment
# variable "JAVA_HOME_17" to that path.
def --env advertise-installed-open-jdks [] {
    for keg in (my-open-jdk-kegs) {
        let java_x_home = $"JAVA_($keg.java_version)_HOME"
        load-env { $java_x_home: $keg.jdk_home_dir }
    }
}

advertise-installed-open-jdks
advertise-installed-nodes

const ACTIVATE_DO = r#'
# ERASE ME
overlay use --prefix do.nu
let hooks = $env.config.hooks.pre_prompt
let filtered = $hooks | where ($it | describe) != "string" or $it !~ "# ERASE ME"
$env.config.hooks.pre_prompt = $filtered
'#

# Activate a 'do.nu' script as an overlay module.
#
# By convention, I put 'do.nu' scripts in projects and this lets me compress my workflow. The 'do activate' command
# activates the local 'do.nu' script as a module using Nushell's *overlays*. Because of Nushell's parse-evaluate model, this
# is actually pretty difficult to do, so we can abuse Nushell hooks to do this.
export def --env "do activate" [] {
    if not ("do.nu" | path exists) {
        err "No 'do.nu' script found."
    }

    # Here is the tricky part. Register a pre_prompt hook that will load the 'do.nu' script and then the hook will
    # erase itself. I have details about this pattern in my nushell-playground repository: https://github.com/dgroomes/nushell-playground/blob/b505270046fd2c774927749333e67707073ad62d/hooks.nu#L72

    $env.config = ($env.config | upsert hooks.pre_prompt {
        default [] | append $ACTIVATE_DO
    })
}

export alias da = do activate

$env.config.show_banner = false

$env.config.history = {
    max_size: 100_000 # Session has to be reloaded for this to take effect
    sync_on_enter: true # Enable to share history between multiple sessions, else you have to close the session to write history to file
    file_format: "sqlite" # "sqlite" or "plaintext"
    isolation: true # only available with sqlite file_format. true enables history isolation, false disables it. true will allow the history to be isolated to the current session using up/down arrows. false will allow the history to be shared across all sessions.
}

$env.config.buffer_editor = "vim" # command that will be used to edit the current line buffer with ctrl+o, if unset fallback to $env.EDITOR and $env.VISUAL

# Consider replacing some of the color config with just the default foreground color (black). I don't need colors on
# everything, that's noise and also maintenance.
$env.config.color_config = {
     separator: default
     leading_trailing_space_bg: { attr: n }
     header: green_bold
     empty: blue
     bool: light_cyan
     int: default
     filesize: cyan
     duration: default
     date: purple
     range: default
     float: default
     string: default
     nothing: default
     binary: default
     cell-path: default
     row_index: green_bold
     record: default
     list: default
     closure: green_bold
     glob:cyan_bold
     block: default
     hints: dark_gray
     search_result: { bg: red fg: white }
     shape_binary: purple_bold
     shape_block: blue_bold
     shape_bool: light_cyan
     shape_closure: green_bold
     shape_custom: green
     shape_datetime: cyan_bold
     shape_directory: cyan
     shape_external: cyan
     shape_externalarg: green_bold
     shape_external_resolved: light_yellow_bold
     shape_filepath: cyan
     shape_flag: blue_bold
     shape_float: purple_bold
     shape_glob_interpolation: cyan_bold
     shape_globpattern: cyan_bold
     shape_int: purple_bold
     shape_internalcall: cyan_bold
     shape_keyword: cyan_bold
     shape_list: cyan_bold
     shape_literal: blue
     shape_match_pattern: green
     shape_matching_brackets: { attr: u }
     shape_nothing: light_cyan
     shape_operator: yellow
     shape_pipe: purple_bold
     shape_range: yellow_bold
     shape_record: cyan_bold
     shape_redirection: purple_bold
     shape_signature: green_bold
     shape_string: green
     shape_string_interpolation: cyan_bold
     shape_table: blue_bold
     shape_variable: purple
     shape_vardecl: purple
     shape_raw_string: light_purple
     shape_garbage: {
         fg: white
         bg: red
         attr: b
     }
}

# Generated with 'vivid'. See the 'vivid/' directory.
$env.LS_COLORS = "*~=0;38;2;122;112;112:bd=0;38;2;102;217;239;48;2;51;51;51:ca=0:cd=0;38;2;249;38;114;48;2;51;51;51:di=0;38;2;0;141;161:do=0;38;2;0;0;0;48;2;249;38;114:ex=1;38;2;249;38;114:fi=0:ln=0;38;2;249;38;114:mh=0:mi=0;38;2;0;0;0;48;2;255;74;68:no=0:or=0;38;2;0;0;0;48;2;255;74;68:ow=0:pi=0;38;2;0;0;0;48;2;102;217;239:rs=0:sg=0:so=0;38;2;0;0;0;48;2;249;38;114:st=0:su=0:tw=0:*.1=0;38;2;154;143;0:*.a=1;38;2;249;38;114:*.c=0;38;2;0;174;63:*.d=0;38;2;0;174;63:*.h=0;38;2;0;174;63:*.m=0;38;2;0;174;63:*.o=0;38;2;122;112;112:*.p=0;38;2;0;174;63:*.r=0;38;2;0;174;63:*.t=0;38;2;0;174;63:*.v=0;38;2;0;174;63:*.z=4;38;2;249;38;114:*.7z=4;38;2;249;38;114:*.ai=0;38;2;214;119;0:*.as=0;38;2;0;174;63:*.bc=0;38;2;122;112;112:*.bz=4;38;2;249;38;114:*.cc=0;38;2;0;174;63:*.cp=0;38;2;0;174;63:*.cr=0;38;2;0;174;63:*.cs=0;38;2;0;174;63:*.db=4;38;2;249;38;114:*.di=0;38;2;0;174;63:*.el=0;38;2;0;174;63:*.ex=0;38;2;0;174;63:*.fs=0;38;2;0;174;63:*.go=0;38;2;0;174;63:*.gv=0;38;2;0;174;63:*.gz=4;38;2;249;38;114:*.ha=0;38;2;0;174;63:*.hh=0;38;2;0;174;63:*.hi=0;38;2;122;112;112:*.hs=0;38;2;0;174;63:*.jl=0;38;2;0;174;63:*.js=0;38;2;0;174;63:*.ko=1;38;2;249;38;114:*.kt=0;38;2;0;174;63:*.la=0;38;2;122;112;112:*.ll=0;38;2;0;174;63:*.lo=0;38;2;122;112;112:*.ma=0;38;2;214;119;0:*.mb=0;38;2;214;119;0:*.md=0;38;2;154;143;0:*.mk=0;38;2;100;163;0:*.ml=0;38;2;0;174;63:*.mn=0;38;2;0;174;63:*.nb=0;38;2;0;174;63:*.nu=0;38;2;0;174;63:*.pl=0;38;2;0;174;63:*.pm=0;38;2;0;174;63:*.pp=0;38;2;0;174;63:*.ps=0;38;2;230;219;116:*.py=0;38;2;0;174;63:*.rb=0;38;2;0;174;63:*.rm=0;38;2;214;119;0:*.rs=0;38;2;0;174;63:*.sh=0;38;2;0;174;63:*.so=1;38;2;249;38;114:*.td=0;38;2;0;174;63:*.ts=0;38;2;0;174;63:*.ui=0;38;2;100;163;0:*.vb=0;38;2;0;174;63:*.wv=0;38;2;214;119;0:*.xz=4;38;2;249;38;114:*FAQ=0;38;2;0;0;0;48;2;230;219;116:*.3ds=0;38;2;214;119;0:*.3fr=0;38;2;214;119;0:*.3mf=0;38;2;214;119;0:*.adb=0;38;2;0;174;63:*.ads=0;38;2;0;174;63:*.aif=0;38;2;214;119;0:*.amf=0;38;2;214;119;0:*.ape=0;38;2;214;119;0:*.apk=4;38;2;249;38;114:*.ari=0;38;2;214;119;0:*.arj=4;38;2;249;38;114:*.arw=0;38;2;214;119;0:*.asa=0;38;2;0;174;63:*.asm=0;38;2;0;174;63:*.aux=0;38;2;122;112;112:*.avi=0;38;2;214;119;0:*.awk=0;38;2;0;174;63:*.bag=4;38;2;249;38;114:*.bak=0;38;2;122;112;112:*.bat=1;38;2;249;38;114:*.bay=0;38;2;214;119;0:*.bbl=0;38;2;122;112;112:*.bcf=0;38;2;122;112;112:*.bib=0;38;2;100;163;0:*.bin=4;38;2;249;38;114:*.blg=0;38;2;122;112;112:*.bmp=0;38;2;214;119;0:*.bsh=0;38;2;0;174;63:*.bst=0;38;2;100;163;0:*.bz2=4;38;2;249;38;114:*.c++=0;38;2;0;174;63:*.cap=0;38;2;214;119;0:*.cfg=0;38;2;100;163;0:*.cgi=0;38;2;0;174;63:*.clj=0;38;2;0;174;63:*.com=1;38;2;249;38;114:*.cpp=0;38;2;0;174;63:*.cr2=0;38;2;214;119;0:*.cr3=0;38;2;214;119;0:*.crw=0;38;2;214;119;0:*.css=0;38;2;0;174;63:*.csv=0;38;2;154;143;0:*.csx=0;38;2;0;174;63:*.cxx=0;38;2;0;174;63:*.dae=0;38;2;214;119;0:*.dcr=0;38;2;214;119;0:*.dcs=0;38;2;214;119;0:*.deb=4;38;2;249;38;114:*.def=0;38;2;0;174;63:*.dll=1;38;2;249;38;114:*.dmg=4;38;2;249;38;114:*.dng=0;38;2;214;119;0:*.doc=0;38;2;230;219;116:*.dot=0;38;2;0;174;63:*.dox=0;38;2;100;163;0:*.dpr=0;38;2;0;174;63:*.drf=0;38;2;214;119;0:*.dxf=0;38;2;214;119;0:*.eip=0;38;2;214;119;0:*.elc=0;38;2;0;174;63:*.elm=0;38;2;0;174;63:*.epp=0;38;2;0;174;63:*.eps=0;38;2;214;119;0:*.erf=0;38;2;214;119;0:*.erl=0;38;2;0;174;63:*.exe=1;38;2;249;38;114:*.exr=0;38;2;214;119;0:*.exs=0;38;2;0;174;63:*.fbx=0;38;2;214;119;0:*.fff=0;38;2;214;119;0:*.fls=0;38;2;122;112;112:*.flv=0;38;2;214;119;0:*.fnt=0;38;2;214;119;0:*.fon=0;38;2;214;119;0:*.fsi=0;38;2;0;174;63:*.fsx=0;38;2;0;174;63:*.gif=0;38;2;214;119;0:*.git=0;38;2;122;112;112:*.gpr=0;38;2;214;119;0:*.gvy=0;38;2;0;174;63:*.h++=0;38;2;0;174;63:*.hda=0;38;2;214;119;0:*.hip=0;38;2;214;119;0:*.hpp=0;38;2;0;174;63:*.htc=0;38;2;0;174;63:*.htm=0;38;2;154;143;0:*.hxx=0;38;2;0;174;63:*.ico=0;38;2;214;119;0:*.ics=0;38;2;230;219;116:*.idx=0;38;2;122;112;112:*.igs=0;38;2;214;119;0:*.iiq=0;38;2;214;119;0:*.ilg=0;38;2;122;112;112:*.img=4;38;2;249;38;114:*.inc=0;38;2;0;174;63:*.ind=0;38;2;122;112;112:*.ini=0;38;2;100;163;0:*.inl=0;38;2;0;174;63:*.ino=0;38;2;0;174;63:*.ipp=0;38;2;0;174;63:*.iso=4;38;2;249;38;114:*.jar=4;38;2;249;38;114:*.jpg=0;38;2;214;119;0:*.jsx=0;38;2;0;174;63:*.jxl=0;38;2;214;119;0:*.k25=0;38;2;214;119;0:*.kdc=0;38;2;214;119;0:*.kex=0;38;2;230;219;116:*.kra=0;38;2;214;119;0:*.kts=0;38;2;0;174;63:*.log=0;38;2;122;112;112:*.ltx=0;38;2;0;174;63:*.lua=0;38;2;0;174;63:*.m3u=0;38;2;214;119;0:*.m4a=0;38;2;214;119;0:*.m4v=0;38;2;214;119;0:*.mdc=0;38;2;214;119;0:*.mef=0;38;2;214;119;0:*.mid=0;38;2;214;119;0:*.mir=0;38;2;0;174;63:*.mkv=0;38;2;214;119;0:*.mli=0;38;2;0;174;63:*.mos=0;38;2;214;119;0:*.mov=0;38;2;214;119;0:*.mp3=0;38;2;214;119;0:*.mp4=0;38;2;214;119;0:*.mpg=0;38;2;214;119;0:*.mrw=0;38;2;214;119;0:*.msi=4;38;2;249;38;114:*.mtl=0;38;2;214;119;0:*.nef=0;38;2;214;119;0:*.nim=0;38;2;0;174;63:*.nix=0;38;2;100;163;0:*.nrw=0;38;2;214;119;0:*.obj=0;38;2;214;119;0:*.obm=0;38;2;214;119;0:*.odp=0;38;2;230;219;116:*.ods=0;38;2;230;219;116:*.odt=0;38;2;230;219;116:*.ogg=0;38;2;214;119;0:*.ogv=0;38;2;214;119;0:*.orf=0;38;2;214;119;0:*.org=0;38;2;154;143;0:*.otf=0;38;2;214;119;0:*.otl=0;38;2;214;119;0:*.out=0;38;2;122;112;112:*.pas=0;38;2;0;174;63:*.pbm=0;38;2;214;119;0:*.pcx=0;38;2;214;119;0:*.pdf=0;38;2;230;219;116:*.pef=0;38;2;214;119;0:*.pgm=0;38;2;214;119;0:*.php=0;38;2;0;174;63:*.pid=0;38;2;122;112;112:*.pkg=4;38;2;249;38;114:*.png=0;38;2;214;119;0:*.pod=0;38;2;0;174;63:*.ppm=0;38;2;214;119;0:*.pps=0;38;2;230;219;116:*.ppt=0;38;2;230;219;116:*.pro=0;38;2;100;163;0:*.ps1=0;38;2;0;174;63:*.psd=0;38;2;214;119;0:*.ptx=0;38;2;214;119;0:*.pxn=0;38;2;214;119;0:*.pyc=0;38;2;122;112;112:*.pyd=0;38;2;122;112;112:*.pyo=0;38;2;122;112;112:*.qoi=0;38;2;214;119;0:*.r3d=0;38;2;214;119;0:*.raf=0;38;2;214;119;0:*.rar=4;38;2;249;38;114:*.raw=0;38;2;214;119;0:*.rpm=4;38;2;249;38;114:*.rst=0;38;2;154;143;0:*.rtf=0;38;2;230;219;116:*.rw2=0;38;2;214;119;0:*.rwl=0;38;2;214;119;0:*.rwz=0;38;2;214;119;0:*.sbt=0;38;2;0;174;63:*.sql=0;38;2;0;174;63:*.sr2=0;38;2;214;119;0:*.srf=0;38;2;214;119;0:*.srw=0;38;2;214;119;0:*.stl=0;38;2;214;119;0:*.stp=0;38;2;214;119;0:*.sty=0;38;2;122;112;112:*.svg=0;38;2;214;119;0:*.swf=0;38;2;214;119;0:*.swp=0;38;2;122;112;112:*.sxi=0;38;2;230;219;116:*.sxw=0;38;2;230;219;116:*.tar=4;38;2;249;38;114:*.tbz=4;38;2;249;38;114:*.tcl=0;38;2;0;174;63:*.tex=0;38;2;0;174;63:*.tga=0;38;2;214;119;0:*.tgz=4;38;2;249;38;114:*.tif=0;38;2;214;119;0:*.tml=0;38;2;100;163;0:*.tmp=0;38;2;122;112;112:*.toc=0;38;2;122;112;112:*.tsx=0;38;2;0;174;63:*.ttf=0;38;2;214;119;0:*.txt=0;38;2;154;143;0:*.typ=0;38;2;154;143;0:*.usd=0;38;2;214;119;0:*.vcd=4;38;2;249;38;114:*.vim=0;38;2;0;174;63:*.vob=0;38;2;214;119;0:*.vsh=0;38;2;0;174;63:*.wav=0;38;2;214;119;0:*.wma=0;38;2;214;119;0:*.wmv=0;38;2;214;119;0:*.wrl=0;38;2;214;119;0:*.x3d=0;38;2;214;119;0:*.x3f=0;38;2;214;119;0:*.xlr=0;38;2;230;219;116:*.xls=0;38;2;230;219;116:*.xml=0;38;2;154;143;0:*.xmp=0;38;2;100;163;0:*.xpm=0;38;2;214;119;0:*.xvf=0;38;2;214;119;0:*.yml=0;38;2;100;163;0:*.zig=0;38;2;0;174;63:*.zip=4;38;2;249;38;114:*.zsh=0;38;2;0;174;63:*.zst=4;38;2;249;38;114:*TODO=1:*hgrc=0;38;2;100;163;0:*.avif=0;38;2;214;119;0:*.bash=0;38;2;0;174;63:*.braw=0;38;2;214;119;0:*.conf=0;38;2;100;163;0:*.dart=0;38;2;0;174;63:*.data=0;38;2;214;119;0:*.diff=0;38;2;0;174;63:*.docx=0;38;2;230;219;116:*.epub=0;38;2;230;219;116:*.fish=0;38;2;0;174;63:*.flac=0;38;2;214;119;0:*.h264=0;38;2;214;119;0:*.hack=0;38;2;0;174;63:*.heif=0;38;2;214;119;0:*.hgrc=0;38;2;100;163;0:*.html=0;38;2;154;143;0:*.iges=0;38;2;214;119;0:*.info=0;38;2;154;143;0:*.java=0;38;2;0;174;63:*.jpeg=0;38;2;214;119;0:*.json=0;38;2;100;163;0:*.less=0;38;2;0;174;63:*.lisp=0;38;2;0;174;63:*.lock=0;38;2;122;112;112:*.make=0;38;2;100;163;0:*.mojo=0;38;2;0;174;63:*.mpeg=0;38;2;214;119;0:*.nims=0;38;2;0;174;63:*.opus=0;38;2;214;119;0:*.orig=0;38;2;122;112;112:*.pptx=0;38;2;230;219;116:*.prql=0;38;2;0;174;63:*.psd1=0;38;2;0;174;63:*.psm1=0;38;2;0;174;63:*.purs=0;38;2;0;174;63:*.raku=0;38;2;0;174;63:*.rlib=0;38;2;122;112;112:*.sass=0;38;2;0;174;63:*.scad=0;38;2;0;174;63:*.scss=0;38;2;0;174;63:*.step=0;38;2;214;119;0:*.tbz2=4;38;2;249;38;114:*.tiff=0;38;2;214;119;0:*.toml=0;38;2;100;163;0:*.usda=0;38;2;214;119;0:*.usdc=0;38;2;214;119;0:*.usdz=0;38;2;214;119;0:*.webm=0;38;2;214;119;0:*.webp=0;38;2;214;119;0:*.woff=0;38;2;214;119;0:*.xbps=4;38;2;249;38;114:*.xlsx=0;38;2;230;219;116:*.yaml=0;38;2;100;163;0:*stdin=0;38;2;122;112;112:*v.mod=0;38;2;100;163;0:*.blend=0;38;2;214;119;0:*.cabal=0;38;2;0;174;63:*.cache=0;38;2;122;112;112:*.class=0;38;2;122;112;112:*.cmake=0;38;2;100;163;0:*.ctags=0;38;2;122;112;112:*.dylib=1;38;2;249;38;114:*.dyn_o=0;38;2;122;112;112:*.gcode=0;38;2;0;174;63:*.ipynb=0;38;2;0;174;63:*.mdown=0;38;2;154;143;0:*.patch=0;38;2;0;174;63:*.rmeta=0;38;2;122;112;112:*.scala=0;38;2;0;174;63:*.shtml=0;38;2;154;143;0:*.swift=0;38;2;0;174;63:*.toast=4;38;2;249;38;114:*.woff2=0;38;2;214;119;0:*.xhtml=0;38;2;154;143;0:*Icon\r=0;38;2;122;112;112:*LEGACY=0;38;2;0;0;0;48;2;230;219;116:*NOTICE=0;38;2;0;0;0;48;2;230;219;116:*README=0;38;2;0;0;0;48;2;230;219;116:*go.mod=0;38;2;100;163;0:*go.sum=0;38;2;122;112;112:*passwd=0;38;2;100;163;0:*shadow=0;38;2;100;163;0:*stderr=0;38;2;122;112;112:*stdout=0;38;2;122;112;112:*.bashrc=0;38;2;0;174;63:*.config=0;38;2;100;163;0:*.dyn_hi=0;38;2;122;112;112:*.flake8=0;38;2;100;163;0:*.gradle=0;38;2;0;174;63:*.groovy=0;38;2;0;174;63:*.ignore=0;38;2;100;163;0:*.matlab=0;38;2;0;174;63:*.nimble=0;38;2;0;174;63:*COPYING=0;38;2;182;182;182:*INSTALL=0;38;2;0;0;0;48;2;230;219;116:*LICENCE=0;38;2;182;182;182:*LICENSE=0;38;2;182;182;182:*TODO.md=1:*VERSION=0;38;2;0;0;0;48;2;230;219;116:*.alembic=0;38;2;214;119;0:*.desktop=0;38;2;100;163;0:*.gemspec=0;38;2;100;163;0:*.mailmap=0;38;2;100;163;0:*Doxyfile=0;38;2;100;163;0:*Makefile=0;38;2;100;163;0:*TODO.txt=1:*setup.py=0;38;2;100;163;0:*.DS_Store=0;38;2;122;112;112:*.cmake.in=0;38;2;100;163;0:*.fdignore=0;38;2;100;163;0:*.kdevelop=0;38;2;100;163;0:*.markdown=0;38;2;154;143;0:*.rgignore=0;38;2;100;163;0:*.tfignore=0;38;2;100;163;0:*CHANGELOG=0;38;2;0;0;0;48;2;230;219;116:*COPYRIGHT=0;38;2;182;182;182:*README.md=0;38;2;0;0;0;48;2;230;219;116:*bun.lockb=0;38;2;122;112;112:*configure=0;38;2;100;163;0:*.gitconfig=0;38;2;100;163;0:*.gitignore=0;38;2;100;163;0:*.localized=0;38;2;122;112;112:*.scons_opt=0;38;2;122;112;112:*.timestamp=0;38;2;122;112;112:*CODEOWNERS=0;38;2;100;163;0:*Dockerfile=0;38;2;100;163;0:*INSTALL.md=0;38;2;0;0;0;48;2;230;219;116:*README.txt=0;38;2;0;0;0;48;2;230;219;116:*SConscript=0;38;2;100;163;0:*SConstruct=0;38;2;100;163;0:*.cirrus.yml=0;38;2;230;219;116:*.gitmodules=0;38;2;100;163;0:*.synctex.gz=0;38;2;122;112;112:*.travis.yml=0;38;2;230;219;116:*INSTALL.txt=0;38;2;0;0;0;48;2;230;219;116:*LICENSE-MIT=0;38;2;182;182;182:*MANIFEST.in=0;38;2;100;163;0:*Makefile.am=0;38;2;100;163;0:*Makefile.in=0;38;2;122;112;112:*.applescript=0;38;2;0;174;63:*.fdb_latexmk=0;38;2;122;112;112:*.webmanifest=0;38;2;100;163;0:*CHANGELOG.md=0;38;2;0;0;0;48;2;230;219;116:*CONTRIBUTING=0;38;2;0;0;0;48;2;230;219;116:*CONTRIBUTORS=0;38;2;0;0;0;48;2;230;219;116:*appveyor.yml=0;38;2;230;219;116:*configure.ac=0;38;2;100;163;0:*.bash_profile=0;38;2;0;174;63:*.clang-format=0;38;2;100;163;0:*.editorconfig=0;38;2;100;163;0:*CHANGELOG.txt=0;38;2;0;0;0;48;2;230;219;116:*.gitattributes=0;38;2;100;163;0:*.gitlab-ci.yml=0;38;2;230;219;116:*CMakeCache.txt=0;38;2;122;112;112:*CMakeLists.txt=0;38;2;100;163;0:*LICENSE-APACHE=0;38;2;182;182;182:*pyproject.toml=0;38;2;100;163;0:*CODE_OF_CONDUCT=0;38;2;0;0;0;48;2;230;219;116:*CONTRIBUTING.md=0;38;2;0;0;0;48;2;230;219;116:*CONTRIBUTORS.md=0;38;2;0;0;0;48;2;230;219;116:*.sconsign.dblite=0;38;2;122;112;112:*CONTRIBUTING.txt=0;38;2;0;0;0;48;2;230;219;116:*CONTRIBUTORS.txt=0;38;2;0;0;0;48;2;230;219;116:*requirements.txt=0;38;2;100;163;0:*package-lock.json=0;38;2;122;112;112:*CODE_OF_CONDUCT.md=0;38;2;0;0;0;48;2;230;219;116:*.CFUserTextEncoding=0;38;2;122;112;112:*CODE_OF_CONDUCT.txt=0;38;2;0;0;0;48;2;230;219;116:*azure-pipelines.yml=0;38;2;230;219;116"

do --env {
    # TODO Consider externalizing these configs. But maybe not.
    let default_java = 21
    let default_node = "23"
    let default_postgres = "17"
    try { activate-my-open-jdk $default_java } catch { print "(warn) A default OpenJDK was not activated." }
    try { activate-my-node $default_node } catch { print "(warn) A default Node.js was not activated." }
    try { activate-postgres $default_postgres } catch { print "(warn) A default Postgres was not activated." }
}

if ($env.MY_DEBUG?) {
    let end = date now | into int
    let diff = $end - $start
    let dur = $diff | into duration
    print $"'config.nu' took ($dur)"
}
