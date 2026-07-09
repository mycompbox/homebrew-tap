# CompBox Homebrew Tap

The public Homebrew tap for **[CompBox](https://mycompbox.web.app)** — installs the CompBox CLI and the Agent Runner daemon on macOS.

## Install

```bash
brew tap mycompbox/tap
brew trust mycompbox/tap    # one-time: Homebrew requires trusting third-party taps
brew install compbox
```

The `brew trust` step is a one-time Homebrew security confirmation for any
third-party tap — you only do it once per machine. (Depending on your Homebrew
version, `brew install` may instead prompt you to trust the tap; either way,
confirm it.)

## Set up this machine

```bash
compbox login                 # authenticate this machine to your CompBox account
compbox configure             # writes the MCP config + pairs this device
brew services start compbox   # start the Agent Runner daemon (runs in the background)
```

Verify everything is healthy:

```bash
compbox doctor
```

> The CompBox **MCP server** auto-installs on first use via `npx` — you don't install it separately. Homebrew delivers the CLI and the Agent Runner daemon; `compbox configure` wires the MCP server into your local Claude client.

## Update

```bash
brew upgrade compbox
brew services restart compbox
```

## Uninstall

```bash
brew services stop compbox
brew uninstall compbox
brew untap mycompbox/tap
```

## What this tap contains

- `Formula/compbox.rb` — the install recipe (points at the `compbox-macos.tar.gz` release asset published on this repo).
- GitHub Releases — the compiled, architecture-neutral CLI bundle (`compbox.cjs`, requires Node).

The CompBox **source code is not** in this repo — this tap distributes only the built product.
