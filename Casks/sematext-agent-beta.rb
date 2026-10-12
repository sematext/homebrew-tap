cask "sematext-agent-beta" do
  arch arm: "arm64", intel: "amd64"

  version "4.6.0-rc.6"
  sha256 arm:   "e75b7e0d33cdcadf95dae42edc921d418a0ffda79850eb11897553cb426032bc",
         intel: "e6161f4435c9676a98a3b0c07cff0135134bc4ce07571a89d99607c078ad1724"

  url "https://pub-repo.sematext.com/macos/sematext-agent/#{version}/st-agent_#{version}_darwin_#{arch}.tar.gz"
  name "Sematext Agent (beta)"
  desc "Beta channel of the Sematext Agent: release candidates and stable releases"
  homepage "https://sematext.com/docs/agents/sematext-agent/"

  livecheck do
    skip "Published by the Sematext Agent release pipeline"
  end

  conflicts_with cask: "sematext-agent"

  binary "st-agent"

  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{staged_path}}/st-agent"]
    # An existing config means this is an upgrade: reinstall the daemon from
    # the new binary. The file is root-only, so only its presence is checked.
    if_path_exists "/opt/spm/properties/infra.properties" do
      # Homebrew runs sudo -E, so pin SPM_ROOT: the check above is for /opt/spm.
      run "{{staged_path}}/st-agent", args: ["macos-service", "install"], sudo: true,
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
    stay in /opt/spm until `brew uninstall --zap sematext/tap/sematext-agent-beta`.
  EOS
end
