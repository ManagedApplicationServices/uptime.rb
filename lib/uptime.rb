require 'yaml'
require 'nokogiri'
require 'open-uri'
require 'terminal-notifier'

APP_PATH   = Dir.pwd
VERSION    = "0.9"
BETA       = true

class Uptime
  UPGRADE_MESSAGE = "Warning: Uptime.rb requires Mountain Lion and above. Please upgrade your operating system.\n\n"

  COMMANDS    = {
    "--install"    => :install,
    "--uninstall"  => :uninstall,
    "--help"       => :help,
    "--copyright"  => :copyright,
    "--version"    => :version,
    nil            => :monitor
  }

  attr_accessor :arguments, :config, :url

  def set_url
    @url = "http://api.uptimerobot.com/getMonitors/?apiKey=#{@config["UPTIME_ROBOT"]["API_KEY"]}"
  end

  def config_file
    File.join(APP_PATH, "config", "config.yml")
  end

  def load_config
      @config = YAML::load_file(config_file) if File.exist?(config_file)
  end

  def initialize args = []
    @arguments = args
    load_config
    set_url
    self
  end

  def notify! monitor = {}
    if TerminalNotifier.available?
      message  = "#{monitor[:url]}"
      title    = "#{monitor[:friendly_name]} is down"
      group    = Process.pid
      subtitle = 'Monitor alert'

      TerminalNotifier.notify(message, title: title, group: group, subtitle: subtitle)
      #`terminal-notifier -group 'uptime-alert' -title "#{monitor[:friendly_name]} is down" -subtitle 'Monitor alert' -message "#{monitor[:url]}"` rescue puts  "#{monitor[:friendly_name]} is down"
      sleep 3
    end
  end

  def monitor
    doc = Nokogiri::XML(open(@url))
    doc.xpath("//monitor").each do |item|
      notify! friendly_name: item['friendlyname'], url: item['url'] if item['status'] != "2"
    end
  end

  def banner
    log "\n"
    log "Uptime.rb, version #{self.version_string} - A UptimeRobot.com OS X notifier"
    log "Copyright © 2014 Sam Hon \n\n"
  end

  def copyright
    self.banner
    puts <<-text
    The MIT License (MIT)

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
    THE SOFTWARE.

    text
  end

  def install
    `whenever --update-crontab`
  end

  def uninstall
    `whenever --clear-crontab`
  end

  def help
    self.banner
    puts "Usage: uptime.rb"
    puts "  --help           print this message"
    puts "  --install        install cron scheduled task"
    puts "  --uninstall      remove cron scheduled task"
    puts "  --copyright      print the copyright message"
    puts "  --version        print the version number"
    puts "\n\n"
  end

  def version
    puts self.version_string
  end

  def version_string
    "#{VERSION} #{"[beta]" if BETA}"
  end

  def os_compatible?
    (/darwin/ =~ RUBY_PLATFORM) && os_version > 11
  end

  def os_version
    RUBY_PLATFORM.match(/\d+\.\d*$/).to_s.to_i
  end

  def show_upgrade_os
    self.banner
    log Uptime::UPGRADE_MESSAGE
  end

  def preflight
    if os_compatible?
      self.send(COMMANDS[@arguments.first])
    else
      self.show_upgrade_os
    end
  end

  private

  def log(message)
    puts message unless ENV['RUBY_ENV'] == 'test'
  end
end