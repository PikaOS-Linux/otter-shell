#!/usr/bin/env node
const fs = require("fs");
const path = require("path");
const { execFileSync } = require("child_process");

const root = path.resolve(__dirname, "..");
const reports = path.join(root, "reports");

const captures = [
  { app: "bar", summary: "ui-parity/20260604-bar-layout-fix/bar/summary.json", shot: "ui-parity/20260604-bar-layout-fix/bar/side-by-side.png" },
  { app: "launcher", summary: "ui-parity/20260604-ui-port/launcher/summary.json", shot: "ui-parity/20260604-ui-port/launcher/side-by-side.png" },
  { app: "settings", summary: "ui-parity/20260604-shared-hit-settings/settings/summary.json", shot: "ui-parity/20260604-shared-hit-settings/settings/side-by-side.png" },
  { app: "osd", summary: "ui-parity/20260604-osd/osd/summary.json", shot: "ui-parity/20260604-osd/osd/side-by-side.png" },
  { app: "wallpaper", summary: "ui-parity/20260604-wallpaper-releasesmall-local/wallpaper/summary.json", shot: "ui-parity/20260604-wallpaper-releasesmall-local/wallpaper/side-by-side.png" },
  { app: "lock", summary: "ui-parity/20260604-lock-fixed-state/lock/summary.json", shot: "ui-parity/20260604-lock-fixed-state/lock/side-by-side.png" },
  { app: "greeter-ui", summary: "ui-parity/20260604-greeter-ui/greeter-ui/summary.json", shot: "ui-parity/20260604-greeter-ui/greeter-ui/side-by-side.png" },
  { app: "term", summary: "ui-parity/20260604-memory-rerun/term/summary.json", shot: "ui-parity/20260604-memory-rerun/term/side-by-side.png" },
  { app: "logout", summary: "ui-parity/20260604-ui-port/logout/summary.json", shot: "ui-parity/20260604-ui-port/logout/side-by-side.png" },
  { app: "shot", summary: "ui-parity/20260604-ui-port/shot/summary.json", shot: "ui-parity/20260604-ui-port/shot/side-by-side.png" },
  { app: "jade", summary: "ui-parity/20260604-ui-port/jade/summary.json", shot: "ui-parity/20260604-ui-port/jade/side-by-side.png" },
  { app: "notifications-private-bus", summary: "ui-parity/20260604-ui-port/notifications-private-bus/summary.json", shot: "ui-parity/20260604-ui-port/notifications-private-bus/side-by-side.png" },
  { app: "polkit", qaPrefix: "otter-polkit", shot: "otter-port-qa/screens/otter-polkit-side-by-side.png" },
];

const skipped = [
  ["otter-greeterd", "Daemon/seat/session launcher not visually captured; greeter UI surface is captured with a fake daemon socket. Render audit passed."],
  ["otter-idle", "No user-visible renderer surface to capture. Render audit passed."],
  ["otter-dock", "No comparable installed baseline is available for this historical side-by-side report; current dock has deterministic Surface Description visual fixtures and isolated headless autohide/hover captures."],
];

const benchmarkLogs = [
  { label: "otter-conf-bench.log", rel: "benchmarks/20260604-current/otter-conf-bench.log" },
  { label: "otter-render-fill-rect.log", rel: "benchmarks/20260604-current/otter-render-fill-rect.log" },
  { label: "otter-render-composite.log", rel: "benchmarks/20260604-current/otter-render-composite.log" },
  { label: "otter-render-text-small.log", rel: "benchmarks/20260604-current/otter-render-text-small.log" },
  { label: "otter-render-text-rtl.log", rel: "benchmarks/20260604-current/otter-render-text-rtl.log" },
  { label: "otter-render-text-cjk.log", rel: "benchmarks/20260604-current/otter-render-text-cjk.log" },
  { label: "otter-render-scene.log", rel: "benchmarks/20260604-current/otter-render-scene.log" },
  { label: "otter-render-damage-cull.log", rel: "benchmarks/20260604-current/otter-render-damage-cull.log" },
  { label: "otter-render-quad-renderer.log", rel: "benchmarks/20260604-current/otter-render-quad-renderer.log" },
  { label: "otter-render-animation-single.log", rel: "benchmarks/20260604-current/otter-render-animation-single.log" },
  { label: "otter-render-animation-batch.log", rel: "benchmarks/20260604-current/otter-render-animation-batch.log" },
  { label: "otter-desktop-bench.log", rel: "benchmarks/20260604-current/otter-desktop-bench.log" },
  { label: "otter-theme-gen-bench.log", rel: "benchmarks/20260604-current/otter-theme-gen-bench.log" },
];

function readJson(rel) {
  return JSON.parse(fs.readFileSync(path.join(reports, rel), "utf8"));
}

function readText(rel) {
  return fs.readFileSync(path.join(reports, rel), "utf8");
}

function exists(rel) {
  return fs.existsSync(path.join(reports, rel));
}

