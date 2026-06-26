# Webit - One-Command Web VS Code Server

`Webit` is a minimalist tool that allows you to instantly spin up a full-featured VS Code (code-server) development environment in your browser for the current or any specified directory—using just **a single command**.

Works with both **root** and **rootless** Docker, automatically detecting your setup and mapping file permissions correctly.

---

## 🚀 Quick Start

Navigate to the directory you want to open or serve, and run the following command in your terminal:

```bash
curl -sSL https://raw.githubusercontent.com/ouut/webit/main/run.sh | bash

```

> *Note: If your default repository branch is `master`, remember to change `main` to `master` in the URL.*

Once fired up, open your browser and go to `http://localhost:8080`. The default password is `cc`.

---

## ⚙️ Custom Configurations

You can pass custom arguments to the script using the `bash -s --` suffix to change the port, password, or host directory.

### 1. Modify Port and Password

To run on port `9090` with the password `123456`:

```bash
curl -sSL https://raw.githubusercontent.com/ouut/webit/main/run.sh | bash -s -- --port 9090 --password 123456

```

### 2. Specify a Different Directory

Want to share a directory other than your current one? Use the `--dir` flag with an absolute path:

```bash
curl -sSL https://raw.githubusercontent.com/ouut/webit/main/run.sh | bash -s -- --dir /home/user/my-project --port 9000

```

---

## 🖥️ Local Management (Download & Run)

You can also download `run.sh` and use it as a local service manager:

```bash
# Download once
curl -sSL https://raw.githubusercontent.com/ouut/webit/main/run.sh -o run.sh
chmod +x run.sh

# Service commands
./run.sh start             # Start (default port 8080, password cc, current dir)
./run.sh start --port 9090 --password 123456 --dir /path/to/project
./run.sh stop              # Stop the container (data preserved)
./run.sh restart           # Stop and re-create with new config
./run.sh restart --port 9000
./run.sh status            # Show container status
./run.sh logs              # Tail container logs
./run.sh remove            # Destroy container completely

# Just run it without downloading
./run.sh                   # Same as './run.sh start'
```

---

## 🛑 Stop and Resume

The container is **persistent** — stopping it won't destroy your environment or config:

```bash
# Using the script (recommended)
./run.sh stop
./run.sh start             # Resume where you left off

# Or raw docker commands
docker stop web-ide
docker start web-ide
```

To fully destroy the container and all its data:

```bash
./run.sh remove
# or: docker stop web-ide && docker rm web-ide
```

---

## 🔒 Permissions & Safety

The script automatically detects your Docker setup and applies the correct user mapping:

| Docker Mode | Strategy | Result |
|---|---|---|
| **rootless** | Runs as container root (`--user 0:0`) | Rootless maps it to your host user — files belong to **you** |
| **root** | Runs with your host UID/GID (`--user $UID:$GID`) | Files belong to **you**, never to host root |

This ensures that any files created or modified inside the Web IDE will belong entirely to your local user, **completely avoiding annoying `root` permission locks**.
