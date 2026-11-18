#!/usr/bin/env python3
"""Extract one binary from ordered docker-save layers without unpacking a rootfs."""
import argparse
import io
import json
from pathlib import Path, PurePosixPath
import tarfile

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('archive', type=Path)
parser.add_argument('output', type=Path)
args = parser.parse_args()
if args.output.exists():
    parser.error('output already exists; choose a new file')

binary = None
with tarfile.open(args.archive, 'r:*') as image:
    manifest_file = image.extractfile('manifest.json')
    if manifest_file is None:
        parser.error('expected docker save archive with manifest.json, not docker export')
    manifests = json.load(manifest_file)
    if len(manifests) != 1:
        parser.error('save exactly one image/platform')
    for layer_name in manifests[0]['Layers']:
        layer_file = image.extractfile(layer_name)
        if layer_file is None:
            parser.error('missing layer: ' + layer_name)
        with tarfile.open(fileobj=io.BytesIO(layer_file.read()), mode='r:*') as layer:
            members = [(str(PurePosixPath(member.name.removeprefix('./').lstrip('/'))), member)
                       for member in layer]
            # Whiteouts affect lower layers, not files added by this layer.
            if any(name in ('bin/.wh.terraform', 'bin/.wh..wh..opq', '.wh.bin', '.wh..wh..opq')
                   for name, member in members):
                binary = None
            for name, member in members:
                if name == 'bin/terraform':
                    if not member.isfile() or member.size > 256 * 1024 * 1024:
                        parser.error('terraform must be a regular file <= 256 MiB')
                    contents = layer.extractfile(member)
                    if contents is None:
                        parser.error('could not read binary')
                    binary = contents.read()
if binary is None:
    parser.error('bin/terraform not present after applying layer order')
args.output.parent.mkdir(parents=True, exist_ok=True)
with args.output.open('xb') as target:
    target.write(binary)
args.output.chmod(0o755)
print('Extracted bin/terraform to', args.output, '(not executed)')
