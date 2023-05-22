#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use File::Spec::Functions;
use File::Path qw(make_path);
use Cwd 'abs_path';

# This script is an automated workaround for the integration of HomeBrew-installed 'bash-completion' scripts for modern
# (v2) 'bash-completion' instead of legacy (v1) 'bash-completion'
#
# Specifically, this script creates symlinks pointing to completion files located in the HomeBrew-managed directory
# '/opt/homebrew/etc/bash_completion.d/' and the symlink files are created in
# '$HOME/.local/share/bash-completion/completions' which is a conventional directory that 'bash-completion' looks for
# v2-based completions.
# 
# As an additional feature, the script also cleans up any dangling symlinks in the '.local' directory, which will
# occur if you uninstall a HomeBrew package that came with completions, like 'docker', 'kcat', etc.
#
# For more information, see https://github.com/dgroomes/my-config

sub create_symlink {
    my ($source_file, $dest_file) = @_;
    
    # Create symlink if it doesn't exist
    if (!-l $dest_file) {
        print "Creating symlink for " . basename($source_file) . "...\n";
        symlink($source_file, $dest_file) or warn "Couldn't create symlink: $!";
    }
}

sub remove_symlink {
    my ($dest_file) = @_;
    
    # Check if the symlink is dangling
    if (!-e $dest_file) {
        print "Removing dangling symlink for " . basename($dest_file) . "...\n";
        unlink($dest_file) or warn "Couldn't remove symlink: $!";
    }
}

# Define source and destination directories
my $source_dir = '/opt/homebrew/etc/bash_completion.d/';
my $dest_dir = "$ENV{HOME}/.local/share/bash-completion/completions";

# Check if source directory exists
if (!-d $source_dir) {
    print "Source directory does not exist. Exiting...\n";
    exit;
}

# Check if destination directory exists, if not create it (and intermediate directories).
if (!-d $dest_dir) {
    print "Destination directory ($dest_dir) does not exist. Creating...\n";
    make_path($dest_dir) or die "Unable to create destination directory: $!";
}

# Loop through each file in source directory
opendir(my $dh, $source_dir) or die "Can't open $source_dir: $!";
while (my $filename = readdir $dh) {
    next if $filename =~ /^\./;  # Skip hidden files and directories
    
    my $source_file = catfile($source_dir, $filename);
    my $dest_file = catfile($dest_dir, $filename);
    
    # Skip if it's a directory
    next if -d $source_file;
    
    create_symlink($source_file, $dest_file);
}
closedir $dh;

# Clean up section
# Loop through each file in destination directory
opendir($dh, $dest_dir) or die "Can't open $dest_dir: $!";
while (my $filename = readdir $dh) {
    next if $filename =~ /^\./;  # Skip hidden files and directories
    
    my $dest_file = catfile($dest_dir, $filename);
    
    # Skip if it's not a symlink
    next unless -l $dest_file;
    

    remove_symlink($dest_file);
}
closedir $dh;

print "Done!\n";
