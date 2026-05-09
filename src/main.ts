import {
  App,
  FileSystemAdapter,
  ItemView,
  Menu,
  Modal,
  Notice,
  Plugin,
  PluginSettingTab,
  Scope,
  Setting,
  TFile,
  ViewStateResult,
  WorkspaceLeaf,
  apiVersion,
  normalizePath,
} from "obsidian";
import { ITheme, Terminal } from "@xterm/xterm";
import { FitAddon } from "@xterm/addon-fit";
import { execFileSync } from "child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "fs";
import { homedir, userInfo } from "os";
import { basename, delimiter, join } from "path";

import bashPromptRc from "./prompts/bash.sh";
import zshPromptRc from "./prompts/zsh.zsh";
import promptWizardScript from "./prompts/wizard.sh";

// ─── constants ──────────────────────────────────────────────────────────

const VIEW_TYPE_COMMAND = "command-view";
const NATIVE_PTY_DIR = join("native", "node-pty");
const PROMPT_CONFIG_FILE = "prompt.conf";
const PROMPT_WIZARD_FILE = "prmptwiz.sh";

const DEFAULT_FONT_SIZE = 14.5;
const MIN_FONT_SIZE = 8;
const MAX_FONT_SIZE = 32;
const BUNDLED_TERMINAL_FONT = "JetBrainsMono Nerd Font Mono";

const MONOSPACE_FALLBACK =
  '"SF Mono", SFMono-Regular, ui-monospace, Menlo, Monaco, Consolas, "Liberation Mono", monospace';

// ─── settings ───────────────────────────────────────────────────────────

type OpenLocation =
  | "tab"
  | "split-vertical"
  | "split-horizontal"
  | "left-sidebar"
  | "right-sidebar";
type WorkingDirectoryMode = "vault" | "home" | "custom";
type ColorMode = "theme" | "custom";
type PromptMode = "custom" | "shell";

interface CommandSettings {
  openLocation: OpenLocation;
  workingDirectoryMode: WorkingDirectoryMode;
  customWorkingDirectory: string;
  startupCommand: string;
  colorMode: ColorMode;
  customColor: string;
  promptMode: PromptMode;
  terminalFontFamily: string;
  fontSize: number;
}

const DEFAULT_SETTINGS: CommandSettings = {
  openLocation: "tab",
  workingDirectoryMode: "vault",
  customWorkingDirectory: "",
  startupCommand: "",
  colorMode: "theme",
  customColor: "#7c3aed",
  promptMode: "custom",
  terminalFontFamily: "",
  fontSize: DEFAULT_FONT_SIZE,
};

const OPEN_LOCATION_LABELS: Record<OpenLocation, string> = {
  tab: "New tab",
  "split-vertical": "Split right",
  "split-horizontal": "Split down",
  "left-sidebar": "Left sidebar",
  "right-sidebar": "Right sidebar",
};

const WORKING_DIRECTORY_LABELS: Record<WorkingDirectoryMode, string> = {
  vault: "Vault folder",
  home: "Home folder",
  custom: "Custom folder",
};

const COLOR_MODE_LABELS: Record<ColorMode, string> = {
  theme: "Obsidian accent",
  custom: "Custom color",
};

const PROMPT_MODE_LABELS: Record<PromptMode, string> = {
  custom: "Catppuccin Mocha (built-in)",
  shell: "System shell (sources your config)",
};

function resolveFontFamily(host: HTMLElement, value: string, fallback: string): string {
  const probe = host.ownerDocument.createElement("span");
  probe.style.fontFamily = value;
  if (!probe.style.fontFamily) return fallback;
  probe.style.display = "none";
  host.appendChild(probe);
  const resolved = getComputedStyle(probe).fontFamily.trim();
  probe.remove();
  return resolved || fallback;
}

function getConfiguredTerminalFontFamily(
  host: HTMLElement,
  settings: CommandSettings,
): string {
  const custom = settings.terminalFontFamily.trim();
  if (custom) return resolveFontFamily(host, custom, custom);
  return resolveFontFamily(host, "var(--font-monospace)", MONOSPACE_FALLBACK);
}

// ─── native PTY loader ──────────────────────────────────────────────────

interface IPty {
  readonly cols: number;
  readonly rows: number;
  onData(handler: (data: string) => void): void;
  onExit(handler: (event: { exitCode: number; signal?: number }) => void): void;
  write(data: string): void;
  resize(cols: number, rows: number): void;
  kill(signal?: string): void;
}

interface SpawnOptions {
  name: string;
  cols: number;
  rows: number;
  cwd: string;
  env: Record<string, string>;
}

interface PtyModule {
  spawn(file: string, args: string[], options: SpawnOptions): IPty;
}

let cachedPtyModule: PtyModule | null = null;

function loadNativePty(plugin: Plugin): PtyModule | null {
  if (cachedPtyModule) return cachedPtyModule;
  const adapter = plugin.app.vault.adapter;
  if (!(adapter instanceof FileSystemAdapter) || !plugin.manifest.dir) return null;
  const pluginDir = adapter.getFullPath(plugin.manifest.dir);
  const nativeDir = join(pluginDir, NATIVE_PTY_DIR);
  if (!existsSync(join(nativeDir, "package.json"))) return null;
  // Indirect eval keeps esbuild from rewriting this require at bundle time.
  cachedPtyModule = (0, eval)("require")(nativeDir) as PtyModule;
  return cachedPtyModule;
}

// ─── rename modal (used for both terminal tabs and notes) ───────────────

interface RenameModalOptions {
  title: string;
  label: string;
  description?: string;
  initialValue: string;
  placeholder: string;
  onSubmit(value: string): void | Promise<void>;
}

class RenameModal extends Modal {
  private value: string;
  private inputEl: HTMLInputElement | null = null;

