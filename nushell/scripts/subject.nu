use zdu.nu *
use my-dir.nu *

# Make a new directory for some "subject". This is designed to be a workspace to explore the subject. As such, a README.md
# file is created and a Git repo is initialized.
#
# The subject name is optional. If omitted, the created directory's name will
# also include the current time.
#
#     new-subject my-experiment   # Will create the directory '~/subjects/2020-02-09_my-experiment'
#     new-subject                 # Will create the directory '~/subjects/2020-02-09_18-02-05'
#
# This also runs 'my-dir-init' to initialize the '.my' directory with conventional files.
#
export def --env new-subject [subject?] {
    let today = date now | format date "%Y-%m-%d"
    let descriptor = coalesce $subject (date now | format date "%H-%M-%S")
    let dirname = $today + "_" + $descriptor
    let dir = [$nu.home-dir subjects $dirname] | path join | path expand
    if ($dir | path exists) {
        error make --unspanned {
          msg: ("The directory already exists: " + $dir)
          help: "Use another subject name."
        }
    }

    mkdir $dir
    print $"Created directory: ($dir). Navigating to it."
    cd $dir

    let title = coalesce $subject "README"

    # Create the conventional files
    $"# ($title)

" | save README.md

    git init
    git add README.md
    let commit_msg = if ($subject | is-empty) { "Subject initialized" } else { "Subject initialized: ($subject)"}
    git commit -m $commit_msg

    my-dir-init
}
