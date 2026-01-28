#!/usr/bin/env python3
"""
Event Storm DSL Parser & Multi-format Generator

Parses .es.yaml files and generates:
- Mermaid flowchart (per scenario)
- Mermaid stateDiagram-v2
- CML (Context Mapper Language)
- MDSL Flow
- JSON (legacy format compatibility)

Usage:
    python3 parse_dsl.py input.es.yaml
    python3 parse_dsl.py input.es.yaml -f mermaid --png
    python3 parse_dsl.py input.es.yaml -f all -o ./output
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

try:
    import yaml
except ImportError:
    print("Error: PyYAML required. Install: pip install pyyaml", file=sys.stderr)
    sys.exit(1)


# ── Constants ──────────────────────────────────────────────

COMPONENT_STYLES = {
    "actor": {
        "fmt": '{{{{"{name}"}}}}',
        "cls": "actor",
        "fill": "#fef9c3",
        "stroke": "#ca8a04",
    },
    "command": {
        "fmt": '["{name}"]',
        "cls": "command",
        "fill": "#93c5fd",
        "stroke": "#2563eb",
    },
    "system": {
        "fmt": '(["{name}"])',
        "cls": "system",
        "fill": "#fbcfe8",
        "stroke": "#db2777",
    },
    "domain_event": {
        "fmt": '(("{name}"))',
        "cls": "event",
        "fill": "#fed7aa",
        "stroke": "#ea580c",
    },
    "policy": {
        "fmt": '{{"{name}"}}',
        "cls": "policy",
        "fill": "#d8b4fe",
        "stroke": "#9333ea",
    },
    "query_model": {
        "fmt": '[/"{name}"/]',
        "cls": "query",
        "fill": "#bbf7d0",
        "stroke": "#16a34a",
    },
    "constraint": {
        "fmt": '[["{name}"]]',
        "cls": "constraint",
        "fill": "#fef08a",
        "stroke": "#ca8a04",
    },
    "hotspot": {
        "fmt": '(((("{name}"))))',
        "cls": "hotspot",
        "fill": "#fecaca",
        "stroke": "#dc2626",
    },
}

DEFAULT_LABELS = {
    ("actor", "command"): "Decides to",
    ("actor", "query_model"): "Looks up",
    ("command", "system"): "Invoked On",
    ("system", "domain_event"): "Produces",
    ("command", "domain_event"): "Produces",
    ("domain_event", "policy"): "Activates",
    ("policy", "command"): "Issues",
    ("domain_event", "query_model"): "Results in",
    ("query_model", "actor"): "observes",
    ("constraint", "command"): "guards",
    ("system", "command"): "Executes",
    ("domain_event", "command"): "Triggers",
}


# ── Parsing & Validation ──────────────────────────────────


def parse_dsl(path: str) -> dict:
    """Parse .es.yaml file from path"""
    p = Path(path)
    if not p.exists():
        raise FileNotFoundError(f"File not found: {path}")
    with open(p, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    _validate(data)
    return data


def parse_dsl_string(content: str) -> dict:
    """Parse YAML DSL from string"""
    data = yaml.safe_load(content)
    _validate(data)
    return data


def _validate(data: Any):
    if not isinstance(data, dict):
        raise ValueError("Root must be a YAML mapping")
    for field in ("event-storm", "scenarios"):
        if field not in data:
            raise ValueError(f"Missing required field: '{field}'")
    scenarios = data["scenarios"]
    if not isinstance(scenarios, list) or len(scenarios) == 0:
        raise ValueError("'scenarios' must be a non-empty list")
    for i, s in enumerate(scenarios):
        if "name" not in s:
            raise ValueError(f"Scenario {i}: missing 'name'")
        if "flows" not in s or not isinstance(s.get("flows"), list):
            raise ValueError(f"Scenario '{s.get('name', i)}': missing or empty 'flows'")


# ── Component Registry ────────────────────────────────────


class _Registry:
    """Manages unique component creation and ID generation"""

    PREFIXES = {
        "actor": "a",
        "command": "c",
        "system": "s",
        "domain_event": "e",
        "policy": "p",
        "query_model": "q",
        "constraint": "cn",
        "hotspot": "h",
    }

    def __init__(self):
        self._store: dict[str, dict] = {}
        self._counts: dict[str, int] = {}

    def get_or_create(self, comp_type: str, name: str) -> str:
        """Get existing or create new component, return ID"""
        key = f"{comp_type}:{name}"
        if key not in self._store:
            pfx = self.PREFIXES.get(comp_type, "x")
            self._counts[pfx] = self._counts.get(pfx, 0) + 1
            self._store[key] = {
                "type": comp_type,
                "name": name,
                "id": f"{pfx}{self._counts[pfx]}",
            }
        return self._store[key]["id"]

    def find_by_name(self, name: str) -> str | None:
        """Find component ID by name (searches all types)"""
        for v in self._store.values():
            if v["name"] == name:
                return v["id"]
        return None

    def type_of(self, comp_id: str) -> str:
        """Get component type by ID"""
        for v in self._store.values():
            if v["id"] == comp_id:
                return v["type"]
        return "command"

    def to_list(self) -> list[dict]:
        return list(self._store.values())


# ── Component/Connection Extraction ───────────────────────


def extract_scenario(scenario: dict) -> tuple[list[dict], list[dict]]:
    """Extract (components, connections) from a scenario's flows"""
    reg = _Registry()
    conns: list[dict] = []
    prev = None
    for step in scenario.get("flows", []):
        prev = _process_step(step, reg, conns, prev)
    return reg.to_list(), conns