  constructor(app: App, private readonly options: RenameModalOptions) {
    super(app);
    this.value = options.initialValue;
  }

  onOpen(): void {
    this.setTitle(this.options.title);
    this.contentEl.empty();

    const setting = new Setting(this.contentEl).setName(this.options.label);
    if (this.options.description) setting.setDesc(this.options.description);
    setting.addText((text) => {
      text
        .setPlaceholder(this.options.placeholder)
        .setValue(this.value)
        .onChange((v) => {
          this.value = v;
        });
      this.inputEl = text.inputEl;
      text.inputEl.addEventListener("keydown", (e) => {
        if (e.key === "Enter") {
          e.preventDefault();
          void this.submit();
        }
      });
    });

    new Setting(this.contentEl)
      .addButton((b) => b.setButtonText("Cancel").onClick(() => this.close()))
      .addButton((b) =>
        b
          .setButtonText("Save")
          .setCta()
          .onClick(() => void this.submit()),
      );

    window.setTimeout(() => {
      this.inputEl?.focus();
      this.inputEl?.select();
    }, 0);
  }

  private async submit(): Promise<void> {
    await this.options.onSubmit(this.value);
    this.close();
  }
}

// ─── note rename helpers ────────────────────────────────────────────────

const ILLEGAL_FILENAME_RE = /[\\/#^[\]|?*:<>"]/g;

function sanitizeBaseName(input: string, extension: string): string {
  let name = input.trim();
  const suffix = `.${extension}`;
  if (name.toLowerCase().endsWith(suffix.toLowerCase())) {
    name = name.slice(0, -suffix.length);
  }
  return name.replace(ILLEGAL_FILENAME_RE, " ").replace(/\s+/g, " ").trim();
}

function openNoteRenameModal(app: App, file: TFile, kind: string): void {
  new RenameModal(app, {
    title: `Rename ${kind}`,
    label: "Name",
    initialValue: file.basename,
    placeholder: file.basename,
    onSubmit: (value) => commitNoteRename(app, file, value, kind),
  }).open();
}

async function commitNoteRename(
  app: App,
  file: TFile,
  raw: string,
  kind: string,
): Promise<void> {
  const newBase = sanitizeBaseName(raw, file.extension);
  if (!newBase || newBase === file.basename) return;

  const parentPath = file.parent?.path;
  const dir = parentPath === "/" || !parentPath ? "" : parentPath;
  const newPath = normalizePath(
    dir ? `${dir}/${newBase}.${file.extension}` : `${newBase}.${file.extension}`,
  );

  const existing = app.vault.getAbstractFileByPath(newPath);
  if (existing && existing !== file) {
    new Notice(`A ${kind} named "${newBase}" already exists`);
    return;
  }

  await app.fileManager.renameFile(file, newPath);
}

// ─── prompt / shell helpers ─────────────────────────────────────────────

interface PromptConfig {
  enabled: boolean;
}

interface PtySpawnConfig {
  command: string;
  args: string[];
  cwd: string;
  env: Record<string, string>;
  label: string;
}

interface UserInfoSnapshot {
  username: string;
  homedir: string;
  shell?: string;
}

// ─── view ───────────────────────────────────────────────────────────────

class CommandView extends ItemView {
  private term: Terminal | null = null;
  private fitAddon: FitAddon | null = null;
  private resizeObserver: ResizeObserver | null = null;
  private termHost: HTMLElement | null = null;
  private pty: IPty | null = null;
  private flatpakHostBlocked = false;
  private flatpakSpawnPath: string | null | undefined = undefined;
  private title = "";

  constructor(leaf: WorkspaceLeaf, private readonly plugin: CommandPlugin) {
    super(leaf);
    this.scope = new Scope(this.app.scope);
    this.scope.register([], "Escape", (e) => this.handleScopedEscape(e));
  }

  getViewType(): string {
    return VIEW_TYPE_COMMAND;
  }

  getDisplayText(): string {
    return this.title || "Command";
  }

  getIcon(): string {
    return "terminal";
  }

  getState(): Record<string, unknown> {
    return { ...super.getState(), title: this.title };
  }

  async setState(state: unknown, result: ViewStateResult): Promise<void> {
    await super.setState(state, result);
    this.title = this.getTabTitleFromState(state);
    this.refreshTabTitle(false);
  }

  onPaneMenu(menu: Menu, source: string): void {
    super.onPaneMenu(menu, source);
    if (source !== "tab-header" && source !== "more-options") return;
    menu.addItem((item) =>
      item
        .setTitle("Rename terminal...")
        .setIcon("pencil")
        .onClick(() => this.openRenameModal()),
    );
  }

  async onOpen(): Promise<void> {
    const container = this.containerEl.children[1] as HTMLElement;
    container.empty();
    container.addClass("command-view");

    const host = container.createDiv({ cls: "command-terminal" });
    this.termHost = host;

    const term = new Terminal({
      fontFamily: this.getTerminalFontFamily(host),
      fontSize: this.getConfiguredFontSize(),
      lineHeight: 1.2,
      letterSpacing: 0,
      cursorBlink: true,
      customGlyphs: true,
      macOptionIsMeta: true,
      scrollback: 10000,
      convertEol: false,
      theme: this.getTerminalTheme(host),
    });

    term.attachCustomKeyEventHandler((e) => this.handleTerminalKeyEvent(e));

    const fit = new FitAddon();
    term.loadAddon(fit);
    term.open(host);
    this.safeFit(fit);

    this.term = term;
    this.fitAddon = fit;

    this.resizeObserver = new ResizeObserver(() => {
      this.safeFit(fit);
      if (this.pty && term.cols > 0 && term.rows > 0) {
        try {
          this.pty.resize(term.cols, term.rows);
        } catch {
          /* PTY may have exited; ignore */
        }
      }
    });
    this.resizeObserver.observe(host);

    this.registerDomEvent(
      host,
      "wheel",
      (e) => {
        if (e.ctrlKey || e.metaKey) {
          e.preventDefault();
          e.stopPropagation();
          this.adjustFontSize(e.deltaY < 0 ? 1 : -1);
        }
      },
      { capture: true, passive: false },
    );

    this.registerDomEvent(
      window,
      "keydown",
      (e) => this.handleWindowKeydown(e),
      { capture: true },
    );

    this.registerEvent(
      this.plugin.app.workspace.on("css-change", () => this.refreshTerminalTheme(host)),
    );

    this.registerEvent(
      this.plugin.app.workspace.on("active-leaf-change", (leaf) => {
        if (leaf === this.leaf) window.setTimeout(() => this.term?.focus(), 0);
      }),
    );

    this.writeStartupBanner(term);
    this.attachPty(term);
    term.focus();
  }

  // Called when a CommandView owns Escape before Obsidian's focus handler can
  // move back to the previously active note leaf.
  injectEscape(): void {
    this.term?.input("\x1b");
    this.app.workspace.setActiveLeaf(this.leaf, { focus: true });
    this.term?.focus();
  }

  private handleWindowKeydown(e: KeyboardEvent): void {
    if (e.key !== "Escape" || e.isComposing) return;
    if (!this.ownsKeyboardEvent(e)) return;
    if (this.shouldLetOverlayHandleEscape(e)) return;

    e.preventDefault();
    e.stopImmediatePropagation();
    this.injectEscape();
  }

  private handleScopedEscape(e: KeyboardEvent): false | void {
    if (e.isComposing) return;
    if (this.shouldLetOverlayHandleEscape(e)) return;

    e.preventDefault();
    e.stopImmediatePropagation();
    this.injectEscape();
    return false;
  }

  private ownsKeyboardEvent(e: KeyboardEvent): boolean {
    return (
      this.isActiveCommandView() ||
      (e.target instanceof Node && this.containerEl.contains(e.target))
    );
  }

  private isActiveCommandView(): boolean {
    return this.app.workspace.getActiveViewOfType(CommandView) === this;
  }

  private shouldLetOverlayHandleEscape(e: KeyboardEvent): boolean {
    return (
      e.target instanceof Element &&
      Boolean(
        e.target.closest(
          ".modal-container, .modal, .prompt, .menu, .suggestion-container, .popover",
        ),
      )
    );
  }

  private handleTerminalKeyEvent(e: KeyboardEvent): boolean {
    e.stopPropagation();
    if (e.type !== "keydown") return true;

    if (e.altKey && !e.ctrlKey && !e.metaKey && !e.shiftKey && e.key.toLowerCase() === "r") {
      e.preventDefault();
      this.openRenameModal();
      return false;
    }

    if (e.ctrlKey || e.metaKey) {
      if (e.key === "=" || e.key === "+") {
        e.preventDefault();
        this.adjustFontSize(1);
        return false;
      }
      if (e.key === "-" || e.key === "_") {
        e.preventDefault();
        this.adjustFontSize(-1);
        return false;
      }
      if (e.key === "0") {
        e.preventDefault();
        this.resetFontSize();
        return false;
      }
    }
    return true;
  }

  openRenameModal(): void {
    new RenameModal(this.app, {
      title: "Rename terminal",
      label: "Tab name",
      description: "Leave empty to use Command.",
      initialValue: this.title,
      placeholder: "Command",
      onSubmit: (value) => this.renameTab(value),
    }).open();
  }

  private renameTab(value: string): void {
    this.title = this.normalizeTabTitle(value);
    this.refreshTabTitle();
  }

  private normalizeTabTitle(value: unknown): string {
    return typeof value === "string" ? value.trim() : "";
  }

  private getTabTitleFromState(state: unknown): string {
    if (!state || typeof state !== "object") return "";
    return this.normalizeTabTitle((state as { title?: unknown }).title);
  }

  private refreshTabTitle(persist = true): void {
    const leaf = this.leaf as WorkspaceLeaf & {
      updateHeader?: () => void;
      updateTabHeader?: () => void;
    };
    leaf.updateHeader?.();
    leaf.updateTabHeader?.();
    if (persist) this.app.workspace.requestSaveLayout();
  }

  // ── font size ────────────────────────────────────────────────────────

  private setFontSize(size: number): void {
    const term = this.term;
    const fit = this.fitAddon;
    if (!term || !fit) return;

    const clamped = Math.min(MAX_FONT_SIZE, Math.max(MIN_FONT_SIZE, size));
    if (term.options.fontSize === clamped) return;

    term.options.fontSize = clamped;
    this.fitAndResizePty();
  }

  adjustFontSize(delta: number): void {
    const current = this.term?.options.fontSize ?? this.getConfiguredFontSize();
    this.setFontSize(current + delta);
  }

  resetFontSize(): void {
    this.setFontSize(this.getConfiguredFontSize());
  }

  refreshSettings(): void {
    const host = this.termHost;
    if (!this.term || !host) return;
    this.refreshTerminalTheme(host);
    this.setFontSize(this.getConfiguredFontSize());
    this.fitAndResizePty();
  }

  private getConfiguredFontSize(): number {
    const value = this.plugin.settings.fontSize;
    return Number.isFinite(value)
      ? Math.min(MAX_FONT_SIZE, Math.max(MIN_FONT_SIZE, value))
      : DEFAULT_FONT_SIZE;
  }

  private fitAndResizePty(): void {
    const term = this.term;
    const fit = this.fitAddon;
    if (!term || !fit) return;

    this.safeFit(fit);
    if (this.pty && term.cols > 0 && term.rows > 0) {
      try {
        this.pty.resize(term.cols, term.rows);
      } catch {
        /* PTY may have exited; ignore */
      }
    }
  }

  // ── theme / colors ───────────────────────────────────────────────────

  private refreshTerminalTheme(host: HTMLElement): void {
    if (!this.term) return;
    this.term.options.fontFamily = this.getTerminalFontFamily(host);
    this.term.options.theme = this.getTerminalTheme(host);
  }

  private getTerminalFontFamily(host: HTMLElement): string {
    return getConfiguredTerminalFontFamily(host, this.plugin.settings);
  }

  private getTerminalTheme(host: HTMLElement): ITheme {
    const hostStyle = getComputedStyle(host);
    const bodyStyle = getComputedStyle(host.ownerDocument.body);
    const cssVar = (name: string, fallback: string): string =>
      hostStyle.getPropertyValue(name).trim() ||
      bodyStyle.getPropertyValue(name).trim() ||
      fallback;
    const color = (name: string, fallback: string): string =>
      this.resolveCssColor(host, cssVar(name, fallback), fallback);

    const background = color("--background-primary", "#1e1e1e");
    const foreground = color("--text-normal", "#d4d4d4");
    const muted = color("--text-muted", "#858585");
    const faint = color("--text-faint", muted);
    const baseAccent = color("--interactive-accent", "#7c3aed");
    const accent = this.getConfiguredAccentColor(host, baseAccent);
    const accentBright =
      this.plugin.settings.colorMode === "custom"
        ? accent
        : color("--interactive-accent-hover", accent);
    const red = color("--color-red", "#e93147");
    const green = color("--color-green", "#08b94e");
    const yellow = color("--color-yellow", "#e0ac00");
    const blue = color("--color-blue", "#086ddd");
    const cyan = color("--color-cyan", "#00bfbc");

    return {
      background,
      foreground,
      cursor: accent,
      cursorAccent: background,
      selectionBackground: this.withAlpha(host, accent, 0.28),
      selectionInactiveBackground: this.withAlpha(host, accent, 0.16),
      black: faint,
      red,
      green,
      yellow,
      blue,
      magenta: accent,
      cyan,
      white: foreground,
      brightBlack: muted,
      brightRed: red,
      brightGreen: green,
      brightYellow: yellow,
      brightBlue: accent,
      brightMagenta: accentBright,
      brightCyan: cyan,
      brightWhite: foreground,
    };
  }

  private resolveCssColor(host: HTMLElement, value: string, fallback: string): string {
    const probe = host.ownerDocument.createElement("span");
    probe.style.color = value;
    if (!probe.style.color) return fallback;
    probe.style.display = "none";
    host.appendChild(probe);
    const resolved = getComputedStyle(probe).color.trim();
    probe.remove();
    return resolved || fallback;
  }

  private getConfiguredAccentColor(host: HTMLElement, fallback: string): string {
    if (this.plugin.settings.colorMode !== "custom") return fallback;
    return this.resolveCssColor(host, this.plugin.settings.customColor, fallback);
  }

  private withAlpha(host: HTMLElement, value: string, alpha: number): string {
    const resolved = this.resolveCssColor(host, value, value);
    const rgb = resolved.match(/^rgba?\(\s*([\d.]+)[,\s]+([\d.]+)[,\s]+([\d.]+)/);
    if (!rgb) return resolved;
    const [, r, g, b] = rgb;
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }

  // ── PTY attach / spawn ───────────────────────────────────────────────

  private attachPty(term: Terminal): void {
    const pty = loadNativePty(this.plugin);
    if (!pty) {
      this.writeMissingBackendBanner(term);
      return;
    }

    const config = this.getPtySpawnConfig();
    if (this.flatpakHostBlocked) this.writeFlatpakHostWarning(term);

    let child: IPty;
    try {
      child = pty.spawn(config.command, config.args, {
        name: "xterm-256color",
        cols: term.cols || 80,
        rows: term.rows || 24,
        cwd: config.cwd,
        env: config.env,
      });
    } catch (err) {
      term.writeln(`\x1b[31mFailed to spawn ${config.label}: ${String(err)}\x1b[0m`);
      return;
    }

    this.pty = child;
    child.onData((data) => term.write(data));
    child.onExit(({ exitCode, signal }) => {
      term.writeln(
        `\r\n\x1b[90m[process exited: code=${exitCode}${
          signal !== undefined ? ` signal=${signal}` : ""
        }]\x1b[0m`,
      );
      this.pty = null;
    });
    term.onData((data) => child.write(data));

    this.runStartupCommand(child);
  }

  private runStartupCommand(child: IPty): void {
    const cmd = this.plugin.settings.startupCommand.trim();
    if (cmd) child.write(`${cmd.replace(/\r?\n/g, "\r")}\r`);
  }

  private getPtySpawnConfig(): PtySpawnConfig {
    const shell = this.getLoginShell();
    const cwd = this.getWorkingDirectory();
    const env = this.getPtyEnv(shell);
    env.PWD = cwd;

    const promptConfig = this.getPromptConfig();
    if (promptConfig.enabled) this.preparePromptRuntime(env);
    const args = this.getInteractiveShellArgs(shell, env, promptConfig);
    const flatpakSpawn = this.getFlatpakSpawn();
    const cwdResolved = existsSync(cwd) ? cwd : env.HOME;

    if (flatpakSpawn) {
      return {
        command: flatpakSpawn,
        args: ["--host", `--directory=${cwd}`, ...this.getFlatpakEnvArgs(env), shell, ...args],
        cwd: cwdResolved,
        env,
        label: `${shell} on host`,
      };
    }
    return { command: shell, args, cwd: cwdResolved, env, label: shell };
  }

  // ── login shell / passwd ─────────────────────────────────────────────

  private getLoginShell(): string {
    const info = this.getUserInfo();
    const candidates = [
      process.env.SHELL,
      info.shell,
      this.getPasswdShell(info.username),
      "/usr/bin/zsh",
      "/bin/zsh",
      "/usr/bin/bash",
      "/bin/bash",
      "/bin/sh",
    ];
    for (const candidate of candidates) {
      if (candidate && this.isUsableShell(candidate)) return candidate;
    }
    return "/bin/sh";
  }

  private getUserInfo(): UserInfoSnapshot {
    try {
      const info = userInfo();
      return {
        username: info.username,
        homedir: info.homedir,
        shell: info.shell ?? undefined,
      };
    } catch {
      return {
        username: process.env.USER || process.env.LOGNAME || "",
        homedir: process.env.HOME || homedir(),
        shell: process.env.SHELL,
      };
    }
  }

  private getPasswdShell(username: string): string | undefined {
    if (!username) return undefined;
    try {
      const line = readFileSync("/etc/passwd", "utf8")
        .split("\n")
        .find((l) => l.startsWith(`${username}:`));
      return line?.split(":")[6]?.trim();
    } catch {
      return undefined;
    }
  }

  private isUsableShell(path: string): boolean {
    const name = basename(path);
    return (name === "zsh" || name === "bash") && existsSync(path);
  }

  // ── shell args / prompt rendering ────────────────────────────────────

  private getInteractiveShellArgs(
    shell: string,
    env: Record<string, string>,
    prompt: PromptConfig,
  ): string[] {
    if (!prompt.enabled) return this.getDefaultShellArgs(shell);
    const name = basename(shell);
    if (name === "bash") return this.getBashShellArgs(env);
    if (name === "zsh") return this.getZshShellArgs(env);
    // Unknown interactive shell — let it use its own default prompt.
    return this.getDefaultShellArgs(shell);
  }

  private getDefaultShellArgs(shell: string): string[] {
    const name = basename(shell);
    if (name === "sh") return [];
    return ["-l"];
  }

  private getPromptConfig(): PromptConfig {
    return { enabled: this.plugin.settings.promptMode === "custom" };
  }

  private preparePromptRuntime(env: Record<string, string>): void {
    const dir = this.getPromptRuntimeRootDirectory();
    if (!dir) return;

    const wizard = join(dir, PROMPT_WIZARD_FILE);
    env.COMMAND_PROMPT_CONFIG = join(dir, PROMPT_CONFIG_FILE);
    env.COMMAND_PROMPT_WIZARD = wizard;
    try {
      writeFileSync(wizard, promptWizardScript, "utf8");
    } catch {
      /* the prompt can still use built-in defaults */
    }
  }

  private getBashShellArgs(env: Record<string, string>): string[] {
    const rcfile = this.writePromptStartupFile("bash", ".bashrc", bashPromptRc);
    if (rcfile) return ["--rcfile", rcfile, "-i"];
    return this.getDefaultShellArgs("/bin/bash");
  }

  private getZshShellArgs(env: Record<string, string>): string[] {
    const dir = this.getPromptRuntimeDirectory("zsh");
    if (!dir) return this.getDefaultShellArgs("/bin/zsh");
    const target = join(dir, ".zshrc");
    try {
      writeFileSync(target, zshPromptRc, "utf8");
      env.ZDOTDIR = dir;
      return ["-i"];
    } catch {
      return this.getDefaultShellArgs("/bin/zsh");
    }
  }

  // ── runtime files ────────────────────────────────────────────────────

  private writePromptStartupFile(shell: string, filename: string, body: string): string | null {
    const dir = this.getPromptRuntimeDirectory(shell);
    if (!dir) return null;
    const target = join(dir, filename);
    try {
      writeFileSync(target, body, "utf8");
      return target;
    } catch {
      return null;
    }
  }

  private getPromptRuntimeDirectory(shell: string): string | null {
    const root = this.getPromptRuntimeRootDirectory();
    if (!root) return null;
    const dir = join(root, shell);
    try {
      mkdirSync(dir, { recursive: true });
      return dir;
    } catch {
      return null;
    }
  }

  private getPromptRuntimeRootDirectory(): string | null {
    const adapter = this.plugin.app.vault.adapter;
    if (!(adapter instanceof FileSystemAdapter) || !this.plugin.manifest.dir) return null;
    const dir = join(adapter.getFullPath(this.plugin.manifest.dir), ".command");
    try {
      mkdirSync(dir, { recursive: true });
      return dir;
    } catch {
      return null;
    }
  }

  // ── working directory / env / PATH ───────────────────────────────────

  private getWorkingDirectory(): string {
    const home = this.getUserInfo().homedir || process.env.HOME || "/";
    const vault = this.getVaultPath() || home;
    const { workingDirectoryMode, customWorkingDirectory } = this.plugin.settings;
    if (workingDirectoryMode === "home") return home;
    if (workingDirectoryMode === "custom") {
      const expanded = this.expandHomePath(customWorkingDirectory.trim(), home);
      if (expanded) return expanded;
    }
    return vault;
  }

  private getVaultPath(): string | null {
    const adapter = this.plugin.app.vault.adapter;
    return adapter instanceof FileSystemAdapter ? adapter.getBasePath() : null;
  }

  private expandHomePath(value: string, home: string): string {
    if (!value) return "";
    if (value === "~") return home;
    if (value.startsWith("~/")) return join(home, value.slice(2));
    return value;
  }

  private getPtyEnv(shell: string): Record<string, string> {
    const info = this.getUserInfo();
    const env: Record<string, string> = {};
    for (const [key, value] of Object.entries(process.env)) {
      if (typeof value === "string") env[key] = value;
    }
    env.HOME = info.homedir || env.HOME || homedir();
    env.USER = info.username || env.USER || env.LOGNAME || "";
    env.LOGNAME = env.USER;
    env.SHELL = shell;
    env.TERM = "xterm-256color";
    env.COLORTERM = "truecolor";
    env.TERM_PROGRAM = "Obsidian";
    env.TERM_PROGRAM_VERSION = apiVersion;
    env.PATH = this.getPathForShell(shell, env);
    return env;
  }

  private getPathForShell(shell: string, env: Record<string, string>): string {
    return this.mergePathValues([
      this.getLoginPath(shell, env),
      env.PATH ?? "",
      `${env.HOME}/.local/bin:${env.HOME}/bin:${env.HOME}/.cargo/bin:${env.HOME}/.npm-global/bin`,
      `${env.HOME}/.local/share/flatpak/exports/bin:/var/lib/flatpak/exports/bin`,
      "/home/linuxbrew/.linuxbrew/bin:/var/home/linuxbrew/.linuxbrew/bin",
      "/opt/homebrew/bin:/opt/homebrew/sbin",
      "/usr/local/bin:/usr/local/sbin",
      "/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin",
    ]);
  }

  private getLoginPath(shell: string, env: Record<string, string>): string {
    // Probing the user's login shell costs up to 3 s of synchronous wall time.
    // The result is stable for the session, so cache per-shell on the plugin.
    const cached = this.plugin.loginPathCache.get(shell);
    if (cached !== undefined) return cached;

    const startMarker = "__COMMAND_PATH_START__";
    const endMarker = "__COMMAND_PATH_END__";
    const probeScript = `printf '\\n${startMarker}%s${endMarker}\\n' "$PATH"`;
    const probeArgs = ["-lic", probeScript];

    const flatpakSpawn = this.getFlatpakSpawn();
    const command = flatpakSpawn ?? shell;
    const args = flatpakSpawn
      ? ["--host", ...this.getFlatpakEnvArgs(env), shell, ...probeArgs]
      : probeArgs;

    let result = "";
    try {
      const stdout = execFileSync(command, args, {
        env,
        encoding: "utf8",
        timeout: 3000,
        stdio: ["ignore", "pipe", "ignore"],
      });
      const match = stdout.match(new RegExp(`${startMarker}([\\s\\S]*?)${endMarker}`));
      result = match?.[1]?.trim() || "";
    } catch {
      /* probe failed; cache the empty result so we don't retry every spawn */
    }
    this.plugin.loginPathCache.set(shell, result);
    return result;
  }

  private mergePathValues(values: string[]): string {
    const seen = new Set<string>();
    const out: string[] = [];
    for (const value of values) {
      for (const entry of value.split(":")) {
        if (!entry || seen.has(entry)) continue;
        seen.add(entry);
        out.push(entry);
      }
    }
    return out.join(":");
  }

  // ── flatpak ──────────────────────────────────────────────────────────

  private getFlatpakSpawn(): string | null {
    if (this.flatpakSpawnPath !== undefined) return this.flatpakSpawnPath;
    if (!this.isFlatpak()) {
      this.flatpakSpawnPath = null;
      return null;
    }
    const path =
      this.findExecutable("flatpak-spawn", process.env.PATH || "") ||
      this.findExecutable("flatpak-spawn", "/usr/bin:/bin:/app/bin");
    if (!path) {
      this.flatpakSpawnPath = null;
      return null;
    }
    try {
      execFileSync(path, ["--host", "true"], {
        encoding: "utf8",
        timeout: 2000,
        stdio: ["ignore", "ignore", "ignore"],
      });
      this.flatpakHostBlocked = false;
      this.flatpakSpawnPath = path;
      return path;
    } catch {
      this.flatpakHostBlocked = true;
      this.flatpakSpawnPath = null;
      return null;
    }
  }

  private isFlatpak(): boolean {
    return Boolean(
      process.env.FLATPAK_ID ||
        process.env.container === "flatpak" ||
        existsSync("/.flatpak-info"),
    );
  }

  private getFlatpakEnvArgs(env: Record<string, string>): string[] {
    const passthrough = [
      "HOME",
      "USER",
      "LOGNAME",
      "SHELL",
      "TERM",
      "COLORTERM",
      "TERM_PROGRAM",
      "TERM_PROGRAM_VERSION",
      "PATH",
      "LANG",
      "LC_ALL",
      "XDG_DATA_HOME",
      "XDG_CONFIG_HOME",
      "XDG_CACHE_HOME",
      "PWD",
      "PS1",
      "ZDOTDIR",
      "COMMAND_PROMPT_CONFIG",
      "COMMAND_PROMPT_WIZARD",
    ];
    return passthrough.filter((k) => env[k]).map((k) => `--env=${k}=${env[k]}`);
  }

  private findExecutable(name: string, searchPath: string): string | null {
    for (const dir of searchPath.split(delimiter)) {
      if (!dir) continue;
      const candidate = join(dir, name);
      if (existsSync(candidate)) return candidate;
    }
    return null;
  }

  // ── banners ──────────────────────────────────────────────────────────

  private writeStartupBanner(term: Terminal): void {
    const vaultName = this.plugin.app.vault.getName() || "Notes";
    term.write(
      `\x1b[1m${vaultName}\x1b[0m \x1b[90m· Obsidian ${apiVersion}\x1b[0m\r\n\r\n`,
    );
  }

  private writeMissingBackendBanner(term: Terminal): void {
    term.writeln("\x1b[33mnode-pty backend is not installed.\x1b[0m\r");
    term.writeln("Run the setup script on this computer once:");
    term.writeln("\x1b[36m  bash <plugin-dir>/install-native-deps.sh\x1b[0m\r");
    term.writeln("Prerequisites (Debian/Ubuntu):");
    term.writeln("  sudo apt install nodejs npm build-essential python3\r");
    term.writeln("After it finishes, reload the plugin (toggle off/on in");
    term.writeln("Settings -> Community plugins).");
  }

  private writeFlatpakHostWarning(term: Terminal): void {
    const flatpakId = process.env.FLATPAK_ID || "md.obsidian.Obsidian";
    term.writeln("\x1b[33mHost shell access is blocked by Flatpak permissions.\x1b[0m");
    term.writeln("This terminal is starting inside the sandbox for now.");
    term.writeln("Run this once on the Bazzite host, then restart Obsidian:");
    term.writeln(
      `\x1b[36m  flatpak override --user --talk-name=org.freedesktop.Flatpak ${flatpakId}\x1b[0m\r`,
    );
    term.writeln("After it finishes, reload the plugin (toggle off/on in");
    term.writeln("Settings -> Community plugins).");
  }

  // ── lifecycle ────────────────────────────────────────────────────────

  private safeFit(fit: FitAddon): void {
    try {
      fit.fit();
    } catch {
      /* xterm not yet attached */
    }
  }

  async onClose(): Promise<void> {
    this.resizeObserver?.disconnect();
    this.resizeObserver = null;
    if (this.pty) {
      try {
        this.pty.kill();
      } catch {
        /* ignore */
      }
      this.pty = null;
    }
    this.term?.dispose();
    this.term = null;
    this.termHost = null;
    this.fitAddon = null;
  }
}

// ─── settings tab ───────────────────────────────────────────────────────

class CommandSettingTab extends PluginSettingTab {
  constructor(app: App, private readonly plugin: CommandPlugin) {
    super(app, plugin);
  }

  private getFontSettingDesc(containerEl: HTMLElement): DocumentFragment {
    const fragment = containerEl.ownerDocument.createDocumentFragment();
    const current = getConfiguredTerminalFontFamily(containerEl, this.plugin.settings);
    fragment.appendText("Current: ");
    const code = containerEl.ownerDocument.createElement("code");
    code.textContent = current;
    fragment.appendChild(code);
    fragment.appendText(
      ". Leave blank to follow Obsidian's monospace font. Use a CSS font-family stack for a Command-only override.",
    );
    return fragment;
  }

  display(): void {
    const { containerEl } = this;
    containerEl.empty();
    containerEl.createEl("h2", { text: "Command" });

    new Setting(containerEl)
      .setName("Open location")
      .setDesc(
        "Where new terminal sessions open when launched from the ribbon or command palette.",
      )
      .addDropdown((dd) =>
        dd
          .addOptions(OPEN_LOCATION_LABELS)
          .setValue(this.plugin.settings.openLocation)
          .onChange(async (v) => {
            this.plugin.settings.openLocation = v as OpenLocation;
            await this.plugin.saveSettings();
          }),
      );

    new Setting(containerEl)
      .setName("Terminal start folder")
      .setDesc("Used for new terminal sessions.")
      .addDropdown((dd) =>
        dd
          .addOptions(WORKING_DIRECTORY_LABELS)
          .setValue(this.plugin.settings.workingDirectoryMode)
          .onChange(async (v) => {
            this.plugin.settings.workingDirectoryMode = v as WorkingDirectoryMode;
            await this.plugin.saveSettings();
            this.display();
          }),
      );

    new Setting(containerEl)
      .setName("Custom start folder")
      .setDesc("Absolute path for new terminal sessions. The ~ prefix is supported.")
      .addText((text) =>
        text
          .setPlaceholder("~/Projects")
          .setValue(this.plugin.settings.customWorkingDirectory)
          .setDisabled(this.plugin.settings.workingDirectoryMode !== "custom")
          .onChange(async (v) => {
            this.plugin.settings.customWorkingDirectory = v.trim();
            await this.plugin.saveSettings();
          }),
      );

    new Setting(containerEl)
      .setName("Startup command")
      .setDesc("Runs once when a new terminal session starts. Leave empty to disable.")
      .addText((text) =>
        text
          .setPlaceholder("npm run dev")
          .setValue(this.plugin.settings.startupCommand)
          .onChange(async (v) => {
            this.plugin.settings.startupCommand = v.trim();
            await this.plugin.saveSettings();
          }),
      );

    new Setting(containerEl)
      .setName("Terminal color")
      .setDesc(
        "Controls the cursor, selection, logo, terminal accent, and prompt when prompt color follows terminal color.",
      )
      .addDropdown((dd) =>
        dd
          .addOptions(COLOR_MODE_LABELS)
          .setValue(this.plugin.settings.colorMode)
          .onChange(async (v) => {
            this.plugin.settings.colorMode = v as ColorMode;
            await this.plugin.saveSettings();
            this.display();
          }),
      );

    new Setting(containerEl)
      .setName("Custom color")
      .setDesc("Used when terminal color is set to custom.")
      .addColorPicker((cp) =>
        cp
          .setValue(this.plugin.settings.customColor)
          .setDisabled(this.plugin.settings.colorMode !== "custom")
          .onChange(async (v) => {
            this.plugin.settings.customColor = v;
            await this.plugin.saveSettings();
          }),
      );

    new Setting(containerEl)
      .setName("Prompt")
      .setDesc(
        "Catppuccin Mocha shows a powerline-style prompt and ignores your shell config (requires a Nerd Font for the glyphs). System shell launches your real $SHELL with its own startup files.",
      )
      .addDropdown((dd) =>
        dd
          .addOptions(PROMPT_MODE_LABELS)
          .setValue(this.plugin.settings.promptMode)
          .onChange(async (v) => {
            this.plugin.settings.promptMode = v as PromptMode;
            await this.plugin.saveSettings();
          }),
      );

    let updateFontInput: ((value: string) => void) | null = null;
    const fontSetting = new Setting(containerEl).setName("Terminal font");
    fontSetting
      .setDesc(this.getFontSettingDesc(containerEl))
      .addText((text) => {
        updateFontInput = (value) => text.setValue(value);
        text
          .setPlaceholder(BUNDLED_TERMINAL_FONT)
          .setValue(this.plugin.settings.terminalFontFamily)
          .onChange(async (v) => {
            this.plugin.settings.terminalFontFamily = v.trim();
            await this.plugin.saveSettings();
            fontSetting.setDesc(this.getFontSettingDesc(containerEl));
          });
      })
      .addButton((b) =>
        b.setButtonText("Use bundled").onClick(async () => {
          this.plugin.settings.terminalFontFamily = BUNDLED_TERMINAL_FONT;
          updateFontInput?.(BUNDLED_TERMINAL_FONT);
          await this.plugin.saveSettings();
          fontSetting.setDesc(this.getFontSettingDesc(containerEl));
        }),
      )
      .addButton((b) =>
        b.setButtonText("Reset").onClick(async () => {
          this.plugin.settings.terminalFontFamily = "";
          updateFontInput?.("");
          await this.plugin.saveSettings();
          fontSetting.setDesc(this.getFontSettingDesc(containerEl));
        }),
      );

    new Setting(containerEl)
      .setName("Default font size")
      .setDesc("Starting font size for new terminal views.")
      .addSlider((slider) =>
        slider
          .setLimits(MIN_FONT_SIZE, MAX_FONT_SIZE, 0.5)
          .setValue(this.plugin.settings.fontSize)
          .setDynamicTooltip()
          .onChange(async (v) => {
            this.plugin.settings.fontSize = v;
            await this.plugin.saveSettings();
          }),
      )
      .addButton((b) =>
        b.setButtonText("Reset").onClick(async () => {
          this.plugin.settings.fontSize = DEFAULT_FONT_SIZE;
          await this.plugin.saveSettings();
          this.display();
        }),
      );
  }
}

// ─── plugin entry ───────────────────────────────────────────────────────

export default class CommandPlugin extends Plugin {
  settings: CommandSettings = { ...DEFAULT_SETTINGS };
  readonly loginPathCache = new Map<string, string>();

  async onload(): Promise<void> {
    await this.loadSettings();

    console.log(
      `[command] electron ${process.versions.electron}, node ${process.versions.node}, ABI ${process.versions.modules}, NAPI ${process.versions.napi}`,
    );

    this.registerView(VIEW_TYPE_COMMAND, (leaf) => new CommandView(leaf, this));

    this.addRibbonIcon("terminal", "Open Command", () => {
      void this.activateView();
    });

    this.addCommand({
      id: "open-command",
      name: "Open Command",
      callback: () => void this.activateView(),
    });

    this.addCommand({
      id: "rename-current-tab-or-note",
      name: "Rename current tab or note",
      hotkeys: [{ modifiers: ["Alt"], key: "r" }],
      checkCallback: (checking) => {
        if (!this.canRenameActiveTabOrNote()) return false;
        if (!checking) this.renameActiveTabOrNote();
        return true;
      },
    });

    this.addSettingTab(new CommandSettingTab(this.app, this));
  }

  async loadSettings(): Promise<void> {
    const stored = (await this.loadData()) as Partial<CommandSettings> | null;
    this.settings = { ...DEFAULT_SETTINGS, ...(stored ?? {}) };
  }

  async saveSettings(): Promise<void> {
    await this.saveData(this.settings);
    this.refreshOpenViews();
  }

  private async activateView(): Promise<void> {
    const { workspace } = this.app;
    const leaf = this.getLeafForOpenLocation(this.settings.openLocation);
    await leaf.setViewState({ type: VIEW_TYPE_COMMAND, active: true });
    await workspace.revealLeaf(leaf);
  }

  private canRenameActiveTabOrNote(): boolean {
    if (this.getActiveCommandView()) return true;
    return this.isRenameableNote(this.app.workspace.getActiveFile());
  }

  private renameActiveTabOrNote(): void {
    const view = this.getActiveCommandView();
    if (view) {
      view.openRenameModal();
      return;
    }
    const file = this.app.workspace.getActiveFile();
    if (this.isRenameableNote(file) && file) {
      const kind = file.extension === "chalk" ? "Chalk board" : "note";
      openNoteRenameModal(this.app, file, kind);
      return;
    }
    new Notice("No Command tab, Chalk board, or Markdown note is active");
  }

  private getActiveCommandView(): CommandView | null {
    return this.app.workspace.getActiveViewOfType(CommandView);
  }

  private isRenameableNote(file: TFile | null): file is TFile {
    return file?.extension === "md" || file?.extension === "chalk";
  }

  private getLeafForOpenLocation(location: OpenLocation): WorkspaceLeaf {
    const { workspace } = this.app;
    if (location === "left-sidebar") {
      return workspace.getLeftLeaf(false) ?? workspace.getLeaf("tab");
    }
    if (location === "right-sidebar") {
      return workspace.getRightLeaf(false) ?? workspace.getLeaf("tab");
    }
    if (location === "split-vertical" || location === "split-horizontal") {
      const direction = location === "split-vertical" ? "vertical" : "horizontal";
      return workspace.getLeaf("split", direction);
    }
    return workspace.getLeaf("tab");
  }

  private refreshOpenViews(): void {
    for (const leaf of this.app.workspace.getLeavesOfType(VIEW_TYPE_COMMAND)) {
      if (leaf.view instanceof CommandView) leaf.view.refreshSettings();
    }
  }
}
