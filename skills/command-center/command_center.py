#!/usr/bin/env python3
"""Render a table of Claude Code sessions: title, activity, branch/worktree.

Data sources (read-only):
  - ~/.claude/projects/<slug>/*.jsonl   session transcripts
  - `ps` live `claude` processes + their cwd

Active detection is a heuristic, not a fd-map: Claude Code appends to the
transcript then closes it, and exposes no session id in process env/argv. So we
count live `claude` processes per project and mark that many most-recently-
modified sessions ACTIVE. The single currently-running session is always the
most recent in its project, so it is always flagged.
"""
import glob
import json
import os
import re
import subprocess
import sys
from datetime import datetime

PROJECTS = os.path.expanduser("~/.claude/projects")


def live_claude_cwds():
    """Return list of cwds, one per live `claude` process (best effort)."""
    try:
        out = subprocess.check_output(
            ["ps", "-Ao", "pid,command"], text=True, stderr=subprocess.DEVNULL
        )
    except Exception:
        return []
    pids = []
    for line in out.splitlines()[1:]:
        parts = line.strip().split(None, 1)
        if len(parts) != 2:
            continue
        pid, cmd = parts
        # match the bare `claude` CLI, not chrome/helpers/this grep
        if re.search(r"(^|/)claude$", cmd.strip()):
            pids.append(pid)
    cwds = []
    for pid in pids:
        try:
            fn = subprocess.check_output(
                ["lsof", "-a", "-p", pid, "-d", "cwd", "-Fn"],
                text=True, stderr=subprocess.DEVNULL,
            )
            for l in fn.splitlines():
                if l.startswith("n"):
                    cwds.append(l[1:])
                    break
        except Exception:
            pass
    return cwds


def slug(path):
    return path.replace("/", "-")


CAVEAT_RE = re.compile(r"Caveat:.*?unless explicitly asked to\.?", re.S)


def title_of(user_texts):
    """Best title from the first few user messages.

    Prefers an explicit slash command; else the first real prose, skipping the
    local-command caveat boilerplate that opens `/slash`-launched sessions.
    """
    for t in user_texts:
        m = re.search(r"<command-name>\s*/?([^<]+?)\s*</command-name>", t)
        if m:
            return "/" + m.group(1).strip()
    for t in user_texts:
        s = CAVEAT_RE.sub("", t)
        s = re.sub(r"<[^>]+>", " ", s)
        s = " ".join(s.split())
        if s:
            return s[:70]
    return "(empty)"


def parse_session(path):
    user_texts = []        # text of first few user messages
    branches = []          # distinct, in first-seen order
    worktree = None
    cwd_last = None
    for line in open(path, encoding="utf-8", errors="replace"):
        try:
            d = json.loads(line)
        except Exception:
            continue
        if d.get("gitBranch") and d["gitBranch"] not in branches:
            branches.append(d["gitBranch"])
        c = d.get("cwd")
        if c:
            cwd_last = c
            if "/.claude/worktrees/" in c and worktree is None:
                worktree = c.split("/.claude/worktrees/", 1)[1].split("/", 1)[0]
        if len(user_texts) < 4 and d.get("type") == "user":
            content = d.get("message", {}).get("content", "")
            if isinstance(content, list):
                content = " ".join(
                    p.get("text", "") for p in content if isinstance(p, dict)
                )
            if isinstance(content, str) and content.strip():
                user_texts.append(content)
    return {
        "id": os.path.basename(path)[:-6],
        "mtime": os.path.getmtime(path),
        "title": title_of(user_texts),
        "branches": branches or ["(unknown)"],
        "worktree": worktree,
        "cwd": cwd_last,
    }


def main():
    scope = "all"
    for a in sys.argv[1:]:
        if a in ("current", "all"):
            scope = a

    cwd = os.getcwd()
    cur_slug = slug(cwd)

    proj_dirs = sorted(glob.glob(os.path.join(PROJECTS, "*")))
    if scope == "current":
        proj_dirs = [d for d in proj_dirs if os.path.basename(d) == cur_slug]

    # live-process count per project slug
    live = {}
    for c in live_claude_cwds():
        live[slug(c)] = live.get(slug(c), 0) + 1

    rows = []
    for pd in proj_dirs:
        pslug = os.path.basename(pd)
        sessions = [
            parse_session(f)
            for f in glob.glob(os.path.join(pd, "*.jsonl"))
        ]
        sessions.sort(key=lambda s: s["mtime"], reverse=True)
        n_active = live.get(pslug, 0)
        for i, s in enumerate(sessions):
            s["project"] = pslug.replace("-Users-robertlopez-repos-", "")
            s["active"] = i < n_active
            rows.append(s)

    if not rows:
        print("No Claude Code sessions found under", PROJECTS)
        return

    rows.sort(key=lambda s: s["mtime"], reverse=True)
    print("| Modified | ID | Active | Branch | Worktree | Title |")
    print("|---|---|---|---|---|---|")
    for s in rows:
        when = datetime.fromtimestamp(s["mtime"]).strftime("%m-%d %H:%M")
        act = "✅ live" if s["active"] else "⛔ idle"
        branch = " → ".join(s["branches"])
        wt = s["worktree"] or "—"
        title = s["title"].replace("|", "\\|")
        print(f"| {when} | `{s['id'][:8]}` | {act} | {branch} | {wt} | {title} |")

    n_live = sum(live.values())
    print()
    print(
        f"_{len(rows)} sessions · {n_live} live `claude` process(es). "
        "Active = most-recent N sessions per project with a live process "
        "(heuristic; branch/worktree are last-logged, not live git)._"
    )


if __name__ == "__main__":
    main()
