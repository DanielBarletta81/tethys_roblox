"""Build a local Studio plugin model; keep the Luau modules separate and inspectable."""
import argparse
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "plugins/TethysTerrain"


def item(parent, class_name, name, source=None):
    node = ET.SubElement(parent, "Item", {"class": class_name})
    properties = ET.SubElement(node, "Properties")
    ET.SubElement(properties, "string", {"name": "Name"}).text = name
    if source is not None:
        ET.SubElement(properties, "ProtectedString", {"name": "Source"}).text = source
    return node


def build(output):
    model = ET.Element("roblox", {"version": "4"})
    entry = item(model, "Script", "TethysTerrain", (SOURCE / "init.server.luau").read_text())
    modules = item(entry, "Folder", "Modules")
    for path in sorted((SOURCE / "Modules").glob("*.luau")):
        item(modules, "ModuleScript", path.stem, path.read_text())
    output.parent.mkdir(parents=True, exist_ok=True)
    ET.indent(model)
    ET.ElementTree(model).write(output, encoding="utf-8", xml_declaration=True)
    parsed = ET.parse(output)
    contents = parsed.findall(".//Item[@class='ModuleScript']")
    assert len(contents) == 8, "Expected eight modular plugin components"
    for node in contents:
        name = node.find("Properties/string[@name='Name']").text
        source = node.find("Properties/ProtectedString[@name='Source']").text
        assert source == (SOURCE / "Modules" / f"{name}.luau").read_text()
    assert parsed.find("./Item/Properties/ProtectedString[@name='Source']").text == (SOURCE / "init.server.luau").read_text()
    print(f"Built {output}: one plugin entry point, {len(contents)} separate modules; source round-trip passed.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "output/terrain-plugin/TethysTerrain.rbxmx")
    build(parser.parse_args().output)
