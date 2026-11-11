#!/usr/bin/env python3
"""Verify the release artifact, independently of the Flutter build command."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import zipfile

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
    if 'assets/flutter_assets/kernel_blob.bin' in archive.namelist():
        raise SystemExit('Debug Dart kernel found in release artifact')
badging = subprocess.check_output([str(args.build_tools / 'aapt'), 'dump', 'badging', str(args.apk)], text=True)
if "package: name='com.dreamreader.app'" not in badging:
    raise SystemExit('Unexpected application ID')
if 'application-debuggable' in badging:
    raise SystemExit('Release must not be debuggable')
subprocess.run([str(args.build_tools / 'apksigner'), 'verify', '--verbose', '--print-certs', '--min-sdk-version', '26', str(args.apk)], check=True)
subprocess.run([str(args.build_tools / 'zipalign'), '-c', '-P', '16', '4', str(args.apk)], check=True)
checksum = hashlib.sha256(args.apk.read_bytes()).hexdigest()
(args.apk.parent / 'SHA256SUMS').write_text(f'{checksum}  {args.apk.name}\n')
version = re.search(r"versionName='([^']+)'", badging).group(1)
metadata = {'generatedBy': 'CodeRabbit-assisted Dream Reader build', 'applicationId': 'com.dreamreader.app', 'version': version, 'abi': 'arm64-v8a', 'sha256': checksum, 'bytes': args.apk.stat().st_size, 'sourceCommit': os.environ.get('GITHUB_SHA') or subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(), 'staticChecks': ['ZIP CRC', 'release Dart library', 'ARM64 only', 'package ID', 'not debuggable', 'APK signature', '16KB ZIP alignment'], 'deviceChecks': 'See release notes; static verification does not prove runtime compatibility.'}
(args.apk.parent / 'build-info.json').write_text(json.dumps(metadata, indent=2) + '\n')
print(f'Verified {args.apk.name}: {checksum}')
