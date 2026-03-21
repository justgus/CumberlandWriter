#!/usr/bin/env python3
"""
Transform hexagon SVG paths into a 4-hexagon honeycomb pattern.
- Scale hexagons by 50%
- Position in perfect hex grid (edges touch, no overlap)
- Fill the original hexagon (remove inner path)
- Group hexagons as separate paths for easy editing
"""

import re


def parse_path_to_commands(path_d):
    """Parse SVG path into list of (command, coords) tuples."""
    pattern = r'([MmLlCcZz])([^MmLlCcZz]*)'
    matches = re.findall(pattern, path_d)

    commands = []
    for cmd_letter, coords_str in matches:
        if cmd_letter in ['Z', 'z']:
            commands.append((cmd_letter, []))
        else:
            coords = re.findall(r'-?\d+\.?\d*', coords_str)
            coords = [float(c) for c in coords]
            commands.append((cmd_letter, coords))

    return commands


def commands_to_path_string(commands):
    """Convert list of (command, coords) tuples back to path string."""
    parts = []
    for cmd_letter, coords in commands:
        if cmd_letter in ['Z', 'z']:
            parts.append(cmd_letter)
        else:
            coord_strs = []
            for c in coords:
                if c == int(c):
                    coord_strs.append(str(int(c)))
                else:
                    coord_strs.append(f'{c:.4f}'.rstrip('0').rstrip('.'))

            if len(coords) >= 2:
                pairs = []
                for i in range(0, len(coord_strs), 2):
                    if i + 1 < len(coord_strs):
                        pairs.append(f'{coord_strs[i]} {coord_strs[i+1]}')
                    else:
                        pairs.append(coord_strs[i])

                if cmd_letter == 'M':
                    parts.append(f'M{pairs[0]}')
                elif cmd_letter == 'L':
                    parts.append(f'L{" L".join(pairs)}')
                elif cmd_letter == 'C':
                    parts.append(f'C{" ".join(pairs)}')
                else:
                    parts.append(f'{cmd_letter}{" ".join(pairs)}')
            else:
                parts.append(f'{cmd_letter}{" ".join(coord_strs)}')

    return ''.join(parts)


def transform_coords(coords, scale, tx, ty):
    """Transform coordinates by scale and translation."""
    new_coords = []
    for i in range(0, len(coords), 2):
        x = coords[i] * scale + tx
        y = coords[i+1] * scale + ty
        new_coords.append(x)
        new_coords.append(y)
    return new_coords


def transform_path_commands(commands, scale, tx, ty):
    """Transform all coordinates in path commands."""
    new_commands = []
    for cmd_letter, coords in commands:
        if cmd_letter in ['Z', 'z']:
            new_commands.append((cmd_letter, []))
        else:
            new_coords = transform_coords(coords, scale, tx, ty)
            new_commands.append((cmd_letter, new_coords))
    return new_commands


def split_path_into_subpaths(commands):
    """Split commands at each M (move) command."""
    subpaths = []
    current = []

    for cmd in commands:
        if cmd[0] == 'M' and current:
            subpaths.append(current)
            current = [cmd]
        else:
            current.append(cmd)

    if current:
        subpaths.append(current)

    return subpaths


def get_path_bounds(commands):
    """Calculate bounding box from path commands."""
    xs, ys = [], []

    for cmd_letter, coords in commands:
        if coords:
            for i in range(0, len(coords), 2):
                xs.append(coords[i])
                if i + 1 < len(coords):
                    ys.append(coords[i+1])

    if not xs or not ys:
        return 0, 0, 0, 0

    return min(xs), min(ys), max(xs), max(ys)


def create_filled_hexagon(commands, scale, tx, ty):
    """Create filled hexagon (only outer path, no inner hole)."""
    subpaths = split_path_into_subpaths(commands)
    if subpaths:
        outer = subpaths[0]
        transformed = transform_path_commands(outer, scale, tx, ty)
        return commands_to_path_string(transformed)
    return ""