def _as_list(val: str | list[str]) -> list[str]:
    return val if isinstance(val, list) else [val]


def _build_chain(step: dict) -> list[tuple[str, str]]:
    """Build ordered (type, name) chain for a flow step.

    Chain order: Trigger → Policy → Action → System → Events
    """
    chain: list[tuple[str, str]] = []

    # 1. Trigger
    if "actor" in step:
        chain.append(("actor", step["actor"]))
    elif "event" in step:
        chain.append(("domain_event", step["event"]))
    elif "external" in step:
        chain.append(("system", step["external"]))

    # 2. Policy
    if "policy" in step:
        chain.append(("policy", step["policy"]))

    # 3. Action
    if "command" in step:
        chain.append(("command", step["command"]))
    elif "query" in step:
        chain.append(("query_model", step["query"]))

    # 4. System (only when not external — external IS the system)
    if "system" in step and "external" not in step:
        chain.append(("system", step["system"]))

    # 5. Emitted events
    if "emits" in step:
        for e in _as_list(step["emits"]):
            chain.append(("domain_event", e))

    return chain


def _process_step(
    step: dict,
    reg: _Registry,
    conns: list[dict],
    prev_id: str | None,
) -> str | None:
    """Process a single flow step. Returns last node ID for chaining."""
    chain = _build_chain(step)

    if not chain:
        # parallel/branch-only step
        for sub in step.get("parallel", []) + step.get("branch", []):
            _process_step(sub, reg, conns, prev_id)
        return prev_id

    # Create component nodes
    nodes = [(reg.get_or_create(ct, cn), ct) for ct, cn in chain]
    first_id, first_type = nodes[0]

    # ── Connect to chain start ──
    has_trigger = any(k in step for k in ("actor", "event", "external"))

    # after: always respected (explicit dependency overrides implicit sequencing)
    if "after" in step:
        for a in _as_list(step["after"]):
            aid = reg.find_by_name(a)
            if aid:
                at = reg.type_of(aid)
                conns.append({
                    "from": aid,
                    "to": first_id,
                    "label": DEFAULT_LABELS.get((at, first_type), ""),
                })
    elif not has_trigger and prev_id:
        # Implicit sequencing: only when no trigger and no after
        pt = reg.type_of(prev_id)
        conns.append({
            "from": prev_id,
            "to": first_id,
            "label": DEFAULT_LABELS.get((pt, first_type), ""),
        })

    # ── Connect chain internally ──
    # Pivot: last non-event index (events fan-out from pivot)
    pivot = -1
    for i, (_, t) in enumerate(nodes):
        if t != "domain_event":
            pivot = i

    if pivot == -1:
        # All events — connect sequentially
        for i in range(len(nodes) - 1):
            cid, ct = nodes[i]
            nid, nt = nodes[i + 1]
            conns.append({
                "from": cid, "to": nid,
                "label": DEFAULT_LABELS.get((ct, nt), ""),
            })
    else:
        # Sequential connections up to pivot
        for i in range(pivot):
            cid, ct = nodes[i]
            nid, nt = nodes[i + 1]
            conns.append({
                "from": cid, "to": nid,
                "label": DEFAULT_LABELS.get((ct, nt), ""),
            })
        # Fan-out from pivot to all trailing events
        if pivot < len(nodes) - 1:
            sid, st = nodes[pivot]
            for i in range(pivot + 1, len(nodes)):
                eid, et = nodes[i]
                conns.append({
                    "from": sid, "to": eid,
                    "label": DEFAULT_LABELS.get((st, et), ""),
                })

    last_id = nodes[-1][0]

    # ── Nested structures ──
    for sub in step.get("parallel", []):
        _process_step(sub, reg, conns, last_id)

    for sub in step.get("branch", []):
        _process_step(sub, reg, conns, last_id)

    if "hotspot" in step:
        hid = reg.get_or_create("hotspot", step["hotspot"])
        conns.append({"from": hid, "to": last_id, "label": "?"})

    return last_id


