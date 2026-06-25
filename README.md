

## 📄 2. `README.md`


# Webit - One-Command Web VS Code Server

`Webit` is a minimalist tool that allows you to instantly spin up a full-featured VS Code (code-server) development environment in your browser for the current or any specified directory—using just **a single command**.

Equipped with the `--rm` flag, it leaves zero clutter on your host system once stopped.

---

## 🚀 Quick Start

Navigate to the directory you want to open or serve, and run the following command in your terminal:

```bash
curl -sSL https://raw.githubusercontent.com/ouut/webit/main/run.sh | bash

```

> *Note: If your default repository branch is `master`, remember to change `main` to `master` in the URL.*

Once fired up, open your browser and go to `http://localhost`. The default password is `cc`.

---

## ⚙️ Custom Configurations

You can pass custom arguments to the script using the `bash -s --` suffix to change the port, password, or host directory.

### 1. Modify Port and Password

To run on port `8080` with the password `123456`:

```bash
curl -sSL https://raw.githubusercontent.com/ouut/webit/main/run.sh | bash -s -- --port 8080 --password 123456

```

### 2. Specify a Different Directory

Want to share a directory other than your current one? Use the `--dir` flag with an absolute path:

```bash
curl -sSL https://raw.githubusercontent.com/ouut/webit/main/run.sh | bash -s -- --dir /home/user/my-project --port 9000

```

---

## 🛑 Stop and Destroy

Since the container runs with the `--rm` flag enabled, you don't need to manually run `docker rm`. When you are done, simply stop the container from your terminal, and it will be completely removed along with the port it occupied:

```bash
docker stop web-ide

```

---

## 🔒 Permissions & Safety

* The script automatically captures your host user's `UID` and `GID` and passes them into Docker. This ensures that any files created or modified inside the Web IDE will belong entirely to your local user, **completely avoiding annoying `root` permission locks**.

```
