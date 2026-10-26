"""Keep one Gandi LiveDNS A record aligned with this network's public IPv4."""

import ipaddress
import json
import os
import urllib.error
import urllib.request
from pathlib import Path


def public_ipv4():
    for endpoint in ("https://api.ipify.org", "https://ipv4.icanhazip.com"):
        try:
            with urllib.request.urlopen(endpoint, timeout=15) as response:  # noqa: S310 (fixed HTTPS URLs)
                address = ipaddress.IPv4Address(response.read(128).decode().strip())
            if address.is_global:
                return str(address)
        except (OSError, ValueError):
            continue
    raise RuntimeError("Could not determine a public IPv4 address")


def update_record(address, token, domain, name, ttl):
    url = f"https://api.gandi.net/v5/livedns/domains/{domain}/records/{name}/A"

    def request(method, data=None):
        req = urllib.request.Request(
            url,
            method=method,
            headers={
                "Authorization": f"Bearer {token}",
                "Content-Type": "application/json",
            },
            data=None if data is None else json.dumps(data).encode(),
        )
        try:
            with urllib.request.urlopen(req, timeout=30) as response:  # noqa: S310 (fixed HTTPS API)
                body = response.read()
                return json.loads(body) if body else None
        except urllib.error.HTTPError as error:
            if method == "GET" and error.code == 404:
                return None
            raise RuntimeError(f"Gandi {method} failed: HTTP {error.code}") from None

    desired = {"rrset_values": [address], "rrset_ttl": ttl}
    current = request("GET")
    if current and all(current.get(key) == value for key, value in desired.items()):
        return False
    request("PUT", desired)
    return True


def main():
    token = (Path(os.environ["CREDENTIALS_DIRECTORY"]) / "gandi-token").read_text().strip()
    domain = os.environ["GANDI_DDNS_DOMAIN"]
    name = os.environ["GANDI_DDNS_NAME"]
    ttl = int(os.environ["GANDI_DDNS_TTL"])
    address = public_ipv4()
    changed = update_record(address, token, domain, name, ttl)
    print(f"{name}.{domain}: {address} ({'updated' if changed else 'unchanged'})")


if __name__ == "__main__":
    main()
