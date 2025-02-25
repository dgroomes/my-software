use zdu.nu err

# Creates (idempotently) an Obsidian vault at ~/vaults/repos-personal by copying all Markdown
# files from my personal repositories in ~/repos/personal.
#
export def create-vault-repos-personal [] {
    let source_dir = "~/repos/personal" | path expand
    let vault_dir = "~/vaults/repos-personal" | path expand

    if not ($source_dir | path exists) {
        err $"Source directory does not exist: ($source_dir)"
    }

    mkdir $vault_dir

    let md_files = fd --extension md . $source_dir

    for file in $md_files {
        # Calculate the relative path from source_dir so we can preserve the folder structure.
        let rel_path = try {
            $file | path relative-to $source_dir
        } catch { |err|
            print $"Error processing file: ($file)"
            $err
        }
        let dest_path = [$vault_dir $rel_path] | path join

        # Ensure that the parent directory in the vault exists.
        let dest_parent = $dest_path | path dirname
        mkdir $dest_parent

        # Copy the file (overwriting if needed).
        cp $file $dest_path --force
        # print $"Copied: ($file) -> ($dest_path)"
    }

    let count = $md_files | length
    print $"Vault successfully populated with ($count) README.md file\(s) at ($vault_dir)"
}
