#!/usr/bin/env python3
"""Configure Pi's proxy provider, taking this worker's proxy key on stdin."""

import argparse
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from urllib.parse import urlsplit

LEGACY_PROVIDERS = ('fleet-claude', 'fleet-codex')
PROXY_FAVORITE_PROVIDERS = (*LEGACY_PROVIDERS, 'anthropic', 'openai', 'openai-codex', 'meta', 'muse-code')
ANTIGRAVITY_PROVIDERS = ('antigravity', 'google-antigravity')
NEON_ID = 'ag-gemini-4-neon'
NEON_EFFORTS = ('low', 'medium', 'high', 'xhigh')
MODEL_FIELDS = (
    'id', 'name', 'input', 'inputLimits', 'contextWindow', 'maxTokens',
    'reasoning', 'cost', 'thinkingLevelMap',
)


def write_private(path, value, *, expected_mtime_ns=None):
    with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, delete=False) as fout:
        tmp = Path(fout.name)
        try:
            fout.write(value)
            fout.close()
            if expected_mtime_ns is not None and path.stat().st_mtime_ns != expected_mtime_ns:
                raise RuntimeError('Settings changed during migration; rerun the installer.')
            os.replace(tmp, path)
        finally:
            tmp.unlink(missing_ok=True)


def advertised_models(base, key):
    response = subprocess.check_output([
        'curl', '--disable', '--noproxy', '*', '-fsS', '--max-time', '10', '-K', '-',
        f'{base}/v1/models',
    ], input=f'header = "Authorization: Bearer {key}"\n', text=True)
    try:
        models = json.loads(response)['data']
        return {
            (model['owned_by'], model['id']) for model in models
            if model.get('owned_by') in ('anthropic', 'openai', 'meta', 'antigravity')
            and isinstance(model.get('id'), str)
        }
    except (KeyError, TypeError, AttributeError, ValueError) as error:
        raise RuntimeError('Invalid hub model catalog.') from error


def pi_catalog():
    # Don't let discovery read or refresh the user's credentials.
    with tempfile.TemporaryDirectory(prefix='t3-router-catalog-') as directory:
        env = {name: value for name, value in os.environ.items()
               if not name.startswith(('PI_', 'ANTHROPIC_', 'OPENAI_', 'META_'))}
        env.update(PI_CODING_AGENT_DIR=directory, ANTHROPIC_API_KEY='catalog-only',
                   OPENAI_API_KEY='catalog-only', META_API_KEY='catalog-only')
        response = subprocess.check_output([
            'pi', '--offline', '--no-session', '--no-extensions', '--no-context-files',
            '--no-skills', '--no-mcp', '--mode', 'rpc',
        ], input='{"id":"fleet-inventory","type":"get_available_models"}\n',
            text=True, cwd=directory, env=env, timeout=15)
    for line in response.splitlines():
        try:
            frame = json.loads(line)
        except ValueError:
            continue
        if frame.get('id') == 'fleet-inventory' and frame.get('success'):
            return frame['data']['models']
    raise RuntimeError('Pi did not return its model catalog.')


def muse_model(model_id):
    # Older Pi catalogs lack the subscription-only variants. Use conservative
    # limits for these exact families, and let the local Pi catalog take priority.
    match = re.fullmatch(r'muse-(spark-1\.[123]|wonder(?:-full)?-1\.0|ember-1\.0)(-contributor)?', model_id)
    if not match:
        return None
    family, contributor = match.groups()
    levels = ('low', 'medium', 'high', 'xhigh') if family == 'spark-1.1' else (
        'minimal', 'low', 'medium', 'high', 'xhigh',
    )
    max_effort = not contributor and not family.startswith(('spark-1.1', 'spark-1.2'))
    return {
        'id': model_id, 'name': model_id.replace('-', ' ').title(),
        'contextWindow': 1_048_576, 'maxTokens': 65_536 if family.startswith('spark-') else 128_000,
        'input': ['text'] if family == 'ember-1.0' else ['text', 'image'],
        'reasoning': True,
        'thinkingLevelMap': dict.fromkeys(('off', 'minimal', 'max'))
        | {level: level for level in levels} | {'max': 'max' if max_effort else None},
    }


