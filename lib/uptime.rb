require 'yaml'
require 'nokogiri'
require 'open-uri'

APP_PATH   = Dir.pwd
VERSION    = "0.9"
BETA       = true

class Uptime
  LAST_ITEM   = ".last_item"
  CONFIG_FILE = File.join(APP_PATH, "config", "config.yml")
  CONFIG      = YAML::load_file(CONFIG_FILE)
  URL         = "http://api.uptimerobot.com/getMonitors/?apiKey=#{CONFIG["UPTIME_ROBOT"]["API_KEY"]}"

  COMMANDS    = {
    "--install"    => :install,
    "--uninstall"  => :uninstall,
    "--help"       => :help,
    "--copyright"  => :copyright,
    "--version"    => :version,
    nil            => :monitor
  }

  def monitor
    doc = Nokogiri::XML(open(URL))
    doc.xpath("//monitor").each do |item|
      if item['status'] != "2"
        `terminal-notifier -group 'mas-alert' -title "#{item['friendlyname']} is down" -subtitle 'Monitor alert' -message "#{item['url']}"` rescue puts  "#{item['friendlyname']} is down"
        sleep 3
      end
    end
  end

  def banner
    puts"\n"
    puts "Uptime.rb, version #{self.version_string} - A UptimeRobot.com OS X notifier"
    puts "Copyright © 2014 Sam Hon \n\n"
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
    puts "Warning: Uptime.rb requires Mountain Lion and above. Please upgrade your operating system.\n\n"
  end

  def preflight
    if os_compatible?
      self.send(COMMANDS[ARGV.first])
    else
      self.show_upgrade_os
    end
  end
end