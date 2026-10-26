import io
import json
import unittest
import urllib.error
from unittest.mock import patch

import gandi_ddns


class GandiDDNSTest(unittest.TestCase):
    @patch("urllib.request.urlopen")
    def test_unchanged_record_is_not_written(self, urlopen):
        urlopen.return_value = io.BytesIO(
            json.dumps({"rrset_values": ["84.192.12.139"], "rrset_ttl": 300}).encode()
        )
        self.assertFalse(
            gandi_ddns.update_record("84.192.12.139", "test-token", "aheymans.xyz", "home", 300)
        )
        self.assertEqual(urlopen.call_count, 1)

    @patch("urllib.request.urlopen")
    def test_changed_address_updates_only_the_home_a_record(self, urlopen):
        urlopen.side_effect = [
            io.BytesIO(json.dumps({"rrset_values": ["87.67.163.212"], "rrset_ttl": 1800}).encode()),
            io.BytesIO(b""),
        ]
        self.assertTrue(
            gandi_ddns.update_record("84.192.12.139", "test-token", "aheymans.xyz", "home", 300)
        )
        request = urlopen.call_args.args[0]
        self.assertEqual(request.method, "PUT")
        self.assertEqual(
            request.full_url,
            "https://api.gandi.net/v5/livedns/domains/aheymans.xyz/records/home/A",
        )
        self.assertEqual(
            json.loads(request.data), {"rrset_values": ["84.192.12.139"], "rrset_ttl": 300}
        )

    @patch("urllib.request.urlopen")
    def test_private_addresses_are_rejected(self, urlopen):
        urlopen.side_effect = [io.BytesIO(b"127.0.0.1"), io.BytesIO(b"192.168.0.11")]
        with self.assertRaises(RuntimeError):
            gandi_ddns.public_ipv4()

    @patch("urllib.request.urlopen")
    def test_public_ip_lookup_has_a_fallback(self, urlopen):
        urlopen.side_effect = [urllib.error.URLError("offline"), io.BytesIO(b"84.192.12.139\n")]
        self.assertEqual(gandi_ddns.public_ipv4(), "84.192.12.139")


if __name__ == "__main__":
    unittest.main()