# ── Mermaid Flowchart ─────────────────────────────────────


def generate_flowchart(scenario: dict) -> str:
    """Generate Mermaid flowchart for a single scenario"""
    components, connections = extract_scenario(scenario)

    lines = ["flowchart LR"]

    # Styles
    for s in COMPONENT_STYLES.values():
        lines.append(f"    classDef {s['cls']} fill:{s['fill']},stroke:{s['stroke']}")
    lines.append("")

    # Nodes
    for c in components:
        name = c["name"].replace('"', "#quot;")
        style = COMPONENT_STYLES.get(c["type"], COMPONENT_STYLES["command"])
        node = style["fmt"].format(name=name)
        lines.append(f"    {c['id']}{node}:::{style['cls']}")
    lines.append("")

    # Edges (deduplicated)
    seen: set[tuple] = set()
    for conn in connections:
        key = (conn["from"], conn["to"], conn.get("label", ""))
        if key in seen:
            continue
        seen.add(key)
        lbl = conn.get("label", "")
        if lbl:
            lines.append(f"    {conn['from']} -->|{lbl}| {conn['to']}")
        else:
            lines.append(f"    {conn['from']} --> {conn['to']}")

    return "\n".join(lines)


# ── Mermaid State Diagram ─────────────────────────────────


def generate_statediagram(states: list[dict]) -> list[dict]:
    """Generate Mermaid stateDiagram-v2 from states section.

    Returns list of {entity: str, mermaid: str}.
    """
    results = []
    for se in states:
        lines = ["stateDiagram-v2", "    direction TB"]
        for t in se.get("transitions", []):
            label = t["trigger"]
            if t.get("note"):
                label += f"\\n{t['note']}"
            lines.append(f"    {t['from']} --> {t['to']} : {label}")
        results.append({"entity": se["entity"], "mermaid": "\n".join(lines)})
    return results


# ── CML Generation ────────────────────────────────────────


def _to_id(name: str) -> str:
    """Convert name to CamelCase identifier (preserves existing casing)"""
    parts = re.split(r"[\s_\-]+", name)
    return "".join((p[0].upper() + p[1:]) if p else "" for p in parts)


