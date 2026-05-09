import { build, context } from "esbuild";
import builtins from "builtin-modules";
import { readFile, writeFile } from "fs/promises";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const here = dirname(fileURLToPath(import.meta.url));
const isProd = process.argv[2] === "production";

const banner = "/* obsidian-command — bundled by esbuild */";

const buildOptions = {
  absWorkingDir: here,
  entryPoints: [join(here, "src", "main.ts")],
  outfile: join(here, "main.js"),
  bundle: true,
  format: "cjs",
  target: "ES2020",
  platform: "node",
  logLevel: "info",
  treeShaking: true,
  minify: isProd,
  sourcemap: isProd ? false : "inline",
  banner: { js: banner },
  external: ["obsidian", "electron", ...builtins],
  loader: { ".sh": "text", ".zsh": "text" },
};

async function bundleStyles() {
  const xtermCss = await readFile(
    join(here, "node_modules", "@xterm", "xterm", "css", "xterm.css"),
    "utf8",
  );
  const ours = await readFile(join(here, "src", "styles.css"), "utf8");
  await writeFile(
    join(here, "styles.css"),
    `/* vendored from @xterm/xterm/css/xterm.css */\n${xtermCss.trim()}\n\n\n${ours}`,
  );
}

if (isProd) {
  await build(buildOptions);
  await bundleStyles();
} else {
  const ctx = await context(buildOptions);
  await ctx.watch();
  await bundleStyles();
  console.log("[command] esbuild watching src/main.ts");
}