def antigravity_model(model_id):
    if model_id != NEON_ID:
        return None
    return {
        'id': model_id, 'name': 'Gemini 4 Neon (Antigravity)',
        'contextWindow': 1_048_576, 'maxTokens': 65_536, 'input': ['text', 'image'],
        'reasoning': True,
        'thinkingLevelMap': dict.fromkeys(('off', 'minimal', 'max')) | {level: level for level in NEON_EFFORTS},
    }


def proxy_models(base, advertised, catalog, providers):
    models = {}

    def add(owner, model):
        model_id = model['id']
        if (owner, model_id) not in advertised:
            return
        if owner == 'anthropic' and model_id.startswith('claude-'):
            api, endpoint = 'anthropic-messages', base
        elif ((owner == 'openai' and model_id.startswith('gpt-'))
              or (owner == 'meta' and model_id.startswith('muse-'))
              or (owner == 'antigravity' and antigravity_model(model_id) is not None)):
            api, endpoint = 'openai-responses', base + '/v1'
        else:
            return
        # Only copy metadata, never an upstream URL, header, or credential.
        models[model_id] = dict(models.get(model_id, {}), api=api, baseUrl=endpoint)
        models[model_id].update({field: model[field] for field in MODEL_FIELDS if field in model})

    for owner, model_id in advertised:
        if owner == 'meta' and (fallback := muse_model(model_id)) is not None:
            add('meta', fallback)
        elif owner == 'antigravity' and (fallback := antigravity_model(model_id)) is not None:
            add('antigravity', fallback)
    for model in providers.get('proxy', {}).get('models', []):
        model_id = model['id']
        owner = next((owner for prefix, owner in (
            ('claude-', 'anthropic'), ('muse-', 'meta'), ('ag-', 'antigravity'),
        ) if model_id.startswith(prefix)), 'openai')
        add(owner, model)
    for owner, provider in (('anthropic', 'fleet-claude'), ('openai', 'fleet-codex')):
        for model in providers.get(provider, {}).get('models', []):
            add(owner, model)
    for model in catalog:
        if model.get('provider') == 'anthropic':
            add('anthropic', model)
        elif model.get('provider') in ('openai', 'meta') and model.get('api') == 'openai-responses':
            add(model['provider'], model)
    for owner, provider in (('anthropic', 'anthropic'), ('openai', 'openai-codex'), ('openai', 'openai'),
                            ('meta', 'meta'), ('meta', 'muse-code')):
        for model in providers.get(provider, {}).get('models', []):
            add(owner, model)
    return [models[model_id] for model_id in sorted(models)]


def proxy_favorites(favorites, model_ids, pi_instances):
    updated, unchanged, seen = [], [], set()
    for entry in favorites:
        provider, model = entry['provider'], entry['model']
        source, _, model_id = model.partition('/')
        if provider in pi_instances:
            if source == 'proxy' and model_id == f'{NEON_ID}-xhigh' and NEON_ID in model_ids:
                entry = {**entry, 'model': f'proxy/{NEON_ID}'}
            elif source == 'proxy' and model_id.startswith('ag-') and model_id not in model_ids and NEON_ID in model_ids:
                continue
            elif source in ANTIGRAVITY_PROVIDERS and f'ag-{model_id}' in model_ids:
                entry = {**entry, 'model': f'proxy/ag-{model_id}'}
            elif source in PROXY_FAVORITE_PROVIDERS and model_id in model_ids:
                entry = {**entry, 'model': f'proxy/{model_id}'}
            elif source != 'proxy':
                unchanged.append(model)
        identity = provider, entry['model']
        if identity not in seen:
            updated.append(entry)
            seen.add(identity)
    return updated, unchanged


