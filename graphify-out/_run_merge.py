import json
from pathlib import Path

# Use AST as the merged extraction (semantic skipped for code-heavy project)
ast = json.loads(Path('graphify-out/.graphify_ast.json').read_text())
merged = {
    'nodes': ast.get('nodes', []),
    'edges': ast.get('edges', []),
    'hyperedges': [],
    'input_tokens': 0,
    'output_tokens': 0,
}
Path('graphify-out/.graphify_extract.json').write_text(json.dumps(merged, indent=2))
print(f'Merged: {len(merged["nodes"])} nodes, {len(merged["edges"])} edges')