def generate_cml(data: dict) -> str:
    """Generate Context Mapper CML output"""
    title = data["event-storm"]
    lines = [f"/* Generated from: {title} */", ""]

    # Collect per-system data
    system_data: dict[str, dict[str, set]] = {}
    for scenario in data["scenarios"]:
        for step in scenario.get("flows", []):
            _collect_cml_step(step, system_data)

    for sys_name in sorted(system_data):
        ctx = _to_id(sys_name) + "Context"
        agg = _to_id(sys_name)
        info = system_data[sys_name]

        lines.append(f"BoundedContext {ctx} {{")
        lines.append(f"  Aggregate {agg} {{")
        for evt in sorted(info.get("events", set())):
            lines.append(f"    DomainEvent {_to_id(evt)}")
        for cmd in sorted(info.get("commands", set())):
            lines.append(f"    CommandEvent {_to_id(cmd)}")
        lines.append("  }")
        lines.append("}")
        lines.append("")

    return "\n".join(lines)


def _collect_cml_step(step: dict, system_data: dict):
    """Recursively collect system-grouped events/commands for CML"""
    sys_name = step.get("system") or step.get("external")
    if sys_name:
        sd = system_data.setdefault(sys_name, {"events": set(), "commands": set()})
        if "command" in step:
            sd["commands"].add(step["command"])
        if "emits" in step:
            for e in _as_list(step["emits"]):
                sd["events"].add(e)
    for sub in step.get("parallel", []) + step.get("branch", []):
        _collect_cml_step(sub, system_data)


# ── MDSL Flow Generation ─────────────────────────────────


def generate_mdsl(data: dict) -> str:
    """Generate MDSL Flow output"""
    title = data["event-storm"]
    lines = [f"// Generated from: {title}", ""]

    for scenario in data["scenarios"]:
        flow_name = _to_id(scenario["name"])
        lines.append(f"flow {flow_name}")
        prev_events: list[str] = []
        for step in scenario.get("flows", []):
            _mdsl_step(step, lines, prev_events)
        lines.append("")

    return "\n".join(lines)


def _mdsl_step(step: dict, lines: list[str], prev_events: list[str]):
    """Process a single step for MDSL output"""
    # Determine trigger
    trigger = ""
    if "event" in step:
        trigger = f"event {_to_id(step['event'])} triggers "
    elif prev_events:
        trigger = f"event {_to_id(prev_events[-1])} triggers "

    # Determine action
    action = ""
    if "command" in step:
        action = f"command {_to_id(step['command'])}"
    elif "query" in step:
        action = f"command {_to_id(step['query'])}"

    # Determine emit
    emit = ""
    if "emits" in step:
        evts = _as_list(step["emits"])
        emit = " emits event " + " + ".join(_to_id(e) for e in evts)
        prev_events.clear()
        prev_events.extend(evts)
    elif action:
        prev_events.clear()

    if action:
        lines.append(f"  {trigger}{action}{emit}")

    # Parallel (AND)
    if "parallel" in step:
        par_cmds = [_to_id(s["command"]) for s in step["parallel"] if "command" in s]
        if par_cmds:
            lines.append(f"  command {' + '.join(par_cmds)}")
        for sub in step["parallel"]:
            if "emits" in sub:
                for e in _as_list(sub["emits"]):
                    prev_events.append(e)

    # Branch (XOR)
    if "branch" in step:
        br_cmds = [_to_id(s["command"]) for s in step["branch"] if "command" in s]
        if br_cmds:
            lines.append(f"  command {' x '.join(br_cmds)}")


# ── JSON Legacy Format ────────────────────────────────────


def to_legacy_json(scenario: dict, storm_type: str | None = None) -> dict:
    """Convert scenario to legacy JSON format (generate_mermaid.py compatible)"""
    components, connections = extract_scenario(scenario)
    result: dict[str, Any] = {
        "title": scenario["name"],
        "components": components,
    }
    if storm_type:
        result["type"] = storm_type
    result["connections"] = [{k: v for k, v in c.items() if v} for c in connections]
    return result


# ── File Output ────────────────────────────────────────────


def _safe_filename(title: str) -> str:
    s = title.replace(" ", "_")
    return re.sub(r'[<>:"/\\|?*]', "", s)


