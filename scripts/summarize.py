#!/usr/bin/env nix-shell
#!nix-shell -p python3 -i python3

import os
from pathlib import Path
import subprocess
import json

def read_summary():
    summary = subprocess.check_output(
        ['nix', 'eval', '--json',
         '--arg', 'bindistTarball', os.environ['GHC_TARBALL'],
         '-f', 'scripts/build-all.nix',
         'summary'],
        encoding = 'UTF-8')

    summary = json.loads(summary)
    for pkg in summary['pkgs']:
        pkg['failed'] = not Path(pkg['out']).exists()
        del pkg['out']

    return summary

def export_logs(summary):
    logs = Path('logs')
    logs.mkdir(exist_ok=True)
    # Deduplicate
    pkgs = { pkg['drvPath']: pkg for pkg in summary['pkgs'] }
    for pkg in pkgs.values():
        print(f'Collecting log for {pkg["drvPath"]}...')
        p = subprocess.run(['nix', 'log', pkg['drvPath']],
                           stdout=open(logs / f'{pkg["drvName"]}.log', 'wb'))
        if p.returncode != 0:
            print(f'Error exporting log for {pkg["drvPath"]}')

def export_dot(summary):
    pkgsDict = { pkg['drvName']: pkg for pkg in summary['pkgs'] }
    edges = {
        (pkg['drvName'], dep)
        for pkg in summary['pkgs']
        for dep in pkg['haskellDeps']
    }

    s = 'digraph {\n'
    s += '  {overlap=prism};\n'

    s += '  subgraph cluster_roots {\n'
    s += '    {fillcolor=blue style=filled};\n'
    for pkg in summary['roots']:
        s += f'    "{pkg}";\n'
    s += '  }\n'
    s += '\n'

    for pkg, dep in edges:
        s +=  f'  "{pkg}" -> "{dep}";\n'

    for pkg in summary['pkgs']:
        if pkg['failed']:
            s += f'  "{pkg["drvName"]}" [ color=indianred style=filled ];\n'

    s += '}'
    return s

def show_failures(summary, log_excerpt=100):
    failed = [pkg
              for pkg in summary['pkgs']
              if pkg['failed']]
    if len(failed) == 0:
        print('='*80)
        print('No issues encountered.')
        print('='*80)
    else:
        print('='*80)
        print('These packages failed to build:')
        print()
        for pkg in failed:
            print('*', pkg['name'])
            print()
            proc = subprocess.run(['nix', 'log', pkg['drvPath']],
                                 stdout=subprocess.PIPE,
                                 encoding='UTF-8')
            if proc.returncode != 0:
                print(f'    Error: Failed to fetch log')
                continue

            print(f'  ---- Last {log_excerpt} lines of log follow ----')
            lines = proc.stdout.split('\n')
            if len(lines) > log_excerpt:
                print('    ⋮')

            print('\n    '.join(lines[-log_excerpt:]))
            print('  ---- End of log ----------------------------')
            print()
            print()

        print('='*80)

if __name__ == "__main__":
    assert os.environ['GHC_TARBALL'] != None
    summary = read_summary()
    export_logs(summary)
    json.dump(summary, Path('summary.json').open('w'))
    show_failures(summary)
    Path('summary.dot').write_text(export_dot(summary))
