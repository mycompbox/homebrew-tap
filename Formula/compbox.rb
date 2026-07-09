# Homebrew formula for the CompBox CLI + Agent Runner daemon.
#
# This is the PUBLISHED formula in the public tap repo github.com/mycompbox/homebrew-tap.
# The canonical source lives in the (private) CompBox monorepo at
# deploy/homebrew-tap/compbox.rb. `brew tap mycompbox/tap` resolves to this repo
# (named `homebrew-tap`), and `brew install compbox` reads this file.
#
# The url points at a SINGLE, architecture-neutral tarball `compbox-macos.tar.gz`
# (containing `compbox.cjs` at the archive root), published as a GitHub Release
# asset ON THIS PUBLIC TAP REPO. There are no per-arch assets: the bundle is pure
# JavaScript (keytar is external, with a file-storage fallback), so arm64 and x64
# are identical. The bundle requires a Node runtime — hence `depends_on "node"`
# and the thin wrapper below.
#
# version/url/sha256 are updated per release (by scripts/bump-formula.mjs in the
# private repo's release automation, or a manual publish).

class Compbox < Formula
  desc "Pair a machine, manage Skill Packs, and run the CompBox Agent Runner daemon"
  homepage "https://mycompbox.web.app"
  url "https://github.com/mycompbox/homebrew-tap/releases/download/v1.8.0/compbox-macos.tar.gz"
  version "1.8.0"
  sha256 "e3d50966e6136dda3009d96c4422a4007267b5ad0b70f97c4c6141c98c5662d7"
  license "UNLICENSED"

  depends_on "node"

  def install
    # The release tarball contains `compbox.cjs` at its root; Homebrew extracts
    # it into the build dir before `install` runs, so it's available here.
    libexec.install "compbox.cjs"
    # Thin wrapper so `compbox` on PATH just delegates to `node compbox.cjs`.
    (bin/"compbox").write <<~SH
      #!/bin/bash
      exec "#{formula_opt_bin("node")}/node" "#{libexec}/compbox.cjs" "$@"
    SH
    (bin/"compbox").chmod 0755
  end

  # `brew services start compbox` generates and manages the launchd plist
  # (macOS) for us. Only Windows needs its own service adapter
  # (compbox service install), since there's no Homebrew there.
  service do
    run [opt_bin/"compbox", "run"]
    keep_alive true
    log_path var/"log/compbox.log"
    error_log_path var/"log/compbox.log"
  end

  # Post-install guidance. Homebrew prints this after `brew install compbox`.
  # This hook does NOT write MCP config or perform auth — that is owned entirely
  # by `compbox configure` / `compbox login`. The formula only points the
  # operator at those commands.
  def caveats
    <<~EOS
      Finish setting up CompBox on this machine:

        1. compbox login              # authenticate this machine to CompBox
        2. compbox configure          # writes the MCP config + local settings
        3. brew services start compbox  # start the Agent Runner daemon (launchd)

      The CompBox MCP server auto-installs on first use via npx — you do not
      need to install it separately.

      Logs (once the service is running):
        #{var}/log/compbox.log
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/compbox --version")
  end
end
