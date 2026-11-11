#!/usr/bin/env python3
"""Check Injekt reflection metadata in the actual minified DEX, not source files."""
import argparse
from pathlib import Path
import re
import subprocess
import tempfile
import zipfile

BASE = 'Luy/kohesive/injekt/api/FullTypeReference;'
REQUIRED = {
    'Landroid/content/Context;',
    'Leu/kanade/tachiyomi/network/NetworkHelper;',
    'Leu/kanade/tachiyomi/network/JavaScriptEngine;',
    'Lkotlinx/serialization/json/Json;',
    'Lkotlinx/serialization/protobuf/ProtoBuf;',
}


def inspect_dump(lines):
    """Return generic signatures of direct FullTypeReference subclasses."""
    signatures, tokens = {}, []
    class_id, descriptor, class_annotations = None, None, False
    for line in lines:
        header = re.match(r'Class #(\d+)\s+(annotations:|-)', line)
        if header:
            class_id = int(header[1])
            class_annotations = False
        if line.startswith('Annotations on '):
            class_annotations = line.strip() == 'Annotations on class'
        if class_annotations and 'Ldalvik/annotation/Signature;' in line:
            signatures[class_id] = ''.join(re.findall(r'"([^"\n]*)"', line))
        if 'Class descriptor  :' in line:
            descriptor = line.split("'")[1]
        if 'Superclass        :' in line and f"'{BASE}'" in line:
            tokens.append((descriptor, signatures.get(class_id, '')))
    return tokens


def verify(apk, dexdump):
    tokens = []
    with tempfile.TemporaryDirectory(prefix='dream-dex-') as directory:
        with zipfile.ZipFile(apk) as archive:
            for name in archive.namelist():
                if not re.fullmatch(r'classes\d*\.dex', name):
                    continue
                path = Path(directory) / name
                path.write_bytes(archive.read(name))
                with subprocess.Popen(
                    [str(dexdump), '-a', str(path)], stdout=subprocess.PIPE,
                    text=True, errors='replace',
                ) as process:
                    tokens.extend(inspect_dump(process.stdout))
                    if process.wait() != 0:
                        raise ValueError(f'dexdump could not inspect {name}')
    if not tokens:
        raise ValueError('No Injekt type tokens found in release DEX')
    broken = [name for name, signature in tokens if not signature.startswith(BASE[:-1] + '<')]
    if broken:
        raise ValueError('Injekt generic signatures missing: ' + ', '.join(broken))
    registered = set()
    for _, signature in tokens:
        registered.update(t for t in REQUIRED if f'<{t}>' in signature)
    missing = REQUIRED - registered
    if missing:
        raise ValueError('Extension runtime type tokens missing: ' + ', '.join(sorted(missing)))
    return len(tokens)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--dexdump', type=Path, required=True)
    args = parser.parse_args()
    try:
        count = verify(args.apk, args.dexdump)
    except ValueError as error:
        raise SystemExit(str(error)) from error
    print(f'Verified generic signatures for {count} Injekt type tokens')
