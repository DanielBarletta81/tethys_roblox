"""Portable validation of the curated source export; Roblox engine tests stay in Studio."""
import argparse
import json
import re
import subprocess
import tempfile
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
ROOT_FILES = {'.gitignore', '.gitattributes', 'README.md', 'AGENTS.md'}
CREDENTIAL = re.compile(r'\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,}|AKIA[A-Z0-9]{16}|sk-proj-[A-Za-z0-9_-]{30,})\b|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----')


def run(args):
    process = subprocess.run(args, cwd=ROOT, text=True, capture_output=True, timeout=60)
    if process.returncode:
        raise RuntimeError(f"Command failed: {args[0]}\n{process.stdout}{process.stderr}")
    return process.stdout


def tracked_files():
    return [Path(name) for name in run(['git', 'ls-files', '-z']).split('\0') if name]


def allowed(path):
    parts = path.parts
    if path.as_posix() in ROOT_FILES:
        return True
    if parts[0] in ('src', 'tests', 'plugins'):
        return path.suffix in ('.luau', '.txt')
    if parts[0] == 'tools':
        return path.suffix == '.luau' or path.as_posix() in ('tools/ci_checks.py', 'tools/install_luau.py', 'tools/luau-release.json', 'tools/package_terrain_plugin.py')
    if parts[:2] == ('docs', 'engineering'):
        return path.suffix in ('.md', '.json')
    if parts[:2] == ('docs', 'media'):
        return path.suffix in ('.jpg', '.png')
    return parts[:2] == ('.github', 'workflows') and path.suffix == '.yml'


def audit_repository(files):
    if not files:
        raise RuntimeError('No tracked files. Stage the curated project before running repository checks.')
    failures = []
    for path in files:
        absolute = ROOT / path
        if not allowed(path) or absolute.is_symlink():
            failures.append(f'{path}: outside curated publication policy')
            continue
        if path.suffix in ('.jpg', '.png'):
            continue
        text = absolute.read_text(encoding='utf-8')
        if CREDENTIAL.search(text):
            failures.append(f'{path}: possible credential (value not printed)')
        if re.search(r'/Users/[A-Za-z0-9._-]+/|/private/var/(?:folders|tmp)/', text):
            failures.append(f'{path}: local-machine path in public text')
        if path.suffix == '.json':
            json.loads(text)
        if path.suffix == '.md':
            for target in re.findall(r'\]\(([^)]+)\)', text):
                if target.startswith(('https://', 'http://', '#', 'mailto:')):
                    continue
                target = unquote(target.split('#', 1)[0])
                destination = (absolute.parent / target).resolve()
                if not destination.is_relative_to(ROOT) or not destination.exists():
                    failures.append(f'{path}: unresolved relative link {target}')
    if failures:
        raise RuntimeError('\n'.join(failures))
    print(f'Repository checks passed: {len(files)} tracked files; private files excluded; relative links resolve.')


def compile_luau(directory, files):
    compiler = directory / 'luau-compile'
    if not compiler.is_file():
        raise RuntimeError(f'Missing compiler: {compiler}. Run tools/install_luau.py first.')
    sources = [path for path in files if path.suffix == '.luau']
    for path in sources:
        run([str(compiler), '--null', str(path)])
    print(f'Luau syntax passed: {len(sources)} files. This does not perform Roblox type or engine analysis.')


def cordge_policy(directory):
    # Reuse existing Studio test cases, substituting only module lookup and reporting.
    original = (ROOT / 'tests/CordgePolicy.spec.luau').read_text()
    lookup = 'local modules = game.ServerScriptService.OrdovicOpening'
    assert original.count(lookup) == 1 and original.count('return results') == 1
    portable = original.replace(lookup, '''local modules = {
    CordgePolicy = "../src/ServerScriptService/OrdovicOpening/CordgePolicy",
    CordgeDialogue = "../src/ServerScriptService/OrdovicOpening/CordgeDialogue",
}''').replace('return results', '''for _, result in ipairs(results) do
    assert(result.passed, result.name .. ": " .. tostring(result.error))
    print("PASS " .. result.name)
end
assert(#results == 6, "Expected the six shared Cordge policy groups")
print("Cordge policy: " .. #results .. " groups passed")
return results''')
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', prefix='.portable_', suffix='.luau', dir=ROOT / 'tests', delete=False) as handle:
            handle.write(portable)
            temporary = Path(handle.name)
        print(run([str(directory / 'luau'), str(temporary)]).strip())
    finally:
        if temporary:
            temporary.unlink(missing_ok=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--luau-dir', type=Path, required=True)
    args = parser.parse_args()
    files = tracked_files()
    audit_repository(files)
    compile_luau(args.luau_dir.resolve(), files)
    cordge_policy(args.luau_dir.resolve())
    print(run([str(args.luau_dir.resolve() / 'luau'), 'tests/DeathExperience.spec.luau']).strip())
    print(run([str(args.luau_dir.resolve() / 'luau'), 'tests/TethysTerrain.spec.luau']).strip())
    print(run([str(args.luau_dir.resolve() / 'luau'), 'tests/Stratum.spec.luau']).strip())
    print(run(['python3', 'tools/package_terrain_plugin.py']).strip())
    print(run(['python3', 'tools/package_terrain_plugin.py', '--plugin', 'Stratum']).strip())


if __name__ == '__main__':
    main()
