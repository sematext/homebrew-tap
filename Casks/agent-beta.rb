cask "agent-beta" do
  arch arm: "arm64", intel: "amd64"

  version "4.6.0-rc.1"
  sha256 arm:   "55838489e5881866ba1d1ab9a6c6af4acc047a1fb0152d98048b682ec05f0014",
         intel: "f56fddd0d323f879f7f3bf7a151efef4f1fed3f2cf836e920277ab2ffa4ab361"

  url "https://pub-repo.sematext.com/macos/sematext-agent/#{version}/st-agent_#{version}_darwin_#{arch}.tar.gz"
  name "Sematext Agent (beta)"
  desc "Beta channel of the Sematext Agent: release candidates and stable releases"
  homepage "https://sematext.com/docs/agents/sematext-agent/"

  livecheck do
    skip "Published by the Sematext Agent release pipeline"
  end

  conflicts_with cask: "agent"

  binary "st-agent"

  postflight do
    system_command "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "#{staged_path}/st-agent"]
    # An existing config means this is an upgrade: reinstall the daemon from
    # the new binary. The file is root-only, so only its presence is checked.
    if File.exist?("/opt/spm/properties/infra.properties")
      # sudo -E would carry a developer's SPM_ROOT; the check above is for /opt/spm.
      system_command "#{staged_path}/st-agent", args: ["macos-service", "install"], sudo: true,
                     env: { "SPM_ROOT" => "/opt/spm" }
    end
  end

  uninstall launchctl: "com.sematext.agent",
            delete:    "/opt/spm/spm-monitor/bin/st-agent"

  zap delete: "/opt/spm"

  caveats <<~EOS
    Sematext Agent runs as a root LaunchDaemon. Install and start it with your
    Infra App token:

      sudo st-agent macos-service install --infra-token <token> --region eu

    brew upgrade reinstalls the daemon (one sudo prompt). Config and tokens
    stay in /opt/spm until `brew uninstall --zap sematext/tap/agent-beta`.
  EOS
end
