#!/usr/bin/env python3
"""Verify the release artifact, independently of the Flutter build command."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import struct
import zipfile
from verify_extension_types import verify as verify_extension_types
from dex_contract import verify as verify_extension_contract

parser = argparse.ArgumentParser()
parser.add_argument('apk', type=Path)
parser.add_argument('--build-tools', type=Path, required=True)
args = parser.parse_args()
with zipfile.ZipFile(args.apk) as archive:
    corrupt = archive.testzip()
    if corrupt:
        raise SystemExit(f'Corrupt ZIP member: {corrupt}')
    libraries = [name for name in archive.namelist() if name.startswith('lib/') and name.endswith('.so')]
    if not libraries or any(name.split('/')[1] != 'arm64-v8a' for name in libraries):
        raise SystemExit('APK must contain ARM64 native libraries only')
    for required in ('lib/arm64-v8a/libapp.so', 'lib/arm64-v8a/libflutter.so'):
        if required not in libraries:
            raise SystemExit(f'Missing Flutter release library: {required}')
    for name in libraries:
        data = archive.read(name)
        if data[:6] != b'\x7fELF\x02\x01' or struct.unpack_from('<H', data, 18)[0] != 183:
            raise SystemExit(f'Not a little-endian ARM64 ELF: {name}')
        offset = struct.unpack_from('<Q', data, 32)[0]
        entry_size, count = struct.unpack_from('<HH', data, 54)
        for index in range(count):
            entry = struct.unpack_from('<IIQQQQQQ', data, offset + index * entry_size)
            if entry[0] == 1 and (entry[7] < 16384 or entry[2] % 16384 != entry[3] % 16384):
                raise SystemExit(f'ELF load segment is not 16KB compatible: {name}')
    if 'assets/flutter_assets/kernel_blob.bin' in archive.namelist():
        raise SystemExit('Debug Dart kernel found in release artifact')
badging = subprocess.check_output([str(args.build_tools / 'aapt'), 'dump', 'badging', str(args.apk)], text=True)
if "package: name='com.dreamreader.app'" not in badging:
    raise SystemExit('Unexpected application ID')
if 'application-debuggable' in badging:
    raise SystemExit('Release must not be debuggable')
subprocess.run([str(args.build_tools / 'apksigner'), 'verify', '--verbose', '--print-certs', '--min-sdk-version', '26', str(args.apk)], check=True)
subprocess.run([str(args.build_tools / 'zipalign'), '-c', '-P', '16', '4', str(args.apk)], check=True)
type_tokens = verify_extension_types(args.apk, args.build_tools / 'dexdump')
print(f'Verified {type_tokens} Injekt type token signatures')
symbols = verify_extension_contract(args.apk, Path(__file__).with_name('extension_contracts.json'))
print(f'Verified {symbols} current Atsumaru/Kagane referenced symbols')
checksum = hashlib.sha256(args.apk.read_bytes()).hexdigest()
(args.apk.parent / 'SHA256SUMS').write_text(f'{checksum}  {args.apk.name}\n')
version = re.search(r"versionName='([^']+)'", badging).group(1)
metadata = {'generatedBy': 'CodeRabbit-assisted Dream Reader build', 'applicationId': 'com.dreamreader.app', 'version': version, 'abi': 'arm64-v8a', 'sha256': checksum, 'bytes': args.apk.stat().st_size, 'sourceCommit': os.environ.get('GITHUB_SHA') or subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(), 'staticChecks': ['ZIP CRC', 'release Dart library', 'ARM64 only', 'package ID', 'not debuggable', 'APK signature', '16KB ZIP alignment', '16KB ELF load segments', 'Injekt generic type signatures', 'Atsumaru/Kagane static class and member linkage'], 'deviceChecks': 'See release notes; static verification does not prove runtime compatibility.'}
(args.apk.parent / 'build-info.json').write_text(json.dumps(metadata, indent=2) + '\n')
print(f'Verified {args.apk.name}: {checksum}')