function html(s) {
  return String(s)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function commit(repo) {
  try {
    return execFileSync("git", ["log", "-1", "--oneline", "--decorate"], {
      cwd: path.join(root, repo),
      encoding: "utf8",
    }).trim();
  } catch {
    return "unavailable";
  }
}

function diffMetric(summaryRel) {
  const diffRel = summaryRel.replace(/summary\.json$/, "diff.txt");
  return exists(diffRel) ? readText(diffRel).trim() : "";
}

function kb(v) {
  return v == null ? "n/a" : `${v} KB`;
}

function parseQaMemory(prefix) {
  const rows = readText(`otter-port-qa/${prefix}-memory.csv`).trim().split("\n").slice(1);
  const out = {};
  for (const row of rows) {
    const cells = row.match(/(?:^|,)(?:"([^"]*)"|([^,]*))/g).map((cell) =>
      cell.replace(/^,/, "").replace(/^"|"$/g, "")
    );
    out[cells[0]] = {
      label: cells[0],
      pid: Number(cells[1]),
      rss_kb: Number(cells[2]),
      pss_kb: Number(cells[3]),
      command: cells[4],
    };
  }
  return out;
}

function qaSummary(prefix, app) {
  const memory = parseQaMemory(prefix);
  return {
    app,
    baseline: {
      app,
      label: "baseline",
      command: memory.old.command,
      png: path.join(reports, `otter-port-qa/screens/${prefix}-old.png`),
      geometry: "nested Sway",
      sha256: "",
      memory: { pid: memory.old.pid, rss_kb: memory.old.rss_kb, pss_kb: memory.old.pss_kb },
    },
    current: {
      app,
      label: "current",
      command: memory.new.command,
      png: path.join(reports, `otter-port-qa/screens/${prefix}-new.png`),
      geometry: "nested Sway",
      sha256: "",
      memory: { pid: memory.new.pid, rss_kb: memory.new.rss_kb, pss_kb: memory.new.pss_kb },
    },
    rss_delta_kb: memory.new.rss_kb - memory.old.rss_kb,
    pss_delta_kb: memory.new.pss_kb - memory.old.pss_kb,
  };
}

const audit = readJson("render-path-audit.json");
const captureRows = captures.map((item) => {
  if (item.qaPrefix) {
    return {
      ...item,
      summary: qaSummary(item.qaPrefix, item.app),
      diff: exists(`otter-port-qa/${item.qaPrefix}-diff.txt`) ? readText(`otter-port-qa/${item.qaPrefix}-diff.txt`).trim() : "",
    };
  }
  const summary = readJson(item.summary);
  return { ...item, summary, diff: diffMetric(item.summary) };
});

const generated = new Date().toISOString();
const allAuditClean = audit.every((a) =>
  a.manual_render_match_count === 0 &&
  a.old_render_path_match_count === 0 &&
  (a.ported_surface_match_count ?? 0) === 0
);

let body = "";
body += `<!doctype html><html><head><meta charset="utf-8"><title>Otter UI Port Evidence Report</title>`;
body += `<style>:root{color-scheme:dark;--bg:#0d1017;--panel:#151923;--line:#2a3142;--text:#d8deea;--muted:#9aa4b5;--ok:#7bd88f;--warn:#f4c36d;--bad:#f7768e;--accent:#7aa2f7}body{margin:0;background:var(--bg);color:var(--text);font:14px/1.45 Inter,system-ui,sans-serif}main{max-width:1180px;margin:0 auto;padding:28px}h1{font-size:28px;margin:0 0 4px}h2{font-size:18px;margin:28px 0 10px;color:#fff}h3{font-size:15px;margin:16px 0 8px}p{color:var(--muted)}table{border-collapse:collapse;width:100%;background:var(--panel);border:1px solid var(--line);border-radius:8px;overflow:hidden}th,td{padding:8px 10px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}th{color:#fff;background:#1b2130}tr:last-child td{border-bottom:0}.ok{color:var(--ok)}.warn{color:var(--warn)}.bad{color:var(--bad)}code,pre{font-family:JetBrains Mono,monospace}pre{white-space:pre-wrap;background:#0a0d13;border:1px solid var(--line);border-radius:8px;padding:12px;max-height:320px;overflow:auto}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:12px}.card{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:12px}.shot{margin:16px 0 24px}.shot img{width:100%;border:1px solid var(--line);border-radius:8px;background:#000}.meta{color:var(--muted);font-size:12px}.pill{display:inline-block;border:1px solid var(--line);border-radius:999px;padding:2px 8px;margin:2px;color:var(--muted)}a{color:var(--accent)}</style>`;
body += `</head><body><main>`;
body += `<h1>Otter UI Port Evidence Report</h1><p>Generated ${html(generated)}. Current physical captures, memory samples, render-path audit, and benchmark logs are linked below. Non-visual or explicitly skipped apps are listed separately.</p>`;
body += `<div class="grid">`;
body += `<div class="card"><b class="${allAuditClean ? "ok" : "bad"}">Render Path Audit</b><p>${allAuditClean ? "All audited apps report zero manual/old render matches." : "Audit has non-zero findings."}</p></div>`;
body += `<div class="card"><b class="ok">Latest Memory Evidence</b><p>Latest comparable captures include RSS/PSS from <code>smaps_rollup</code>; polkit is captured through a real auth challenge in nested Sway.</p></div>`;
body += `<div class="card"><b class="warn">Physical Coverage</b><p>Session-owned services are listed separately until they have safe isolated capture evidence.</p></div>`;
body += `</div>`;

