# Homebrew formula for the CompBox CLI + Agent Runner daemon (ENG-122-3 / ENG-127).
#
# SOURCE OF TRUTH. This file is the canonical formula, maintained in the main
# CompBox monorepo at deploy/homebrew-tap/compbox.rb. It is PUBLISHED (copied)
# to the separate tap repo github.com/mycompbox/homebrew-tap as
# Formula/compbox.rb — see deploy/homebrew-tap/README.md for the tap topology
# and publish steps. Homebrew's `brew tap mycompbox/tap` resolves to a
# repo named `homebrew-<name>`, so the tap CANNOT live inside this monorepo.
#
# This formula assumes:
#   - A GitHub Release publishing a SINGLE, architecture-neutral tarball
#     `compbox-macos.tar.gz` (containing exactly `compbox.cjs` and
#     `compbox-mcp.cjs` at the archive root — see ENG-139) as a release
#     asset. There are NO per-arch assets: both bundles are pure JavaScript
#     (keytar is external, with a file-storage fallback), so the arm64 and
#     x64 artifacts would be identical.
#   - The tarball is built + packaged by
#     `pnpm --filter @mycompbox/compbox-cli build:standalone:package`
#     (runs packages/cli/build-standalone.mjs).
#   - The `version`/`url`/`sha256` fields below are MAINTAINED BY RELEASE
#     AUTOMATION (ENG-125): the `Release CLI` workflow
#     (.github/workflows/release-cli.yml) runs scripts/bump-formula.mjs at
#     release time to rewrite them in the tap repo's Formula/compbox.rb. Do NOT
#     hand-edit them here — the placeholder values below are intentional and are
#     overwritten by the automation on each `cli-v*` tag.
#
# The bundle (compbox.cjs) requires a Node runtime — it's a bundled CJS
# module, not a compiled native binary — hence `depends_on "node"` and the
# thin wrapper script below. A future enhancement could switch to Node's
# Single Executable Application (SEA) feature to ship a truly standalone
# binary with no Node dependency; deferred as a separate increment.
#
# Usage once published:
#   brew tap mycompbox/tap
#   brew install compbox
#   compbox login && compbox configure
#   brew services start compbox   # registers + starts the launchd service

class CompboxAT19 < Formula
  desc "Pair a machine, manage Skill Packs, and run the CompBox Agent Runner daemon"
  homepage "https://mycompbox.web.app"
  # PLACEHOLDER — the url points at the single arch-neutral `compbox-macos.tar.gz`
  # release asset. The version/url/sha256 are rewritten by scripts/bump-formula.mjs
  # at release time (see the versioning note above); do NOT hand-edit them.
  # Stanza order (url → version → sha256) follows Homebrew's ComponentsOrder cop.
  url "https://github.com/mycompbox/homebrew-tap/releases/download/cli-v1.9.1/compbox-macos.tar.gz"
  version "1.9.1"
  sha256 "b93b01aac5036e9663fad4201a17c9878cd1a34365efa5cc41627698c62c8fd7"
  license :cannot_represent

  depends_on "node"

  def install
    # The release tarball contains `compbox.cjs` and `compbox-mcp.cjs` at its
    # root; Homebrew extracts them into the build dir before `install` runs,
    # so they're available here. The MCP bundle is installed alongside the CLI
    # so `compbox configure` can point MCP clients at the local, pinned copy
    # (node #{libexec}/compbox-mcp.cjs) instead of fetching via npx.
    libexec.install "compbox.cjs"
    libexec.install "compbox-mcp.cjs"
    # Thin wrapper so `compbox` on PATH just delegates to `node compbox.cjs`.
    (bin/"compbox").write <<~SH
      #!/bin/bash
      exec "#{formula_opt_bin("node")}/node" "#{libexec}/compbox.cjs" "$@"
    SH
    (bin/"compbox").chmod 0755
  end

  # `brew services start compbox` generates and manages the launchd plist
  # (macOS) for us — see the ENG-122 distribution decision. This REPLACES
  # hand-rolled launchd generation; only Windows needs its own service adapter
  # (compbox service install), since there's no Homebrew there.
  service do
    run [opt_bin/"compbox", "run"]
    keep_alive true
    log_path var/"log/compbox.log"
    error_log_path var/"log/compbox.log"
  end

  # Post-install guidance. Homebrew prints this after `brew install compbox`.
  # IMPORTANT: this hook does NOT write MCP config or perform auth — that is
  # owned entirely by `compbox configure` / `compbox login`. The formula only
  # points the operator at those commands (ENG-126 messaging convention).
  def caveats
    <<~EOS
      Finish setting up CompBox on this machine:

        1. compbox login              # authenticate this machine to CompBox
        2. compbox configure          # writes the MCP config + local settings
        3. brew services start compbox  # start the Agent Runner daemon (launchd)

      The CompBox MCP server bundle is installed with this formula at:
        #{opt_libexec}/compbox-mcp.cjs
      `compbox configure` detects it and writes your MCP config to launch it
      directly with node — no separate install or npx download needed.

      Logs (once the service is running):
        #{var}/log/compbox.log
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/compbox --version")
    # Both bundles must ship: the CLI wrapper target and the MCP server bundle
    # that `compbox configure` points MCP clients at.
    assert_path_exists libexec/"compbox.cjs"
    assert_path_exists libexec/"compbox-mcp.cjs"
  end
end
