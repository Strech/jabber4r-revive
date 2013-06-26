# coding: utf-8

require "bundler/gem_tasks"
require "pty"

# ============================== Support =======================================

ROOT_PATH = File.expand_path("..", __FILE__)
VERSION_PATH = File.join(ROOT_PATH, "lib", "jabber4r", "version.rb")
CHANGELOG_PATH = File.join(ROOT_PATH, "CHANGELOG")

# get current version from version.rb file
def current_version
  version = File.read(VERSION_PATH).gsub(/[^\d\.]+/, "").strip.chomp
end

# get released version from git
def released_version
  /\Av([\d\.]+)\z/ === `git describe --tags --abbrev=0 2>/dev/null || echo 'v0.0.0'`.chomp.strip

  $1
end

# run +cmd+ in subprocess, redirect its stdout to parent's stdout
def spawn(cmd, stdout = STDOUT)
  puts ">> #{cmd}"

  cmd += ' 2>&1'
  PTY.spawn cmd do |r, w, pid|
    begin
      r.sync
      r.each_char { |chr| stdout.write(chr) }
    rescue Errno::EIO => e
      # simply ignoring this
    ensure
      ::Process.wait pid
    end
  end
  abort "#{cmd} failed" unless $? && $?.exitstatus == 0
end

# =============================== Tasks ========================================

namespace :version do
  task :current do
    puts current_version
  end

  desc "Release new version"
  task release: [:changelog, :commit, :tag]

  desc "Add new version to git repo"
  task :commit do
    spawn "git add '#{VERSION_PATH}'"
    spawn "git diff --cached --exit-code > /dev/null || git commit -m \"Release #{current_version}\" || echo -n"
  end

  desc "Add git tag for new version"
  task :tag do
    spawn "git tag v#{current_version}"
  end

  desc "Generate file CHANGELOG"
  task :changelog do
    spawn "changelogger changelog '#{ROOT_PATH}' --top_version='v#{current_version}' > '#{CHANGELOG_PATH}'"
    spawn "git add '#{CHANGELOG_PATH}'"
  end
end

desc "Show current version"
task version: "version:current"