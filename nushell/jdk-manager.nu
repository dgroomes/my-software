# ABANDONED: but I'm keeping a reference to the code for posterity, especially for the sample 'url' commands because
# I haven't used that much in Nushell.
#
# Managing local installations of OpenJDK. I want to support switching between versions. And optionally, installing
# new versions.
#
# After some prototyping, I've realized that switching is by far the most important feature, and might be the least
# amount of work too because it doesn't have to handle network requests, breaking changes in the Adoptium API, etc.
# Focus on your blue chip features first.
#
# I also realized that installing a version of Eclipse Temurin is different than discovering versions of OpenJDK. I've
# decided that discovering news versions of Eclipse Temurin is something I want to do manually. I want to skim the
# release notes. I need to manually decide what's noise (i.e. no-frills patch release of a non-LTS version) and what's
# signal (i.e. a patch release that fixes a severe defect on macOS).
#
# Installing a version of Eclipse Temurin should be somewhat scripted. At this point, the download URL is known, the
# hash of the download is known, and the installation directory is known. The only job left for the script is the
# download request, handling errors with useful error messages, verifying the hash, extracting the archive, checking if
# the version is already installed, and finally moving the installation files to the right place.
#
# Update: should I even bother with installation scripts? I'd rather just use the installer because it knows the
# conventional installation location and should handle errors and edge cases better than I could. Hmm well I don't know
# what the installer did w.r.t the PATH. Answer: yeah I writes a weird launcher straight into /usr/bin. I don't want
# that. I don't need these "many versioned tools" like Python, Java, Node, etc in a typical PATH location. I want my
# shell to add a default-but-switchable directory to the PATH at runtime. I've heard the symlink described well
# somewhere, maybe as "shims"? That's a valid way, but it's not what I want.
#
# https://github.com/adoptium/api.adoptium.net
# https://api.adoptium.net
# https://api.adoptium.net/q/swagger-ui

const adoptium_api_host = "api.adoptium.net"

# const known_distributions = [
#   {
#     release_name: "jdk-17.0.11+9"
#     sha256: "09a162c58dd801f7cfacd87e99703ed11fb439adc71cfa14ceb2d3194eaca01c"
#   }
# ]

# const options = {
#   architecture: "aarch64"
#   image_type: "jdk"
#   lts: "true"
#   project: "jdk"
#   release_type: "ga"
#   vendor: "eclipse"
# }

# Fetch releases of Eclipse Temurin by querying the Adoptium API.
#
# This queries the "release_names" endpoint and stores the results in a cache file.
#export def refresh-releases [] {
#  let url_components = {
#    scheme: https,
#    host: $adoptium_api_host,
#    path: "/v3/info/release_names",
#    params: {
#      lts: "true",
#      page: 0,
#      page_size: 20,
#      release_type: "ga"
#    }
#  }
#
#  # We need to paginate. The API returns a "Link" HTTP header but I don't like the implementation because it actually
#  # doesn't provide a "Link" header on the last page. This is somewhat unusual because a "Link" header is typically
#  # present on a response for any page and includes some combination of "first", "prev", "next", and "last" links.
#  #
#  # Also the "Link" header is returned in lowercase ("link"). Also, as usual, I would have to parse out the "Link" header
#  # by hand and/or using regex. This is on the fragile side of things. I'd much rather just make requests until I outrun
#  # the data. Usually an API returns an empty array when you've reached beyond the last page, but this API returns a
#  # 404.
#  let url = $url_components | url join
#  let response = http get --full $url
#  $response
#}


# List distributions of Eclipse Temurin by querying the Adoptium API (https://api.adoptium.net/q/swagger-ui/)
# export def list-releases [--refresh = false] {
#     if ($refresh) {
#         print "Fetching distribution list from Adoptium API..."
#         # TODO write to a cache file
#     }
#
#     # TODO read from cache file
# }

# How do we do a simple install of "Eclipse Temurin"? There is a really nice example of this in the Adoptium cookbook: https://github.com/adoptium/api.adoptium.net/blob/main/docs/cookbook.adoc#example-three-scripting-a-download-using-the-adoptium-api
# Temurin releases: https://adoptium.net/temurin/releases/
# export def install [] {
#
# }

# Download a distribution of Eclipse Temurin.
#
# Return the path to the downloaded file.
export def jdk-download [] {
  let release_name = "jdk-17.0.11+9" # TODO parameterize with completions

  let cache_path = [$env.HOME ".cache"] | path join | path expand
  mkdir $cache_path

  let url_path = ["/v3/binary/version" $release_name "mac/aarch64/jdk/hotspot/normal/eclipse"] | path join
  let url_components = {
    scheme: "https",
    host: $adoptium_api_host,
    path: $url_path,
  }

  let url = $url_components | url join

  # Make a FETCH request to determine the file name from the "Content-Disposition" header
  let file_name = try {
    http head $url | where name =~ "(?i)Content-Disposition" | first | get value | parse --regex 'filename=(\S*)' | get capture0 | first
  } catch {
    error make { msg: "Unexpected error during FETCH request and subsequent parsing to identity the file name from the 'Content-Disposition' header." }
  }

  let download_path = [$cache_path $file_name] | path join | path expand
  if ($download_path | path exists) {
    print $"The OpenJDK distribution was previously downloaded at '($download_path)'. Skipping download."
    return $download_path
  }

  http get $url | save --progress $download_path
  $download_path
}

# Given that the binary is already downloaded, install it into the system.
export def jdk-install-from-download [download_path: string] {
  if not ($download_path | path exists) {
    error make { msg: "No file exists at '($download_path)'. Exiting." }
  }

  let base_dir = $download_path | path dirname
  cd $base_dir
  let file_components = $download_path | path parse --extension "tar.gz"

  if ($file_components.extension | is-empty) {
    error make { msg: $"The downloaded file ($download_path) is not a '.tar.gz' archive. This is unexpected. Exiting." }
  }

  let extracted_dir = $file_components.stem
  let extracted_dir_path = [$base_dir $file_components.stem] | path join | path expand
  print $"extracted_dir_path: ($extracted_dir_path)"
  if ($extracted_dir_path | path exists) {
    print $"The binary was previously extracted to ($extracted_dir_path). Skipping extraction."
    return
  }

  print $"Extracting the downloaded binary from path '($download_path)'"
  print $"Current directory: (pwd)"
  # let result = do { tar -xf $download_path } | complete
  tar -xf $download_path
  #if ($result.exit_code != 0) {
  #  error make --unspanned {
  #    msg: ("Something unexpected went wrong while unzipping the download." + (char newline) + $result.stderr)
  #  }
  #} else {
  #  print $result.stdout
  #}
#
  #print $"TODO: install ($extracted_dir) into the right place."
}
