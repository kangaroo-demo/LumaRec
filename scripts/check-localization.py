#!/usr/bin/env python3
"""Check every literal UI/export error key and parity, without third-party Python packages."""
import json
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parent.parent
catalogs = {}
for language in ('en', 'zh-Hans'):
    path = root / f'Sources/LumaRecCore/Resources/{language}.lproj/Localizable.strings'
    catalogs[language] = json.loads(subprocess.check_output(['plutil', '-convert', 'json', '-o', '-', str(path)]))
assert catalogs['en'].keys() == catalogs['zh-Hans'].keys(), 'Catalog keys do not match'
keys = set()
for relative in ('Sources/LumaRec/AppDelegate.swift', 'Sources/LumaRecCore/NativeExporter.swift', 'Sources/LumaRecCore/RecordingStore.swift'):
    text = (root / relative).read_text()
    for key in re.findall(r'\b(?:L|LF|failure)\("((?:[^"\\]|\\.)*)"', text):
        keys.add(json.loads('"' + key + '"'))
for language, catalog in catalogs.items():
    assert keys <= catalog.keys(), f'{language} missing: {keys - catalog.keys()}'
    for key in keys:
        assert catalog[key], f'{language} empty: {key}'
        assert re.findall(r'%[@df]', key) == re.findall(r'%[@df]', catalog[key]), f'{language} format mismatch: {key}'
print(f'PASS: {len(keys)} UI/export keys in both languages; complete catalogs and format placeholders')
