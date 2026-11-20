cask "sematext-agent" do
  arch arm: "arm64", intel: "amd64"

  version "4.7.0"
  sha256 arm:   "6d1d079132185652a49f4c9ff0fded9d9782b147a57eb53a9b97f9252e9f1b10",
         intel: "9e484d4eebf716ab88d7cbcbe15e199b82aafee3d698116fbeb9e90da92c82ad"

  url "https://pub-repo.sematext.com/macos/sematext-agent/#{version}/st-agent_#{version}_darwin_#{arch}.tar.gz"
  name "Sematext Agent"
  desc "Collects host, process and service metrics for Sematext Cloud"
  homepage "https://sematext.com/docs/agents/sematext-agent/"

  livecheck do
    skip "Published by the Sematext Agent release pipeline"
  end

  conflicts_with cask: "sematext-agent-beta"

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
    stay in /opt/spm until `brew uninstall --zap sematext/tap/sematext-agent`.
  EOS
end
