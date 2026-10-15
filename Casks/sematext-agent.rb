cask "sematext-agent" do
  arch arm: "arm64", intel: "amd64"

  version "4.6.1"
  sha256 arm:   "f9cca20211a2345c2fbcc901b5d283eb2dbbb144816d713a128fa3955c66b6fb",
         intel: "ae113f32ed52dd4d8e9d1a1948c7b3566bdde8bad65dd982040101c8f1344417"

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
