#!/usr/bin/env python3
"""Claude usage monitor for waybar - reads browser cookies to get usage from claude.ai"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Mapping, Optional

import browser_cookie3
from curl_cffi import requests

CLAUDE_DOMAIN = "claude.ai"
DEFAULT_BROWSERS = ("chrome", "chromium", "brave", "firefox")

BASE_HEADERS = {
    "Referer": "https://claude.ai/chats",
    "Origin": "https://claude.ai",
    "Accept": "application/json, text/plain, */*",
}


def load_cookies(
    domain: str, browsers: list[str] | None = None, required: list[str] | None = None
) -> tuple[dict, str]:
    """Load cookies for a domain from the first available browser.

    If `required` is specified, only return cookies from a browser that has all required cookies.
    """
    browsers = list(browsers or DEFAULT_BROWSERS)
    required = required or []
    errors: list[str] = []

    for name in browsers:
        loader = getattr(browser_cookie3, name, None)
        if loader is None:
            errors.append(f"{name}: unsupported")
            continue

        try:
            cj = loader(domain_name=domain)
            cookies = {c.name: c.value for c in cj}
        except Exception as exc:
            errors.append(f"{name}: {exc}")
            continue

        if not cookies:
            errors.append(f"{name}: no cookies")
            continue

        # Check if all required cookies are present
        missing = [r for r in required if r not in cookies]
        if missing:
            errors.append(f"{name}: missing {', '.join(missing)}")
            continue

        return cookies, name

    detail = "; ".join(errors) if errors else "no browsers"
    raise RuntimeError(f"Failed to read cookies: {detail}")


@dataclass
class WindowUsage:
    """Usage information for a time window."""

    utilization: float
    resets_at: Optional[str | int]


def parse_window(raw: Mapping[str, object] | None) -> WindowUsage:
    """Parse window where Claude returns utilization as 0-100%."""
    raw = raw or {}
    util = raw.get("utilization") or 0
    resets = raw.get("resets_at")

    try:
        util_f = float(util)
    except Exception:
        util_f = 0.0

    return WindowUsage(utilization=util_f, resets_at=resets)


def format_eta(reset_at: str | int | None) -> str:
    """Format ETA from ISO string or Unix timestamp."""
    if not reset_at:
        return "0m00s"

    try:
        if isinstance(reset_at, str):
            if reset_at.endswith("Z"):
                reset_at = reset_at[:-1] + "+00:00"
            reset_dt = datetime.fromisoformat(reset_at)
        else:
            reset_dt = datetime.fromtimestamp(reset_at, tz=timezone.utc)

        now = datetime.now(timezone.utc)
        delta = reset_dt - now
    except Exception:
        return "??m??s"

    secs = int(delta.total_seconds())
    if secs <= 0:
        return "0m00s"

    if secs >= 86400:
        days = secs // 86400
        hours = (secs % 86400) // 3600
        return f"{days}d{hours:02}h"

    if secs >= 3600:
        hours = secs // 3600
        mins = (secs % 3600) // 60
        return f"{hours}h{mins:02}m"

    mins = secs // 60
    secs_rem = secs % 60
    return f"{mins}m{secs_rem:02}s"


def get_claude_usage(browsers: list[str] | None = None) -> dict:
    """Fetch Claude usage data using curl_cffi to impersonate Chrome."""
    try:
        cookies, _browser = load_cookies(
            CLAUDE_DOMAIN, browsers, required=["lastActiveOrg"]
        )
    except Exception as e:
        raise RuntimeError(f"Cookie error: {e}")

    org_id = cookies["lastActiveOrg"]

    url = f"https://{CLAUDE_DOMAIN}/api/organizations/{org_id}/usage"

    last_error = None
    for attempt in range(2):
        try:
            resp = requests.get(
                url,
                cookies=cookies,
                headers=BASE_HEADERS,
                impersonate="chrome110",
                timeout=10,
            )

            if resp.status_code == 403:
                raise RuntimeError("403 Forbidden: Refresh Claude page in browser")

            resp.raise_for_status()
            return resp.json()

        except Exception as e:
            last_error = e
            if attempt == 0:
                continue

    raise RuntimeError(f"Request failed: {last_error}")


def print_waybar(usage: dict) -> None:
    """Output JSON for waybar custom module."""
    fh = parse_window(usage.get("five_hour"))
    sd = parse_window(usage.get("seven_day"))

    # Icons (Nerd Font)
    ICON_CLAUDE = "󰚩"  # nf-md-robot (AI)
    ICON_TIMER = "󱎫"  # nf-md-clock_outline
    ICON_CHECK = "󰄬"  # nf-md-check
    ICON_PAUSE = "󰏤"  # nf-md-pause
    ICON_WARN = "󰀪"  # nf-md-alert

    # Default to 5h window, unless 7d window exceeds 80%
    if sd.utilization >= 100:
        pct = 100
        text = f"{ICON_CLAUDE} {ICON_PAUSE} Exhausted"
        win_name = "7d"
    else:
        if sd.utilization > 80:
            target = sd
            win_name = "7d"
            window_length = 604800
        else:
            target = fh
            win_name = "5h"
            window_length = 18000

        pct = int(round(target.utilization))

        # Check if window is unused
        is_unused = False
        window_not_started = target.utilization == 0 and target.resets_at is None

        if target.utilization == 0 and target.resets_at:
            try:
                if isinstance(target.resets_at, str):
                    reset_at_str = target.resets_at
                    if reset_at_str.endswith("Z"):
                        reset_at_str = reset_at_str[:-1] + "+00:00"
                    reset_dt = datetime.fromisoformat(reset_at_str)
                else:
                    reset_dt = datetime.fromtimestamp(target.resets_at, tz=timezone.utc)

                now = datetime.now(timezone.utc)
                reset_after = int((reset_dt - now).total_seconds())
                is_unused = reset_after >= window_length - 1
            except Exception:
                pass

        if is_unused or window_not_started:
            text = f"{ICON_CLAUDE} {ICON_CHECK} Ready"
        else:
            eta = format_eta(target.resets_at)
            text = f"{ICON_CLAUDE} {pct}% {ICON_TIMER} {eta}"

    fh_reset = format_eta(fh.resets_at) if fh.resets_at else "Ready"
    sd_reset = format_eta(sd.resets_at) if sd.resets_at else "Ready"

    # Build usage bars
    def bar(pct: float) -> str:
        filled = int(pct / 10)
        return "█" * filled + "░" * (10 - filled)

    tooltip = (
        f"󰚩 Claude Usage\n"
        f"─────────────────────\n"
        f"5h  {bar(fh.utilization)} {fh.utilization:>3.0f}%  {ICON_TIMER} {fh_reset}\n"
        f"7d  {bar(sd.utilization)} {sd.utilization:>3.0f}%  {ICON_TIMER} {sd_reset}"
    )

    if pct < 50:
        cls = "low"
    elif pct < 80:
        cls = "mid"
    else:
        cls = "high"

    print(json.dumps({"text": text, "tooltip": tooltip, "class": cls, "alt": win_name}))


def print_cli(usage: dict) -> None:
    """Print usage to terminal."""
    print(json.dumps(usage, indent=2))

    fh = parse_window(usage.get("five_hour"))
    sd = parse_window(usage.get("seven_day"))

    def _fmt_reset(win: WindowUsage) -> str:
        if win.utilization == 0 and win.resets_at is None:
            return "Not started"
        return format_eta(win.resets_at)

    print("-" * 40)
    print(f"5-hour : {fh.utilization:.1f}%  (Reset in {_fmt_reset(fh)})")
    print(f"7-day  : {sd.utilization:.1f}%  (Reset in {_fmt_reset(sd)})")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--waybar", action="store_true", help="JSON output for Waybar")
    parser.add_argument(
        "--browser", action="append", help="Browser to try (repeatable)"
    )
    args = parser.parse_args()

    try:
        usage = get_claude_usage(args.browser)
    except Exception as e:
        if args.waybar:
            err_msg = str(e)
            short_err = "Auth" if "403" in err_msg else "Net"
            print(
                json.dumps(
                    {
                        "text": f"󰚩 󰀪 {short_err}",
                        "tooltip": f"󰚩 Claude - Error\n─────────────────────\n{err_msg}",
                        "class": "error",
                    }
                )
            )
            sys.exit(0)
        else:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)

    if args.waybar:
        print_waybar(usage)
    else:
        print_cli(usage)


if __name__ == "__main__":
    main()
