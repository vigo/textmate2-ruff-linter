require ENV['TM_SUPPORT_PATH'] + '/lib/tm/process'

require ENV["TM_BUNDLE_SUPPORT"] + "/lib/constants"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/logger"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/storage"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/helpers"

module Linter
  extend Logging::ClassMethods
  extend Storage
  extend Helpers

  module_function

  def run(options={})
    cmd = Constants::TM_PYRUFF
    input = options[:input]
    args = options[:args]
    
    logger.debug "cmd: #{cmd} | nil input: #{input.nil?} | args: #{args.inspect} | input: #{input.nil? ? Constants::TM_FILEPATH : "input"}"
    
    if input.nil?
      return TextMate::Process.run(cmd, args, Constants::TM_FILEPATH)
    else
      return TextMate::Process.run(cmd, args, :input => input)
    end
  end

  def sort_imports(options={})
    input = options[:input]
    args = ["check", "--select", "I", "--fix", "-"]

    out, err = run :input => input, :args => args

    errors = check_errors(err, true)
    out = input unless errors.nil?
    return out, errors
  end
  
  def format_code(options={})
    input = options[:input]
    
    args = ["format"]

    unless Constants::TM_PYRUFF_OPTIONS.nil?
      ruff_options = Constants::TM_PYRUFF_OPTIONS.tokenize
      logger.debug "ruff_options: #{ruff_options.inspect}"
      args += ruff_options
    end

    args << "-"

    out, err = run :input => input,
                   :args => args

    errors = check_errors(err, true)
    out = input unless errors.nil?
    return out, errors
  end
  
  def autofix(options={})
    input = options[:input]

    args = [
      "check",
      "--fix",
      "--output-format", "grouped",
      "--stdin-filename", Constants::TM_FILENAME,
      "-",
    ]

    out, err = run :input => input,
                   :args => args

    errors = check_errors(err, true)
    out = input unless errors.nil?
    return out, errors
  end
  
  def noqalize(options={})
    args = ["check", "--add-noqa"]

    out, err = run :args => args

    logger.warn "noqalize err: #{err.inspect}"
    exit_boxify_tool_tip("🎉 #{err.chomp} 👍") if out.empty?
  end
  
  def check(options={})
    args = ["check", "--output-format", "grouped"]
    document_line_count = options[:document_line_count]

    unless Constants::TM_PYRUFF_OPTIONS.nil?
      ruff_options = Constants::TM_PYRUFF_OPTIONS.tokenize
      logger.debug "ruff_options: #{ruff_options.inspect}"
      args += ruff_options
    end
    
    out, err = run :args => args

    exit_boxify_tool_tip(err) if out.empty? || err.start_with?("error")

    result = parse_out(out)
    set_markers("error", result[:mark_errors])
    display_result(result, document_line_count)
  end
end
