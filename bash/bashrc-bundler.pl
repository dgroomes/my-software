#!/usr/bin/env perl
#
# 'bb' bundles your Bash scripts so that you can speed up your shell startup time.

use v5.30;
use strict;
use warnings;
use File::Spec;
use Time::Piece;
use Time::HiRes qw(gettimeofday);
use File::Copy;
use IPC::Open3;
use Term::ReadKey;

sub main {
    my $instrument_with_perf;

    # Parse the command line arguments. If the user passes the '--help' flag, then print the help text and exit.
    if (scalar(@ARGV) > 0) {
        if ($ARGV[0] eq "--help") {
            print <<'EOF';
bb: .(b)ashrc (b)undler

Bundle together all the Bash code you source when you start a Bash shell.
Source code: https://github.com/dgroomes/my-config/tree/main/bash

Usage: bb [--perf]

    --perf
        Instrument the bundled .bashrc file with benchmarking code to find your slowest scripts.

'bb' is short for '.bashrc bundler'. It is a Perl script that generates a '.bashrc' file from a collection of '.bash'
scripts in the directory `$HOME/.config/bash/`. This is a single-file and zero-dependency script. It is designed to be
copy/pasted onto your own computer in a location like '/usr/local/bin/bb' and it is designed to be edited to your
heart's content: "Copy it, edit it, and run it". Want to change the way the sorting works? Want to source files from
a different directory? Go for it. Change the source code directly and feel free to version control your own copy.

  * This script is designed to run on macOS (although I'm not using any macOS specific things).
  * This script assumes you are using the macOS-bundled version of Perl (v5.30 in macOS Ventura).
  * This script assumes you are using a modern version of Bash (5.x) (macOS does not ship with a modern version
    of Bash).
  * This script does not write or move any files without interactive confirmation from you.
  * This script does not execute any scripts without interactive confirmation from you.

The output of this script is a '.bashrc' file, which is written directly to the user's home directory and replaces the
existing '.bashrc'. Usefully, this script backs up the existing '.bashrc' with a naming convention like '.bashrc.2023-04-03T12:34:56.bak'.

---

'bb' offers two specific benefits:

  1. **Measuring** slowness in your Bash startup time to find the slowest scripts.
  2. **Solving** for slowness in your Bash startup time by pre-building dynamic content and inlining all content.

'bb' accomplishes the *measuring* benefit by instrumenting the generated '.bashrc' file with benchmarking code that
measures the duration it takes to source each Bash script. Using 'bb' in this way is called "instrumented mode".

Use "instrumented mode" to generate an instrumented '.bashrc' file by running 'bb --perf'. Then, start a new Bash
shell instance, wait for it to fully load, and then read the benchmarking results which are printed to the screen.
It will be clear which scripts are slow and which are fast. Here is an example output, where 'misc.bash' contains a big
clump of shell code accumulated over time and is ripe for optimizing:

```text
Script                            Duration (milliseconds) to source into the Bash shell
aliases.bash                      8
nvm.bash                          117
misc.bash                         350
```

For me, I found that the initialization code for 'bash-completion' completions was very slow (hundreds of milliseconds).
After some research, I figured out that 'bash-completion' v2 supports on-demand completion loading. I made sure to use
this approach exclusively and I saved hundreds of milliseconds on my Bash startup time.

The .bashrc file generated using "instrumented mode" does not actually pre-build or inline the scripts. It is NOT
recommended to use the .bashrch generated from 'bb --perf' for everyday use. Consider all of these factors:

  * The "instrumented mode" .bashrc file adds roughly 100-200 milliseconds of execution time because of the benchmarking
    overhead.
  * The "instrumented mode" .bashrc file does not pre-build any scripts.
  * The "instrumented mode" .bashrc file does not inline any scripts.
  * The "instrumented mode" .bashrc file has a runtime dependency on the 'bb' command (NOT YET IMPLEMENTED. I want 'bb' to
    do the timing logic by way of writes from the .bashrc file to a fifo/named-pipe. This is a bit silly but I want what
    I want. Maybe a Unix domain socket but that would be more verbose, but also cooler. IPC is cool.)

You should use the .bashrc file generated from the straight 'bb' command for everyday use. Using 'bb' in this way is
called "normal mode".

"Normal mode" does the actual bundling work (the namesake of 'bb'). There are two aspects to this: pre-building and
inlining. Pre-building is the process of executing scripts that they themselves produce lines of Bash code that are
designed to be evaluated at Bash startup time. For example, Homebrew recommends adding the snippet `eval "$(brew shellenv)"`
to your .bashrc (or equivalent). This snippet takes about 20ms to execute on my computer. But `brew shellenv` outputs
the same small snippet of text every time, so why bother with the dynamism and instead just evaluate the static output?
(Technically you can make a good case for this dynamism, but I am choosing to optimize for startup speed and not
authoring convenience). That's exactly what pre-building does: it evaluates `brew shellenv` and inlines the output
into the generated .bashrc file. Your Bash startup time will always be about 20ms faster (in this example) because it
saves time by eliminating the dynamism of executing `brew shellenv` (remember, Homebrew is a Ruby program).

Inlining is straightforward. Inlining is the process of taking the contents of a script and pasting it into the
generated .bashrc file. The performance savings are quite low because it only saves on the incremental I/O time of
opening and reading from a separate file.

Tip: if you've bundled your scripts using "normal mode" and are interested in benchmarking the speed, you can always use
the standard "time" command. It can't break down the time spent in each script, but it can give you the overall
execution that it takes to start a new interface Bash shell. Use the following command:

```shell
time bash -i -c exit
```

It will output something like this:

```text
real	0m0.226s
user	0m0.088s
sys     0m0.129s
```

This means that it took 226ms to start a new Bash shell and for the new shell instance to fully go through its startup
phase (source .bash_profile, .bashrc, or however you've set it up). 226ms is pretty decent. nvm is still slow because I
can see it's taking 117ms when I use the "instrumented mode" .bashrc file. As a short term workaround, I can just rename
the 'nvm.bash' to 'nvm-ignore.bash' and then 'bb' will not bundle it. I don't do front-end development most of the time
so I can make this compromise.

---

 Consider this example. You have the following two files that you like to source in your .bashrc file:

   * `$HOME/.config/bash/aliases.bash`
   * `$HOME/.config/bash/dynamic-homebrew.bash`

The 'aliases.bash' file contains a bunch of Bash aliases. The 'dynamic-homebrew.bash' file contains the aforementioned
`brew shellenv` command. When you use the 'bb' command, 'bb' will generate a '.bashrc' including the exact contents of
'aliases.bash' and it will contain the contents of the *output* of executing the 'dynamic-homebrew.bash' script.

That's the end of the example. Consider how your own Bash setup can use 'bb' to pre-build and inline all your Bash
setup code. Can you turn a 1 second startup time into a 0.1 second startup time? It might be possible.

---

'bb' bundles your scripts with the following rules:

  * Scripts with the word 'early' in their name are bundled at the top so they execute first.
  * Scripts with the word 'late' in their name are bundled at the bottom so they execute last.
  * After taking into account the other ordering rules, scripts are bundled lexicographically by name so that the order is
    deterministic between bundle procedures.
  * Scripts with the word 'ignore' in their name are ignored.
  * Scripts with the word 'dynamic' in their name are executed by 'bb' (only with your interactive permission) and
    their contents are inlined into the generated '.bashrc' file.
EOF

            exit 0;
        } elsif ($ARGV[0] eq "--perf") {
            # The user has requested that we instrument the bundled .bashrc file to collect execution timings.
            $instrument_with_perf = 1;
        } else {
            die "Unrecognized command line argument: '$ARGV[0]'"
        }
    } else {
        $instrument_with_perf = 0;
    }

    my $config_dir;
    my $bashrc_file;
    {
        my $home = $ENV{"HOME"};
        $config_dir = File::Spec->catdir($home, ".config", "bash");
        if (!-d $config_dir) {
            die "There is no '$config_dir' directory. This directory is required for 'bb' to work.\n";
        }
        $bashrc_file = File::Spec->catfile($home, ".bashrc");
    }

    # Start building up the output file by inserting the header content.
    #
    # Throughout the bundler program we will continue to append to the '$out' string variable and eventually write it to
    # the .bashrc file.
    my $out = header_content($instrument_with_perf);

    # Find the Bash scripts to source and order them by priority,
    my @files;
    {
        opendir(my $dh, $config_dir) || die "Can't open $config_dir: $!";
        @files = readdir($dh);
        # Filter down to only the files that end in '.bash'.
        @files = grep { /\.bash$/ } @files;
        # Ignore files with the word 'ignore' in their name.
        @files = grep { !/ignore/ } @files;
        # Sort by priority
        #  - Names with the word 'early' are sorted first
        #  - Names with the word 'late' are sorted last
        #  - Ties are broken by lexicographic sorting
        @files = sort {
            my $a_priority = priority_as_int($a);
            my $b_priority = priority_as_int($b);
            my $comparison = $a_priority <=> $b_priority;
            if ($comparison == 0) {
                # In the case of a tie, break the tie lexico-graphically.
                return $a cmp $b;
            } else {
                return $comparison;
            }
        } @files;

        closedir $dh;
    }

    # Codegen the .bashrc content.
    # Accumulate the generated content into the '$out' string variable.
    for my $file (@files) {
        # Sanitize the file name
        my $sanitized_file_name;
        {
            # We need to sanitize the file name to make it a valid Bash string literal. Let's just strip away anything that
            # isn't alphanumeric, a dash or a period.
            $sanitized_file_name = $file;
            $sanitized_file_name =~ s/[^a-zA-Z0-9-\.]//g;
        }

        if ($instrument_with_perf == 1) {
           $out .= codegen_instrumented_mode($config_dir, $file, $sanitized_file_name);
        } else {
           $out .= codegen_normal_mode($config_dir, $file, $sanitized_file_name);
        }
    }

    # Insert footer content.
    $out .= footer_content($instrument_with_perf);

    # Back up the existing '.bashrc' file.
    if (-e $bashrc_file) {
        print "Your existing '.bashrc' file will be backed up and replaced with a generated file. Is this okay? (y/n)";
        my $allowed = prompt_yes_or_no();
        if ($allowed == 0) {
            die "The '.bashrc' file will NOT be replaced. Exiting.\n";
        }
        my $timestamp = Time::Piece->new->strftime("%Y-%m-%dT%H:%M:%S");
        my $backup_file = "$bashrc_file.$timestamp.bak";
        print "Backing up '$bashrc_file' to '$backup_file'\n";
        copy($bashrc_file, $backup_file) or die "Failed to back up the '.bashrc' file: $!";
    }

    # Write the bundled Bash content to the '.bashrc' file.
    {
        open(my $bashrc_fh, '>', $bashrc_file) or die "Cannot write the generated .bashrc contents because there was a failure to open the file '$bashrc_file': $!";
        print $bashrc_fh $out;
        close($bashrc_fh);
        print "The '.bashrc' file was generated and placed in your home directory at $bashrc_file\n";
    }
}

sub header_content {
   my $instrument_with_perf = shift;

   my $out =  <<'EOF';
# This file was generated by 'bb' (the ".bashrc bundler").

# 'failure' is taken directly from this great project: https://github.com/colindean/hejmo/blob/0f14c6d00c653fcbb49236c4f2c2f64b267ffb3c/dotfiles/bash_profile#L21
# trap failures during startup more, uh, grandiloquently
failure() {
  local lineno=$2
  local fn=$3
  local exitstatus=$4
  local msg=$5
  local lineno_fns=${1% 0}
  if [[ "$lineno_fns" != "0" ]] ; then
    lineno="${lineno} ${lineno_fns}"
  fi
  echo "${BASH_SOURCE[1]}:${fn}[${lineno}] Failed with status ${exitstatus}: $msg"
}

trap 'failure "${BASH_LINENO[*]}" "$LINENO" "${FUNCNAME[*]:-script}" "$?" "$BASH_COMMAND"' ERR
EOF

  if ($instrument_with_perf == 1) {
    $out .= <<'EOF';

# 'current_time' is taken directly from this great project: https://github.com/colindean/hejmo/blob/0f14c6d00c653fcbb49236c4f2c2f64b267ffb3c/dotfiles/bash_profile#L13
current_time() {
  # macos date doesn't provide resolution greater than seconds
  # gdate isn't on the path yet when we need this but *almost*
  # assuredly perl is and it loads faster than anything else
  # https://superuser.com/a/713000
  perl -MTime::HiRes -e 'printf("%.0f\n",Time::HiRes::time()*1000)'
}

# We use this file to record how long it took to execute (i.e. "timing", "benchmarking") each Bash script that we source.
# Truncate it to delete any previous timings and include the header row.
printf "Script\tDuration (milliseconds) to source into the Bash shell\n" > "$HOME/.bash_source_timings.tsv"

INSTRUMENTED_SCRIPT_NAME=""
INSTRUMENTED_START_TIME=""

# Demarcate the start of a Bash script that we source. The first and only argument is the name of the script.
# Note: we don't want to append to the timings file at this point because we don't want to the I/O overhead to
# have an impact on the timing. So, we save the script name and the start time in global variables.
source_section_start() {
  INSTRUMENTED_SCRIPT_NAME="$1"
  INSTRUMENTED_START_TIME=$(current_time)
}

# Demarcate the end of a Bash script that we source. This function should be called after 'source_section_start'.
source_section_end() {
  local load_end_time=$(current_time)
  local load_duration=$((load_end_time - INSTRUMENTED_START_TIME))

  echo -e "$INSTRUMENTED_SCRIPT_NAME\t$load_duration" >> "$HOME/.bash_source_timings.tsv"
}

# (b)ash (s)ource (t)imings
#
# This is a handy alias that we can use to see how long it took to source each script by looking at the
# "bash_source_timings.tsv" file. Where are the slow scripts?
bst() {
  sort -t $'\t' -n -k 2 "$HOME/.bash_source_timings.tsv" | column -t -s $'\t'
}

EOF
  }

  return $out;
}

# Prompts the user for a 'y' or 'n' response.
# A return value of 1 means 'yes', 0 means 'no'.
sub prompt_yes_or_no {
    while (1) {
        # Not sure how this works exactly but 'cbreak' must send some terminal escape control codes so that characters
        # typed are not actually show in the terminal AND as soon as a character is typed it is readable by this script
        # (no need for pressing the 'enter' key).
        ReadMode('cbreak');
        my $input = ReadKey(0);
        $input = lc($input);
        ReadMode('normal');
        if ($input eq 'y') {
            print("\n");
            return 1;
        } elsif ($input eq 'n') {
            print("\n");
            return 0;
        } else {
            print "Invalid input, please enter 'y' or 'n'\n";
        }
    }
}

sub footer_content {
    my $instrument_with_perf = shift;

    my $out = << 'EOF';
# Unset the custom trap.
trap - ERR
EOF

    if ($instrument_with_perf == 1) {
        $out .= "bst\n";
    }

    return $out;
}

sub priority_as_int {
    my $name = shift;
    if ($name =~ /early/) {
        return -1;
    } elsif ($name =~ /late/) {
        return 1;
    } else {
        return 0;
    }
}

# Generate Bash code to source and benchmark the given Bash script.
#
# This function is used in "instrumented mode".
sub codegen_instrumented_mode {
    my ($config_dir, $file, $sanitized_file_name) = @_;

    my $out = qq{source_section_start "$sanitized_file_name"\n};

    # 'dynamic' files must be executed. We can execute the file and capture its output using process substitution.
    if ($file =~ /dynamic/) {
        $out .= qq{. <("$config_dir/$file")\n};
    } else {
        $out .= qq{. "$config_dir/$file"\n};
    }

    $out .= qq{source_section_end\n};

    return $out;
}


# Generate Bash code as the result of pre-bundling and inlining.
#
# This function is used in "normal mode"
sub codegen_normal_mode {
    my ($config_dir, $file, $sanitized_file_name) = @_;
    my $out = '';


    # Add a header. This is useful if you're browsing the generated .bashrc file so you can make sense of what script
    # the content came from.
    $out .= "\n# *****SECTION START*****: $sanitized_file_name\n";

    # Bundle the script contents.
    my $filepath = File::Spec->catfile($config_dir, $file);
    if ($file =~ /dynamic/) {
        # This is a dynamic file. We need to execute the given script. Prompt the user for permission to do so, then
        # execute it, and capture the output.
        print "Allow execution of '$filepath'? (y/n)";
        if (prompt_yes_or_no()) {
            print "\tExecuting '$filepath'... ";
            # First, check if the script is executable. If it is, execute it directly. Otherwise, execute it using
            # 'bash'.
            if (!-x $filepath) {
                print "The file '$filepath' is not executable. This is not expected. Exiting.\n";
                exit 1;
            }
            $out .= qx("$filepath");
            # Exit if the script failed.
            if ($? != 0) {
                # The terminal escape sequences print the text as red then resets it.
                print "\e[31mThe script '$filepath' exited with an error. Exiting.\e[0m\n";
                exit 1;
            }
            print "done.\n";
        } else {
            print "Skipping '$filepath'.\n";
        }
    } else {
        open my $fh, '<', $filepath;
        # Slurp the whole file into a string
        $out .= do { local $/; <$fh> };
        close $fh;
    }

    # Add a footer.
    $out .= "\n# *****SECTION END*****: $sanitized_file_name\n";

    return $out;
}

main() unless caller;