body += `<h2>Current Commits</h2><table><tr><th>Repo</th><th>Commit</th></tr>`;
for (const repo of ["otter-ui", "otter-settings", "otter-bar", "otter-launcher", "otter-render", "otter-desktop", "otter-theme-gen", "otter-wallpaper"]) {
  body += `<tr><td>${html(repo)}</td><td><code>${html(commit(repo))}</code></td></tr>`;
}
body += `</table>`;

body += `<h2>What Changed Since Gooey Plan Work</h2><ul>`;
for (const item of [
  "Apps route paint through otter-ui frame/rasterize paths; app-level old command-list/rasterizer paths audit clean.",
  "Bar widget, popup, lifecycle, dynamic custom-button, damage, draw, and cursor routing moved behind otter-ui registries.",
  "Settings low-level rectangle/index hit testing moved into otter-ui shared helpers.",
  "Text shaping remains lazy and gated; ASCII/private-use icon paths stay fast while RTL/CJK can use shaping.",
  "Font resolver uses bundled/common family resolution before fontconfig where possible.",
]) {
  body += `<li>${html(item)}</li>`;
}
body += `</ul>`;

body += `<h2>Render Path Audit</h2><table><tr><th>App</th><th>Manual render matches</th><th>Old path matches</th><th>Ported surface matches</th></tr>`;
for (const a of audit) {
  const surfaceCount = a.ported_surface_match_count ?? 0;
  const clean = a.manual_render_match_count === 0 && a.old_render_path_match_count === 0 && surfaceCount === 0;
  body += `<tr><td>${html(a.app)}</td><td class="${clean ? "ok" : "bad"}">${a.manual_render_match_count}</td><td class="${clean ? "ok" : "bad"}">${a.old_render_path_match_count}</td><td class="${clean ? "ok" : "bad"}">${surfaceCount}</td></tr>`;
}
body += `</table>`;

body += `<h2>App Runtime Evidence</h2><table><tr><th>App</th><th>Baseline RSS</th><th>Current RSS</th><th>Delta RSS</th><th>Baseline PSS</th><th>Current PSS</th><th>Delta PSS</th><th>Diff metric</th></tr>`;
for (const row of captureRows) {
  const s = row.summary;
  body += `<tr><td>${html(row.app)}</td><td>${kb(s.baseline.memory.rss_kb)}</td><td>${kb(s.current.memory.rss_kb)}</td><td>${kb(s.rss_delta_kb)}</td><td>${kb(s.baseline.memory.pss_kb)}</td><td>${kb(s.current.memory.pss_kb)}</td><td>${kb(s.pss_delta_kb)}</td><td><code>${html(row.diff)}</code></td></tr>`;
}
body += `</table>`;

body += `<h2>Physical Side-by-Side Evidence</h2>`;
for (const row of captureRows) {
  const s = row.summary;
  body += `<section class="shot"><h3>${html(row.app)}</h3><p class="meta">Baseline: <code>${html(s.baseline.command)}</code><br>Current: <code>${html(s.current.command)}</code><br>Geometry: <code>${html(s.baseline.geometry || "")}</code> / <code>${html(s.current.geometry || "")}</code></p><img src="${html(row.shot)}" alt="${html(row.app)} side-by-side"></section>`;
}

body += `<h2>Skipped Or Blocked Physical Captures</h2><table><tr><th>App</th><th>Reason</th></tr>`;
for (const [app, reason] of skipped) {
  body += `<tr><td>${html(app)}</td><td>${html(reason)}</td></tr>`;
}
body += `</table>`;

body += `<h2>Benchmarks And Logs</h2><div class="grid">`;
body += `<div class="card"><b>Library benchmark logs</b><p>${benchmarkLogs.map((f) => `<a href="${html(f.rel)}">${html(f.label)}</a>`).join("<br>")}</p></div>`;
body += `<div class="card"><b>Benchmark status</b><p>All linked benchmark logs are from the current sweep. Render text includes small, RTL mixed, and CJK scenarios.</p></div>`;
body += `<div class="card"><b>Raw audit</b><p><a href="render-path-audit.json">render-path-audit.json</a></p></div>`;
body += `</div>`;

for (const f of ["otter-render-text-rtl.log", "otter-render-text-cjk.log", "otter-render-scene.log", "otter-render-animation-batch.log"]) {
  const rel = `benchmarks/20260604-current/${f}`;
  if (!exists(rel)) continue;
  const excerpt = readText(rel).split("\n").slice(0, 42).join("\n");
  body += `<h3>${html(f)}</h3><pre>${html(excerpt)}</pre>`;
}

body += `</main></body></html>\n`;

fs.writeFileSync(path.join(reports, "ui-port-report.html"), body);
console.log(path.join(reports, "ui-port-report.html"));