def migrate_t3_favorites(model_ids):
    root = Path(os.environ.get('T3CODE_HOME', str(Path.home() / '.t3')))
    path = root / 'userdata/settings.json'
    if not path.is_file():
        print('No T3 settings file; skipped favorite migration.')
        return
    path = path.resolve()
    try:
        mtime = path.stat().st_mtime_ns
        source = path.read_text()
        config = json.loads(source)
        favorites = config.get('favorites') or []
        pi_instances = {'pi'} | {name for name, instance in config.get('providerInstances', {}).items()
                                 if instance.get('driver') == 'pi'}
        updated, unchanged = proxy_favorites(favorites, model_ids, pi_instances)
        if updated != favorites:
            backup = path.with_name('settings.json.before-proxy-favorites')
            if not backup.exists():
                with open(backup, 'x', opener=_private_opener) as out:
                    out.write(source)
            config['favorites'] = updated
            write_private(path, json.dumps(config, indent=2) + '\n', expected_mtime_ns=mtime)
    except (OSError, ValueError, TypeError, AttributeError, KeyError, RuntimeError) as error:
        sys.exit(f'Could not migrate T3 favorites ({type(error).__name__}).')
    print(f'T3 Pi proxy favorites: {sum(e["provider"] in pi_instances and e["model"].startswith("proxy/") for e in updated)}')
    if unchanged:
        print('Left direct favorites unchanged: ' + ', '.join(sorted(set(unchanged))))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('url', help='HTTPS origin of the hub')
    parser.add_argument('--migrate-t3-favorites', action='store_true')
    args = parser.parse_args()
    url = urlsplit(args.url)
    if (url.scheme != 'https' or not url.hostname or url.username or url.password
            or url.path not in ('', '/') or url.query or url.fragment):
        sys.exit('Expected an HTTPS origin without credentials.')
    base = f'https://{url.netloc}'
    key = sys.stdin.read().strip()
    if not re.fullmatch(r't3-[a-z0-9-]+-[A-Za-z0-9_-]{43}', key):
        sys.exit('Missing or invalid worker key.')
    agent = Path(os.environ.get('PI_CODING_AGENT_DIR', str(Path.home() / '.pi/agent')))
    agent.mkdir(mode=0o700, parents=True, exist_ok=True)
    path = agent / 'models.json'
    credential = agent / 't3-router.key'
    provider_key = '!cat ' + shlex.quote(str(credential))
    try:
        config = json.loads(path.read_text()) if path.exists() else {}
        providers = config.setdefault('providers', {})
        if not isinstance(providers, dict):
            sys.exit('Invalid providers in models.json; config unchanged.')
        for name in (*LEGACY_PROVIDERS, 'proxy'):
            if name in providers and providers[name].get('apiKey') != provider_key:
                sys.exit(f'{name} already exists and is not managed by this installer.')
        models = proxy_models(base, advertised_models(base, key), pi_catalog(), providers)
        if not models:
            sys.exit('No supported hub models found; config unchanged.')
        backup = agent / 'models.json.before-t3-router'
        if any(name in providers for name in LEGACY_PROVIDERS):
            backup = agent / 'models.json.before-unified-proxy'
        if path.exists() and not backup.exists():
            with path.open() as src, open(backup, 'x', opener=_private_opener) as out:
                shutil.copyfileobj(src, out)
        providers['proxy'] = {'baseUrl': base, 'apiKey': provider_key, 'models': models}
        for name in LEGACY_PROVIDERS:
            providers.pop(name, None)
        write_private(credential, key + '\n')
        write_private(path, json.dumps(config, indent=2) + '\n')
    except (OSError, ValueError, AttributeError, KeyError, RuntimeError, subprocess.SubprocessError) as error:
        sys.exit(f'Could not update the Pi model config ({type(error).__name__}).')

    counts = {prefix: sum(model['id'].startswith(prefix) for model in models)
              for prefix in ('claude-', 'gpt-', 'muse-', 'ag-')}
    print(f'Configured proxy: {counts["claude-"]} Claude, {counts["gpt-"]} OpenAI, '
          f'{counts["muse-"]} Muse, {counts["ag-"]} Antigravity models.')
    if args.migrate_t3_favorites:
        migrate_t3_favorites({model['id'] for model in models})


def _private_opener(path, flags):
    return os.open(path, flags, 0o600)


if __name__ == '__main__':
    main()
