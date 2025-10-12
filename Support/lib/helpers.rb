require ENV['TM_SUPPORT_PATH'] + '/lib/exit_codes'

require ENV["TM_BUNDLE_SUPPORT"] + "/lib/constants"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/storage"

class String
  def tokenize
    self.
      split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/).
      select {|s| not s.empty? }.
      map {|s| s.gsub(/(^ +)|( +$)|(^["']+)|(["]+$)/, '')}
  end
end

module Helpers
  include Constants

  extend Storage

  module_function
  
  def pluralize(n, singular, plural=nil)
    return plural.nil? ? singular + "s" : plural if n > 1
    return singular
  end

  def goto(line)
    system(ENV["TM_MATE"], "--uuid", TM_DOCUMENT_UUID, "--line", line)
  end
  
  def reset_markers
    system(
      ENV["TM_MATE"],
      "--uuid", TM_DOCUMENT_UUID,
      "--clear-mark=note",
      "--clear-mark=warning",
      "--clear-mark=error"
    )
  end

  def set_marker(mark, line, msg)
    unless line.nil?
      tm_args = [
        '--uuid', TM_DOCUMENT_UUID,
        '--line', "#{line}",
        '--set-mark', "#{mark}:#{msg}",
      ]
      system(ENV['TM_MATE'], *tm_args)
    end
  end

  def set_markers(mark, errors_list)
    errors_list.each do |line_number, errors|
      messages = []

      errors.each do |data|
        messages << "#{data[:message]}"
      end

      set_marker(mark, line_number, messages.join("\n"))
    end
  end

  def exit_discard
    TextMate.exit_discard
  end

  def chunkify(s, max_len, left_padding)
    out = []
    s.split("\n").each do |line|
      if line.size > max_len
        words_matrix = []
        words_matrix_index = 0
        words_len = 0
        line.split(" ").each do |word|
          unless words_matrix[words_matrix_index].nil?
            words_len = words_matrix[words_matrix_index].join(" ").size
          end
          if words_len + word.size < max_len
            words_matrix[words_matrix_index] = [] if words_matrix[words_matrix_index].nil?
            words_matrix[words_matrix_index] << word
          else
            words_matrix_index = words_matrix_index + 1
            words_matrix[words_matrix_index] = [] if words_matrix[words_matrix_index].nil?
            words_matrix[words_matrix_index] << word
          end
        end
        
        rows = []
        padding_word = " " * left_padding
        words_matrix.each do |row|
          rows << "#{padding_word}#{row.join(" ")}" 
        end
        out << rows.join("\n#{padding_word}↪")
      else
        out << line
      end
    end
    out.join("\n")
  end

  def boxify(txt)
    s = chunkify(txt, TOOLTIP_LINE_LENGTH.to_i, TOOLTIP_LEFT_PADDING.to_i)
    s = s.split("\n")
    ll = s.map{|l| l.size}.max || 1
    lsp = TOOLTIP_BORDER_CHAR * ll
    s.unshift(lsp)
    s << lsp
    s = s.map{|l| "  #{l}  "}
    s.join("\n")
  end

  def exit_boxify_tool_tip(msg)
    TextMate.exit_show_tool_tip(boxify(msg))
  end

  def pad_number(lines_count, line_number)
    padding = lines_count.to_s.length
    padding = 2 if lines_count < 10
    return sprintf("%0#{padding}d", line_number)
  end

  def check_errors(err, store=false)
    all_checks_passed = "All checks passed!" 
    if err.nil? || 
       err.empty? || 
       err.start_with?(all_checks_passed) ||
       err.start_with?("Found 1 error (1 fixed, 0 remaining)")
       return nil
    end

    if err.start_with?("ruff failed") && store
      errors = ["Critical error:\n"] + err.split("\n")
      create_storage(errors)
      logger.error "#{errors.inspect}"
      return errors
    end
    
    if err.start_with?("warning:")
      errors = ["You must fix this warning to continue:\n"] + err.split("\n")
      create_storage(errors)
      logger.error "#{errors.inspect}"
      return errors
    end

    if err.start_with?("error:")
      original_errors = err.split("\n")
      errors = ["Error\n"] + original_errors
      errors.delete(all_checks_passed) if errors.include?(all_checks_passed)
      create_storage(errors)
      logger.error "#{errors.inspect}"

      match = original_errors.first.match(/^.+?(\d+):(\d+):\s(.+)$/)
      if match
        line_number = match[1]
        column_number = match[2]
        message = match[3]
        
        set_marker "warning", line_number, message
        goto "#{line_number}:#{column_number}"
      end

      return errors
    end

    return nil
  end

  def display_result(result, line_count)
    ruff_version = `ruff --version`.chomp
    
    if result[:mark_errors].size == 0
      success_msg = [
        "🎉 congrats! \"#{TM_FILENAME}\" has zero errors 👍",
        "",
        "🧩 ruff version: #{ruff_version}",
        "⚙️ config:",
        "#{get_ruff_config_arg}",
      ]
      exit_boxify_tool_tip(success_msg.join("\n"))
    end
    
    destroy_storage(true)
    
    output = []
    go_to_errors = []
    
    default_errors_count = result[:default_errors].size
    fixable_errors_count = result[:fixable_errors].size
    total_count = default_errors_count + fixable_errors_count

    output << "⚠️ Found #{total_count} #{pluralize(total_count, "error")}! ⚠️\n"
    output << "🔍 Use Option ( ⌥ ) + G to jump error line!"
    output << "📋 Use Option ( ⌥ ) + R to display error report!"
    output << "🔄 Use Option ( ⌥ ) + A to noqalize all problematic lines"
    output << "🛠️ Use Option ( ⌥ ) + F to autofix autofixables"
    output << ""
    output << "🧩 ruff version: #{ruff_version}"
    output << "⚙️ config:"
    output << "#{get_ruff_config_arg}"
    output << ""
    
    if default_errors_count > 0
      output << "[#{default_errors_count}] default #{pluralize(default_errors_count, "error")}:"
      result[:default_errors].sort_by{|err| err[:line_number]}.each do |err|
        output << "  - #{err[:line_number]} -> #{err[:message]}"
        fmt_ln = pad_number(line_count, err[:line_number])
        fmt_cn = pad_number(line_count, err[:column_number])
        go_to_errors << "#{fmt_ln}:#{fmt_cn} | #{err[:message]}"
      end
    end

    output << "" if fixable_errors_count > 0

    if fixable_errors_count > 0
      output << "[#{fixable_errors_count}] fixable #{pluralize(fixable_errors_count, "error")}:"
      result[:fixable_errors].sort_by{|err| err[:line_number]}.each do |err|
        output << "  - #{err[:line_number]} -> #{err[:message]}"
        fmt_ln = pad_number(line_count, err[:line_number])
        fmt_cn = pad_number(line_count, err[:column_number])
        go_to_errors << "#{fmt_ln}:#{fmt_cn} | #{err[:message]}"
      end
    end
    
    output << "" if result[:extras].size > 0
    
    output.concat(result[:extras]) if result[:extras].size > 0
    
    create_storage(go_to_errors, true) if go_to_errors
    
    exit_boxify_tool_tip(output.join("\n"))
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

  def get_ruff_config_file
    config_file = File.join(TM_PROJECT_DIRECTORY, ".ruff.toml")
    return config_file if File.exists?(config_file)
    return nil
  end

  def get_ruff_extra_options
    unless TM_PYRUFF_OPTIONS.nil?
      ruff_options = TM_PYRUFF_OPTIONS.tokenize
      logger.debug "ruff_options: #{ruff_options.inspect}"
      return ruff_options
    end
    return nil
  end
  
  def get_ruff_config_arg
    config_arg = get_ruff_extra_options
    config_arg = get_ruff_config_file if get_ruff_config_file
    return config_arg
  end
end