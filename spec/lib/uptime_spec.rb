require 'spec_helper'


describe Uptime do
  before do
    allow_any_instance_of(Uptime).to receive(:config_file).and_return(SPEC_CONFIG)
  end

  context "when the uptime object is initialized" do
    it "accepts a set of arguments" do
      args   = ["just","an","array","of","arguments"]
      uptime = Uptime.new(args)
      expect(uptime.arguments).to eq args
    end
  end

  context "when the operating system is compatible" do
    before do
      # Force compatibility
      allow_any_instance_of(Uptime).to receive(:delay).and_return(true)
      allow_any_instance_of(Uptime).to receive(:os_compatible?).and_return(true)
      allow(TerminalNotifier::Guard).to receive(:available?).and_return(true)
    end

    #   This spec will test the following commands:
    #   "--install"    => :install,
    #   "--uninstall"  => :uninstall,
    #   "--help"       => :help,
    #   "--copyright"  => :copyright,
    #   "--version"    => :version,
    #   nil            => :monitor
    #
    #   This test is written such a way that it is future proof to newer COMMANDS

    Uptime::COMMANDS.each_pair do |command, method_name|
      it "processes the #{command || 'monitoring feature without an'} argument" do
        expect_any_instance_of(Uptime).to receive(method_name)
        Uptime.new([command]).preflight
      end
    end

    it "constructs the uptime robot api url with the config yaml api key" do
      uptime = Uptime.new
      expect(uptime.url).to match(/REPLACE-THIS-WITH-THE-ACTUAL-KEY/)
    end

    it "constructs the uptime robot api url using https protocol" do
      uptime = Uptime.new
      expect(uptime.url).to match(/http:\/\/api.uptimerobot.com\/getMonitors\/\?apiKey=/)
    end

    it "calls the uptime robot api" do
      uptime = Uptime.new
      expect(uptime).to receive(:open).with(uptime.url).and_return([])
      expect(Nokogiri::XML::Document).to receive(:parse).and_return(Nokogiri::XML(open(FAKE_XML_PATH)))
      expect_any_instance_of(Nokogiri::XML::Document).to receive(:xpath).and_return([])
      uptime.preflight
    end

    it "parses the results and attempt to call terminal-notifier if the server being monitored is down" do
      uptime = Uptime.new
      expect(uptime).to receive(:open).with(uptime.url).and_return([])
      expect(Nokogiri::XML::Document).to receive(:parse).and_return(Nokogiri::XML(File.read(FAKE_XML_PATH)))
      expect(uptime).to receive(:notify!).with({friendly_name: "DOWN Server", url: "https://down.example.com"})
      uptime.preflight
    end

    it "calls the failed method on terminal-notifier if the server being monitored is down" do
      uptime = Uptime.new
      expect(uptime).to receive(:open).with(uptime.url).and_return([])
      expect(uptime).to receive(:delay).with(3).and_return(true)
      expect(Nokogiri::XML::Document).to receive(:parse).and_return(Nokogiri::XML(File.read(FAKE_XML_PATH)))
      expect(TerminalNotifier::Guard).to receive(:failed).and_return(true)
      uptime.preflight
    end

  end

  context "when the operating system is not compatible" do
    before do
      allow_any_instance_of(Uptime).to receive(:os_compatible?).and_return(false)
    end
    it "displays the upgrade operating system message" do
      expect_any_instance_of(Uptime).to receive(:show_upgrade_os).and_call_original
      expect_any_instance_of(Uptime).to receive(:banner)
      expect_any_instance_of(Uptime).to receive(:log).with(Uptime::UPGRADE_MESSAGE)
      Uptime.new.preflight
    end

    #   This spec will test the following commands:
    #   "--install"    => :install,
    #   "--uninstall"  => :uninstall,
    #   "--help"       => :help,
    #   "--copyright"  => :copyright,
    #   "--version"    => :version,
    #   nil            => :monitor
    #
    #   This test is written such a way that it is future proof to newer COMMANDS

    Uptime::COMMANDS.each_pair do |command, method_name|
      it "does not process the #{command || 'empty'} argument" do
        expect_any_instance_of(Uptime).not_to receive(method_name)
        Uptime.new([command]).preflight
      end
    end
  end
end