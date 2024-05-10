require ENV['TM_SUPPORT_PATH'] + '/lib/tm/process'

module Linter
  extend Logging::ClassMethods

  TM_PYRUFF_OPTIONS = ENV["TM_PYRUFF_OPTIONS"]
  TM_FILENAME = ENV["TM_FILENAME"]
  TM_FILEPATH = ENV["TM_FILEPATH"]

  module_function
  
  def check_errors(err)
    return if err.nil?
    return if err.empty?

    if err.start_with?("ruff failed")
      Storage.add(err.split("\n"))
      Helpers.alert :title => "Error", :message => err
    end

    if err.start_with?("error:")
      errors = err.split("\n")
      Storage.add(errors)

      first_line = errors.first
      match = first_line.match(/.+?parse at (\d+):(\d+): (.+)/)
      if match
        line_number = match[1]
        column_number = match[2]
        message = match[3]

        Helpers.set_marker "warning", line_number, message
        Helpers.alert :title => "Error", :message => message, :line => "#{line_number}:#{column_number}"
      else
        Helpers.alert :title => "Error", :message => errors.join("\n")
      end
    end
    
    if err.start_with?("warning:")
      errors = err.split("\n")
      Storage.add(errors)
      Helpers.alert :title => "Warning", :message => err
    end
  end

  def run(options={})
    cmd = options[:cmd]
    input = options[:input]
    args = options[:args]

    if input.nil?
      return TextMate::Process.run(cmd, args, TM_FILEPATH)
    else
      return TextMate::Process.run(cmd, args, :input => input)
    end
  end
  
  def sort_imports(options={})
    cmd = options[:cmd]
    input = options[:input]
    args = ["check", "--select", "I", "--fix", "-"]

    logger.debug "sort_imports | args: #{args.inspect}"
    
    out, err = run :cmd => cmd, :input => input, :args => args
    
    logger.debug "sort_imports - err: #{err.inspect} - nil? #{err.nil?}"
    check_errors(err)
    logger.info "sort_imports - returned from check_errors"
    return out
  end
  
  def format_code(options={})
    cmd = options[:cmd]
    input = options[:input]
    args = ["format", "-"]
    
    logger.debug "format_code | args: #{args.inspect}"

    out, err = run :cmd => cmd,
                   :input => input,
                   :args => args
    
    logger.debug "format_code - err: #{err.inspect} - nil? #{err.nil?}"
    check_errors(err)
    logger.info "format_code - returned from check_errors"
    return out
  end
  
  def autofix(options={})
    cmd = options[:cmd]
    input = options[:input]

    args = [
      "check",
      "--fix",
      "--output-format", "grouped",
      "--stdin-filename", TM_FILENAME,
      "-",
    ]

    logger.debug "autofix | args: #{args.inspect}"

    out, err = run :cmd => cmd,
                   :input => input,
                   :args => args

   logger.debug "autofix - err: #{err.inspect} - nil? #{err.nil?}"
   check_errors(err)
   logger.info "autofix - returned from check_errors"
   return out
  end
  
  def noqalize(options={})
    cmd = options[:cmd]
    args = ["check", "--add-noqa"]

    logger.debug "noqalize | args: #{args.inspect}"

    out, err = run :cmd => cmd, :args => args

    logger.debug "noqalize - out: #{out}, empty? #{out.empty?}"
    logger.debug "noqalize - err: #{err.inspect} - nil? #{err.nil?}"

    Helpers.exit_boxify_tool_tip("🎉 #{err.chomp} 👍") if out.empty?
  end
  
  def check(options={})
    cmd = options[:cmd]
    args = ["check", "--output-format", "grouped"]
    document_line_count = options[:document_line_count]

    unless TM_PYRUFF_OPTIONS.nil?
      ruff_options = TM_PYRUFF_OPTIONS.split(" ")
      args.concat(ruff_options)
      logger.debug "check - ruff_options: #{ruff_options.inspect}"
    end
    
    logger.debug "check | args: #{args.inspect}"

    out, err = run :cmd => cmd, :args => args

    logger.debug "check - err: #{err.inspect} - nil? #{err.nil?}"

    result = parse_out(out)
    Helpers.set_markers("error", result[:mark_errors])
    display_result(result, document_line_count)
  end
  
  def pad_number(lines_count, line_number)
    padding = lines_count.to_s.length
    padding = 2 if lines_count < 10
    return sprintf("%0#{padding}d", line_number)
  end
  
  def display_result(result, line_count)
    Helpers.exit_boxify_tool_tip("🎉 congrats! \"#{TM_FILENAME}\" has zero errors 👍") if result[:mark_errors].size == 0
    
    Storage.destroy(true)
    
    output = []
    go_to_errors = []
    
    default_errors_count = result[:default_errors].size
    fixable_errors_count = result[:fixable_errors].size
    total_count = default_errors_count + fixable_errors_count

    output << "⚠️ Found #{total_count} #{Helpers.pluralize(total_count, "error")}! ⚠️\n"
    output << "🔍 Use Option ( ⌥ ) + G to jump error line!\n"
    
    if default_errors_count > 0
      output << "[#{default_errors_count}] default #{Helpers.pluralize(default_errors_count, "error")}:"
      result[:default_errors].sort_by{|err| err[:line_number]}.each do |err|
        output << "  - #{err[:line_number]} -> #{err[:message]}"
        fmt_ln = pad_number(line_count, err[:line_number])
        fmt_cn = pad_number(line_count, err[:column_number])
        go_to_errors << "#{fmt_ln}:#{fmt_cn} | #{err[:message]}"
      end
    end

    output << "" if fixable_errors_count > 0

    if fixable_errors_count > 0
      output << "[#{fixable_errors_count}] fixable #{Helpers.pluralize(fixable_errors_count, "error")}:"
      result[:fixable_errors].sort_by{|err| err[:line_number]}.each do |err|
        output << "  - #{err[:line_number]} -> #{err[:message]}"
        fmt_ln = pad_number(line_count, err[:line_number])
        fmt_cn = pad_number(line_count, err[:column_number])
        go_to_errors << "#{fmt_ln}:#{fmt_cn} | #{err[:message]}"
      end
    end
    
    output << "" if result[:extras].size > 0
    
    output.concat(result[:extras]) if result[:extras].size > 0
    
    Storage.add(go_to_errors, true) if go_to_errors
    
    Helpers.exit_boxify_tool_tip(output.join("\n"))
  end
  
  def parse_out(out)
    input = out.split("\n")

    mark_errors = {}
    default_errors = []
    fixable_errors = []
    extras = []
    
    if input.first.include?(TM_FILENAME)
      input[1..-1].each do |line|
        if line.start_with?(" ")
          match = line.match(/(\d+):(\d+)\s+(\w+)\s+(\[\*\]\s+)?(.+)/)
          if match
            line_number = match[1].to_i
            column_number = match[2].to_i
            code = match[3]
            fixable = !match[4].nil?
            message = match[5].strip
            
            mark_errors[line_number] = [] unless mark_errors.has_key?(line_number)
            error = {
              :line_number => line_number,
              :column_number => column_number,
              :code => code,
              :fixable => fixable,
              :message => "[#{code}]: #{message}",
            }
            mark_errors[line_number] << error
            if fixable
              fixable_errors << error
            else
              default_errors << error
            end
          end
        else
          extras << line unless line.empty?
        end
      end
    end
    
    return {
      :mark_errors => mark_errors,
      :default_errors => default_errors,
      :fixable_errors => fixable_errors,
      :extras => extras,
    }
  end
end