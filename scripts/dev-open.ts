import { spawn } from "node:child_process";
import process from "node:process";

const url = process.env.DEV_LAUNCH_URL || "http://localhost:3000";

const server = spawn("pnpm", ["dev"], {
  stdio: ["ignore", "pipe", "pipe"],
  shell: process.platform === "win32",
  env: process.env,
});

let opened = false;
const openUrl = () => {
  if (opened) return;
  opened = true;

  const platform = process.platform;
  try {
    if (platform === "darwin") {
      const child = spawn("open", [url], { detached: true, stdio: "ignore" });
      child.unref();
    } else if (platform === "win32") {
      const child = spawn("cmd", ["/c", "start", "", url], { detached: true, stdio: "ignore" });
      child.unref();
    } else {
      const child = spawn("xdg-open", [url], { detached: true, stdio: "ignore" });
      child.unref();
    }
  } catch (err) {
    console.warn("Failed to open browser tab automatically", err);
  }
};

const signalReady = (chunk: Buffer) => {
  const text = chunk.toString();
  if (!opened && /ready|started server/i.test(text)) {
    openUrl();
  }
  process.stdout.write(chunk);
};

server.stdout?.on("data", signalReady);
server.stderr?.on("data", (chunk) => {
  const text = chunk.toString();
  process.stderr.write(chunk);
  if (!opened && /ready|started server/i.test(text)) {
    openUrl();
  }
});

const exit = (code: number | null) => {
  if (code !== null && code !== 0) {
    process.exit(code);
  } else {
    process.exit(0);
  }
};

server.on("close", (code) => exit(code));

const shutdown = (signal: NodeJS.Signals) => {
  if (!server.killed) {
    server.kill(signal);
  }
  process.exit(0);
};

process.on("SIGINT", () => shutdown("SIGINT"));
process.on("SIGTERM", () => shutdown("SIGTERM"));

process.on("exit", () => {
  if (!server.killed) {
    server.kill();
  }
});

setTimeout(() => {
  if (!opened) openUrl();
}, 4000);