def _to_png(mmd: Path, png: Path) -> bool:
    try:
        r = subprocess.run(
            ["npx", "-p", "@mermaid-js/mermaid-cli", "mmdc",
             "-i", str(mmd), "-o", str(png)],
            capture_output=True, text=True, timeout=60,
        )
        return r.returncode == 0
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def write_outputs(
    data: dict,
    output_dir: Path,
    fmt: str = "all",
    png: bool = False,
) -> list[str]:
    """Write all requested output formats. Returns list of generated file paths."""
    output_dir.mkdir(parents=True, exist_ok=True)
    title = data["event-storm"]
    base = _safe_filename(title)
    generated: list[str] = []

    # ── Mermaid ──
    if fmt in ("all", "mermaid"):
        md_parts = [f"# {title}\n"]

        for sc in data["scenarios"]:
            md_parts.append(f"## {sc['name']}\n")
            if sc.get("description"):
                md_parts.append(f"> {sc['description']}\n")
            md_parts.append(f"```mermaid\n{generate_flowchart(sc)}\n```\n")

        if data.get("states"):
            md_parts.append("## State Transitions\n")
            for sd in generate_statediagram(data["states"]):
                md_parts.append(f"### {sd['entity']}\n")
                md_parts.append(f"```mermaid\n{sd['mermaid']}\n```\n")

        md_path = output_dir / f"{base}.md"
        md_path.write_text("\n".join(md_parts), encoding="utf-8")
        generated.append(str(md_path))

        if png:
            for sc in data["scenarios"]:
                sname = _safe_filename(sc["name"])
                mmd_path = output_dir / f"{base}_{sname}.mmd"
                png_path = output_dir / f"{base}_{sname}.png"
                mmd_path.write_text(generate_flowchart(sc), encoding="utf-8")
                if _to_png(mmd_path, png_path):
                    generated.append(str(png_path))
                    mmd_path.unlink()
                else:
                    generated.append(f"{mmd_path} (PNG failed)")

    # ── CML ──
    if fmt in ("all", "cml"):
        p = output_dir / f"{base}.cml"
        p.write_text(generate_cml(data), encoding="utf-8")
        generated.append(str(p))

    # ── MDSL ──
    if fmt in ("all", "mdsl"):
        p = output_dir / f"{base}.mdsl"
        p.write_text(generate_mdsl(data), encoding="utf-8")
        generated.append(str(p))

    # ── JSON (legacy) ──
    if fmt in ("all", "json"):
        st = data.get("type")
        for sc in data["scenarios"]:
            sname = _safe_filename(sc["name"])
            p = output_dir / f"{base}_{sname}.json"
            content = json.dumps(to_legacy_json(sc, st), ensure_ascii=False, indent=2)
            p.write_text(content, encoding="utf-8")
            generated.append(str(p))

    return generated


# ── CLI ────────────────────────────────────────────────────


def main():
    ap = argparse.ArgumentParser(
        description="Event Storm DSL Parser & Multi-format Generator",
        epilog=(
            "Examples:\n"
            "  python3 parse_dsl.py input.es.yaml\n"
            "  python3 parse_dsl.py input.es.yaml -f mermaid --png\n"
            "  python3 parse_dsl.py input.es.yaml -f all -o ./output\n"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("input", help=".es.yaml file path")
    ap.add_argument(
        "-f", "--format",
        choices=["all", "mermaid", "cml", "mdsl", "json"],
        default="all",
    )
    ap.add_argument("-o", "--output-dir", default=".", help="Output directory")
    ap.add_argument("--png", action="store_true", help="Generate PNG (needs mermaid-cli)")
    ap.add_argument("--validate-only", action="store_true", help="Validate only")

    args = ap.parse_args()

    try:
        data = parse_dsl(args.input)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

    if args.validate_only:
        n = len(data["scenarios"])
        print(f"Valid: {data['event-storm']} ({n} scenario{'s' if n != 1 else ''})")
        sys.exit(0)

    for p in write_outputs(data, Path(args.output_dir), args.format, args.png):
        print(f"Generated: {p}")


if __name__ == "__main__":
    main()
