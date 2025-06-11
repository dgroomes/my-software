import asyncio
import signal
import sys
from pathlib import Path
from urllib.parse import urlparse
from mitmproxy import options, http
from mitmproxy.tools import dump

HOST = "127.0.0.1"
PORT = 9051

class ClaudeFilter:

    def is_anthropic_domain(self, host: str) -> bool:
        """Check if host is anthropic.com or any subdomain of it. I would rather avoid regex for now for."""
        if host == "anthropic.com":
            return True
        return host.endswith(".anthropic.com")

    def request(self, flow: http.HTTPFlow) -> None:
        host = flow.request.pretty_host

        if self.is_anthropic_domain(host):
            print(f"✅ Allowed: {flow.request.pretty_url}")
        else:
            print(f"❌ Blocked: {flow.request.pretty_url}")
            flow.response = http.Response.make(
                403,
                b"Denied. This is a sandbox.",
                {"Content-Type": "text/plain"}
            )


async def run_proxy():
    config_dir = Path.home() / ".config" / "claude-proxy"
    config_dir.mkdir(parents=True, exist_ok=True)

    opts = options.Options(
        listen_host=HOST,
        listen_port=PORT,
        confdir=str(config_dir),
    )

    master = dump.DumpMaster(opts, with_termlog=False, with_dumper=False)
    master.addons.add(ClaudeFilter())

    print(f"🚀 Claude proxy starting on {HOST}:{PORT}")
    print(f"📁 Certificates stored in: {config_dir}")
    print(f"✅ Allowing: *.anthropic.com")
    print(f"❌ Blocking: all other domains")
    print("")
    print("Press Ctrl+C to stop")

    loop = asyncio.get_running_loop()

    def signal_handler():
        print("\n⏹️  Shutting down...")
        master.shutdown()

    loop.add_signal_handler(signal.SIGINT, signal_handler)
    loop.add_signal_handler(signal.SIGTERM, signal_handler)

    await master.run()


def main():
    asyncio.run(run_proxy())
