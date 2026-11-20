#!/usr/bin/env python3
"""Initialize the hub's private state on coding, without rotating existing keys."""

import grp
import http.client
import json
import os
import pwd
import re
import secrets
import subprocess
import sys
import tempfile
from pathlib import Path

STATE = Path('/var/lib/t3-router')
CONFIG = STATE / 'config.json'
PRIVATE = Path('/etc/t3-router')
WORKERS = ('coding', 'gmktec-k11', 't480-arthur', 'm900', 'mj11')
NEON_UPSTREAM = 'gemini-4-neon-xhigh'
NEON_ALIAS = 'ag-gemini-4-neon'
# Antigravity returned a bare 429 for Pi's generated preamble/docs. Keep the
# task, tools, project instructions, and rules intact; only trim Pi boilerplate.
PI_PREAMBLES = (
    ('You are a coding assistant running inside pi, a coding agent harness. '
     'Help users inspect files, run commands, and modify code.'),
    ('You are an expert coding assistant operating inside pi, a coding agent harness. '
     'You help users by reading files, executing commands, editing code, and writing new files.'),
)
PI_SYSTEM_RULES = [
    {
        'pattern': '(?m)^' + preamble.replace('.', r'\.') + '$',
        'replacement': 'Assist the user with software development. Follow their instructions and use '
        'the available tools when helpful.',
    }
    for preamble in PI_PREAMBLES
] + [{
    'pattern': r'(?ms)^<docs>\nPi documentation \(read only when the user asks [^\n]*\n.*?^</docs>\n?',
    'replacement': 'Before changing the harness, read the relevant documentation and examples.\n',
}]


def put(path, text, owner=None, *, expected_mtime_ns=None):
    with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, delete=False) as fout:
        tmp = Path(fout.name)
        try:
            fout.write(text)
            fout.close()
            if owner:
                os.chown(tmp, *owner)
            if expected_mtime_ns is not None and path.stat().st_mtime_ns != expected_mtime_ns:
                raise RuntimeError('Router config changed; rerun the command.')
            os.replace(tmp, path)
        finally:
            tmp.unlink(missing_ok=True)


def sync_antigravity_aliases():
    try:
        env = (PRIVATE / 'usage.env').read_text().splitlines()
        management_key = next(line.split('=', 1)[1] for line in env if line.startswith('CPA_MANAGEMENT_KEY='))
        conn = http.client.HTTPConnection('127.0.0.1', 8317, timeout=8)
        try:
            conn.request('GET', '/v8/management/routing/model-definitions/antigravity',
                         headers={'Authorization': 'Bearer ' + management_key})
            response = conn.getresponse()
            if response.status != 200:
                raise RuntimeError(f'Hub management returned HTTP {response.status}.')
            catalog = json.load(response)['models']
        finally:
            conn.close()
        model_ids = {model['id'] for model in catalog if model.get('owned_by') == 'antigravity'}
        if NEON_UPSTREAM not in model_ids:
            raise RuntimeError('The hub returned no Neon route.')
        aliases = [{'name': NEON_UPSTREAM, 'alias': NEON_ALIAS, 'force-mapping': True}]
        stat = CONFIG.stat()
        source = CONFIG.read_text()
        config = json.loads(source)
        oauth = config.setdefault('oauth', {})
        channels = oauth.setdefault('model-alias', {})
        exclusions = oauth.setdefault('excluded-models', {})
        antigravity = oauth.setdefault('providers', {}).setdefault('antigravity', {})
        existing_rules = antigravity.get('sensitive-patterns-replace', [])
        new_rules = [rule for rule in PI_SYSTEM_RULES if rule not in existing_rules]
        blocked = sorted(model_ids - {NEON_UPSTREAM})
        if channels.get('antigravity') != aliases or exclusions.get('antigravity') != blocked or new_rules:
            backup = PRIVATE / ('config.json.before-antigravity-pi-prompt' if new_rules
                                else 'config.json.before-antigravity-neon-only')
            if not backup.exists():
                put(backup, source)
            channels['antigravity'] = aliases
            exclusions['antigravity'] = blocked
            antigravity['sensitive-patterns-replace'] = existing_rules + new_rules
            put(CONFIG, json.dumps(config, indent=2) + '\n', (stat.st_uid, stat.st_gid),
                expected_mtime_ns=stat.st_mtime_ns)
    except (OSError, KeyError, TypeError, ValueError, StopIteration, RuntimeError, http.client.HTTPException) as error:
        sys.exit(f'Unable to sync Antigravity aliases ({type(error).__name__}).')
    print(f'Antigravity: {NEON_ALIAS} only; {len(blocked)} other models excluded.')


def main():
    if os.geteuid() != 0 or sys.argv[1:] not in ([], ['--anthropic-key-stdin'], ['--sync-antigravity-aliases']):
        sys.exit('Run as root, optionally with --anthropic-key-stdin or --sync-antigravity-aliases.')
    if sys.argv[1:] == ['--sync-antigravity-aliases']:
        sync_antigravity_aliases()
        return
    key = sys.stdin.read().strip() if sys.argv[1:] else None
    if key is not None and not re.fullmatch(r'sk-ant-api[A-Za-z0-9_-]+', key):
        sys.exit('Expected an Anthropic Console API key, not an OAuth token.')

    owner = (pwd.getpwnam('t3-router').pw_uid, grp.getgrnam('t3-router').gr_gid)
    PRIVATE.mkdir(mode=0o700, exist_ok=True)
    STATE.mkdir(mode=0o700, exist_ok=True)
    os.chown(STATE, *owner)
    workers = PRIVATE / 'worker-keys.json'
    usage = PRIVATE / 'usage.env'
    try:
        worker_keys = json.loads(workers.read_text()) if workers.exists() else {}
    except (OSError, ValueError):
        sys.exit('Could not read the existing worker key store.')
    for name in WORKERS:
        if name not in worker_keys:
            worker_keys[name] = f't3-{name}-{secrets.token_urlsafe(32)}'
    put(workers, json.dumps(worker_keys, indent=2) + '\n')

    if not usage.exists():
        put(usage, f'CPA_MANAGEMENT_KEY={secrets.token_urlsafe(32)}\n'
                   f'LOGIN_PASSWORD={secrets.token_urlsafe(32)}\n')
    management_key = next(line.split('=', 1)[1] for line in usage.read_text().splitlines()
                          if line.startswith('CPA_MANAGEMENT_KEY='))

    if CONFIG.exists():
        try:
            config = json.loads(CONFIG.read_text())
        except (OSError, ValueError):
            sys.exit('Could not read the existing router config.')
    else:
        hashed = subprocess.check_output(
            ['mkpasswd', '--method=bcrypt', '--rounds=12', '--stdin'],
            input=management_key + '\n', text=True,
        ).strip()
        config = {
            'server': {'host': '127.0.0.1', 'port': 8317, 'discovery': {'enabled': False}},
            'management': {'allow-remote': False, 'secret-key': hashed,
                           'disable-control-panel': True},
            'oauth': {'auth-dir': str(STATE / 'oauth')},
            'observability': {'logs': {'request-log': False}, 'usage': {
                'usage-statistics-enabled': True, 'redis-usage-queue-retention-seconds': 3600}},
        }
    config.setdefault('access', {})['api-keys'] = list(worker_keys.values())
    if key:
        config.setdefault('api-keys', {})['claude'] = [{
            'name': 'anthropic-console', 'keys': [{'api-key': key}],
        }]
    put(CONFIG, json.dumps(config, indent=2) + '\n', owner)


if __name__ == '__main__':
    main()
