# claude-proxy

A filtering HTTP proxy for sandboxing Claude Code sessions using mitmproxy.


## Overview

This proxy only allows traffic to the Anthropic APIs and blocks all other network requests.

The proxy runs on port 9051 and uses mitmproxy's certificate authority to decrypt HTTPS traffic for filtering. Certificates are stored in `~/.config/claude-proxy/`. I've arbitrarily chosen the port 9051. My idea is to use the port range 9050-9059 for my own tooling, if the need arises. It's hard to find a good range. A good reference for what's out there is <https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers>.

On first run, mitmproxy generates a certificate authority in `~/.config/claude-proxy/`. To use the proxy, clients must trust this CA certificate.


## Instructions

Follow these instructions to build and run the proxy.

1. Pre-requisite: Poetry
    * I'm using Poetry `2.1.3` which I installed via `pipx`.
2. Pre-requisite: Python
    * I'm using Python `3.13.3` which is available on my PATH as `python3` and `python3.13`.
3. Install dependencies
    * ```nushell
      poetry install
      ```
4. Run the proxy
    * ```nushell
      poetry run claude-proxy
      ```
    * The proxy will start on `127.0.0.1:9051` and generate CA certificates in `~/.config/claude-proxy/` on first run.
5. Build a wheel distribution
    * ```nushell
      poetry build
      ```
6. Install the wheel distribution
    * ```nushell
      glob dist/*.whl | first | pipx install --python python3.13 $in
      ```
    * After installation, you can run the proxy directly with:
    * ```nushell
      claude-proxy
      ```
    * To re-install it again later you could use 'reinstall' or '--force' but I prefer just uninstalling it and the installed it again with the original command. Use the following command to uninstall it.
    * ```nushell
      pipx uninstall claude-proxy
      ```
7. Verify that requests to `api.anthropic.com` work
    * ```nushell
      curl --proxy http://127.0.0.1:9051 --cacert ~/.config/claude-proxy/mitmproxy-ca-cert.pem --head https://api.anthropic.com
      ```
8. Verify that requests to other domains are blocked
    * ```nushell
      curl --proxy http://127.0.0.1:9051 --cacert ~/.config/claude-proxy/mitmproxy-ca-cert.pem --head https://mozilla.org
      ```


## Wish List

General clean-ups, TODOs and things I wish to implement for this project:

* [ ] Use "lazy" connection strategy to avoid DNS lookups and TCP handshakes for blocked domains. With the `mitmdump` CLI, there's an option for doing this but when running it programmatically I just can't figure it out.
* [ ] Use a `do.nu` script
* [ ] Convert to `uv`.
* [ ] Consider writing requests/response to a sqlite db, encrypted/sandboxed with macOS facilities?
* [ ] Re-consider how the cert is saved/managed. Codesigning? Idk. 
