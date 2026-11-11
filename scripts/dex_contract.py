#!/usr/bin/env python3
"""Read public DEX linkage without executing extension code.

This checks class/member availability only. Reflection, method behavior, Android
version differences, and live source requests still require runtime testing.
"""
import argparse
from dataclasses import dataclass, field
import hashlib
import json
from pathlib import Path
import re
import struct
import zipfile


@dataclass
class DexClass:
    parents: list[str] = field(default_factory=list)
    methods: set[tuple[str, str]] = field(default_factory=set)
    fields: set[tuple[str, str]] = field(default_factory=set)


@dataclass
class DexInventory:
    classes: dict[str, DexClass] = field(default_factory=dict)
    types: set[str] = field(default_factory=set)
    methods: set[tuple[str, str, str]] = field(default_factory=set)
    fields: set[tuple[str, str, str]] = field(default_factory=set)


def read_dex(data: bytes) -> DexInventory:
    if len(data) < 112 or data[:4] != b'dex\n' or data[7] != 0:
        raise ValueError('Expected a standard DEX file')
    if struct.unpack_from('<I', data, 40)[0] != 0x12345678:
        raise ValueError('Only little-endian DEX is supported')

    def u32(offset):
        return struct.unpack_from('<I', data, offset)[0]

    def uleb(offset):
        result = 0
        for shift in range(0, 35, 7):
            byte = data[offset]
            offset += 1
            result |= (byte & 127) << shift
            if byte < 128:
                return result, offset
        raise ValueError('Malformed DEX integer')

    def string(offset):
        _, offset = uleb(offset)
        # Linkage names are ASCII. Replacement preserves parsing of unrelated
        # modified-UTF8 literals; those literals never enter the contract.
        return data[offset:data.index(b'\0', offset)].decode('utf-8', 'replace')

    def type_list(offset):
        if not offset:
            return []
        return [types[struct.unpack_from('<H', data, offset + 4 + i * 2)[0]]
                for i in range(u32(offset))]

    strings = [string(u32(u32(60) + i * 4)) for i in range(u32(56))]
    types = [strings[u32(u32(68) + i * 4)] for i in range(u32(64))]
    protos = []
    for i in range(u32(72)):
        offset = u32(76) + i * 12
        protos.append('(' + ''.join(type_list(u32(offset + 8))) + ')' + types[u32(offset + 4)])
    methods = []
    for i in range(u32(88)):
        owner, proto, name = struct.unpack_from('<HHI', data, u32(92) + i * 8)
        methods.append((types[owner], strings[name], protos[proto]))
    fields = []
    for i in range(u32(80)):
        owner, type_id, name = struct.unpack_from('<HHI', data, u32(84) + i * 8)
        fields.append((types[owner], strings[name], types[type_id]))
    result = DexInventory(types=set(types), methods=set(methods), fields=set(fields))
    for i in range(u32(96)):
        offset = u32(100) + i * 32
        name, parent = types[u32(offset)], u32(offset + 8)
        item = DexClass(parents=([types[parent]] if parent != 0xffffffff else []) + type_list(u32(offset + 12)))
        cursor = u32(offset + 24)
        if cursor:
            static, cursor = uleb(cursor)
            instance, cursor = uleb(cursor)
            direct, cursor = uleb(cursor)
            virtual, cursor = uleb(cursor)
            for count in (static, instance):
                index = 0
                for _ in range(count):
                    delta, cursor = uleb(cursor)
                    index += delta
                    _, cursor = uleb(cursor)
                    item.fields.add(fields[index][1:])
            for count in (direct, virtual):
                index = 0
                for _ in range(count):
                    delta, cursor = uleb(cursor)
                    index += delta
                    _, cursor = uleb(cursor)
                    _, cursor = uleb(cursor)
                    item.methods.add(methods[index][1:])
        result.classes[name] = item
    return result


def read_apk(path: Path) -> DexInventory:
    result = DexInventory()
    with zipfile.ZipFile(path) as archive:
        for name in archive.namelist():
            if re.fullmatch(r'classes\d*\.dex', name):
                part = read_dex(archive.read(name))
                result.classes.update(part.classes)
                result.types.update(part.types)
                result.methods.update(part.methods)
                result.fields.update(part.fields)
    if not result.classes:
        raise ValueError('APK contains no DEX classes')
    return result


PLATFORM_PREFIXES = ('Ljava/', 'Ljavax/', 'Landroid/', 'Ldalvik/', 'Lorg/json/', 'Lorg/xml/', 'Lorg/w3c/')


def extract_contract(path: Path):
    inventory = read_apk(path)
    def external(name):
        name = name.lstrip('[')
        return len(name) > 1 and name not in inventory.classes and not name.startswith(PLATFORM_PREFIXES)
    return {
        'generatedBy': 'CodeRabbit-assisted static DEX inspection',
        'artifact': path.name,
        'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'types': sorted({name.lstrip('[') for name in inventory.types if external(name)}),
        'methods': sorted(item for item in inventory.methods if external(item[0])),
        'fields': sorted(item for item in inventory.fields if external(item[0])),
        'limitations': 'Static referenced symbols only; excludes Android/JVM classes, reflection and runtime behavior.',
    }


def resolve_member(classes, owner, member, kind, seen=None):
    seen = set() if seen is None else seen
    if owner in seen or owner not in classes:
        return False
    seen.add(owner)
    item = classes[owner]
    if member in getattr(item, kind):
        return True
    # Constructors are never inherited.
    if kind == 'methods' and member[0] in ('<init>', '<clinit>'):
        return False
    return any(resolve_member(classes, parent, member, kind, seen) for parent in item.parents)


def check_contract(classes, contract):
    missing = [name for name in contract['types'] if name not in classes]
    for kind in ('methods', 'fields'):
        for owner, name, descriptor in contract[kind]:
            if not resolve_member(classes, owner, (name, descriptor), kind):
                missing.append(f'{owner}->{name}{descriptor}')
    return missing


def verify(apk: Path, contracts: Path):
    classes = read_apk(apk).classes
    count = 0
    for contract in json.loads(contracts.read_text())['extensions']:
        missing = check_contract(classes, contract)
        if missing:
            raise ValueError(f"Missing extension linkage for {contract['artifact']}: " + ', '.join(missing))
        count += sum(len(contract[key]) for key in ('types', 'methods', 'fields'))
    return count


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('apk', type=Path)
    parser.add_argument('--contracts', type=Path, help='Verify host APK against this recorded reference contract')
    args = parser.parse_args()
    if args.contracts:
        print(f'Verified {verify(args.apk, args.contracts)} extension symbols')
    else:
        print(json.dumps(extract_contract(args.apk), indent=2))
