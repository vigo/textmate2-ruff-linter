require ENV['TM_SUPPORT_PATH'] + '/lib/tm/process'
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/logger"

module RuffLinter
  include Logging

  TM_PYRUFF = ENV["TM_PYRUFF"] || `command -v ruff`.chomp

  module_function

  def report
    input = STDIN.read
    cmd = TM_PYRUFF
    args = ["check", "--output-format", "grouped"]
    out, err = TextMate::Process.run(cmd, args, :input => input)
    print out
    puts "---"
    print err
    puts "---"
  end
end