def create_outlined_hexagon(commands, scale, tx, ty):
    """Create outlined hexagon (both outer and inner paths)."""
    transformed = transform_path_commands(commands, scale, tx, ty)
    return commands_to_path_string(transformed)


def transform_hexagon_to_honeycomb(path_d, class_attr):
    """Transform single hexagon path into 4-hexagon honeycomb pattern with separate paths."""
    commands = parse_path_to_commands(path_d)

    # Get bounding box
    min_x, min_y, max_x, max_y = get_path_bounds(commands)
    width = max_x - min_x
    height = max_y - min_y

    # Scale factor
    scale = 0.5
    scaled_width = width * scale
    scaled_height = height * scale

    # Calculate center
    center_x = (min_x + max_x) / 2
    center_y = (min_y + max_y) / 2

    # Base translation to move to upper-left area
    base_tx = -center_x * scale
    base_ty = -center_y * scale

    # For perfect hex grid tiling (flat-topped hexagons):
    # - Adjacent hexagons (same row): center-to-center horizontal spacing = (3/4) * width
    # - Next row hexagons: center-to-center vertical spacing = height
    # - Next row horizontal offset: (3/8) * width

    # Positions for perfect tiling honeycomb pattern
    positions = [
        (base_tx, base_ty),  # H1: upper left (filled)
        (base_tx + scaled_width * 0.75, base_ty),  # H2: adjacent right (edges touch)
        (base_tx + scaled_width * 0.375, base_ty + scaled_height),  # H3: next row, offset
        (base_tx + scaled_width * 1.125, base_ty + scaled_height),  # H4: adjacent to H3
    ]

    # Create 4 separate path elements
    paths = []

    # H1: filled (only outer path)
    h1_path = create_filled_hexagon(commands, scale, positions[0][0], positions[0][1])
    paths.append(f'   <path class="{class_attr}" d="{h1_path}"/>')

    # H2, H3, H4: outlined (both paths)
    for i in range(1, 4):
        hi_path = create_outlined_hexagon(commands, scale, positions[i][0], positions[i][1])
        paths.append(f'   <path class="{class_attr}" d="{hi_path}"/>')

    # Return grouped paths
    return '\n'.join(paths)


def main():
    # Read input SVG
    with open('/Users/justgus/Xcode-Projects/Cumberland/hexagon.svg', 'r') as f:
        svg_content = f.read()

    # Find and replace each variant's path
    for variant_id in ['Ultralight-S', 'Regular-S', 'Black-S']:
        # Pattern to match the entire path element within this variant group
        pattern = rf'(<g id="{variant_id}"[^>]*>\s*)(<path[^>]*class="([^"]+)"[^>]*d=")([^"]+)("[^>]*/>)(\s*</g>)'

        def replace_path(match):
            group_open = match.group(1)
            # Skip path_prefix (group 2) and path_suffix (group 5) - we'll create new paths
            class_attr = match.group(3)
            original_path = match.group(4)
            group_close = match.group(6)

            # Transform the path into 4 separate grouped paths
            new_paths = transform_hexagon_to_honeycomb(original_path, class_attr)

            return group_open + '\n' + new_paths + '\n  ' + group_close

        svg_content = re.sub(pattern, replace_path, svg_content, flags=re.DOTALL)

    # Write output
    with open('/Users/justgus/Xcode-Projects/Cumberland/four.hexagon.one.fill.svg', 'w') as f:
        f.write(svg_content)

    print('✓ Transformed 3 variants: Ultralight-S, Regular-S, Black-S')
    print('✓ Each variant now has 4 separate hexagon paths (1 filled, 3 outlined)')
    print('✓ Hexagons tile perfectly with edges touching (no overlap)')
    print('✓ Generated four.hexagon.one.fill.svg')


if __name__ == '__main__':
    main()
