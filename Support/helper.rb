#!/usr/bin/env ruby18 -W0

require 'logger'

# require ENV['TM_SUPPORT_PATH'] + '/lib/exit_codes'
# require ENV['TM_SUPPORT_PATH'] + '/lib/textmate'
require ENV['TM_SUPPORT_PATH'] + '/lib/tm/executor'
# require ENV['TM_SUPPORT_PATH'] + '/lib/tm/process'

$CMD = nil

STORAGE_FILE_PREFIX = "/tmp/textmate-python-ruff-"
LOG_FILE = "/tmp/textmate-python-ruff.log"
LOG_PROGNAME = "Python-RUFF"

module Configuration
  TM_PROJECT_DIRECTORY = ENV["TM_PROJECT_DIRECTORY"]
  TM_FILENAME = ENV["TM_FILENAME"]

  TOOLTIP_LINE_LENGTH = ENV["TM_PYRUFF_TOOLTIP_LINE_LENGTH"] || "100"
  TOOLTIP_LEFT_PADDING = ENV["TM_PYRUFF_TOOLTIP_LEFT_PADDING"] || "2"
  TOOLTIP_BORDER_CHAR = ENV["TM_PYRUFF_TOOLTIP_BORDER_CHAR"] || "-"
  
  ENABLE_LOGGING = !ENV["ENABLE_LOGGING"].nil?
  TM_PYRUFF_DISABLE = ENV["TM_PYRUFF_DISABLE"].nil?
  TM_PYRUFF_ENABLE_AUTOFIX = !ENV["TM_PYRUFF_ENABLE_AUTOFIX"].nil?
  TM_PYRUFF_OPTIONS = ENV["TM_PYRUFF_OPTIONS"]

  def self.logging_enabled?
    ENABLE_LOGGING
  end
end


module LoggingUtility
  BLACK            = "\e[30m"
  RED              = "\e[31m"
  RED_BOLD         = "\e[01;31m"
  GREEN            = "\e[32m"
  GREEN_BOLD       = "\e[01;32m"
  YELLOW           = "\e[33m"
  YELLOW_BOLD      = "\e[01;33m"
  BLUE             = "\e[34m"
  BLUE_BOLD        = "\e[01;34m"
  MAGENTA          = "\e[35m"
  MAGENTA_BOLD     = "\e[01;35m"
  CYAN             = "\e[36m"
  CYAN_BOLD        = "\e[01;36m"
  WHITE            = "\e[37m"
  WHITE_BOLD       = "\e[01;37m"
  EXTENDED         = "\e[38m"
  BLINK            = "\e[5m"
  OFF              = "\e[0m"
  
  def severity_color(severity)
    case severity
    when "DEBUG" then BLUE
    when "INFO" then GREEN
    when "WARN" then YELLOW
    when "ERROR" then RED
    when "FATAL" then MAGENTA
    when "UNKNOWN" then BLINK
    end
  end
  
  module_function :severity_color
  
  def self.logger
    if Configuration.logging_enabled?
      @logger = Logger.new(LOG_FILE)
      @logger.level = Logger::DEBUG
      @logger.progname = LOG_PROGNAME
      @logger.formatter = proc do |severity, _, progname, msg|
        color_code = severity_color(severity)
        caller_info = caller(5).first
        method_name = caller_info.match(/`([^']*)'/) ? caller_info.match(/`([^']*)'/)[1] : "unknown"
        "[#{WHITE_BOLD}#{progname}#{OFF}][#{color_code}#{severity}#{OFF}][#{CYAN_BOLD}#{method_name}#{OFF}]: #{msg}\n"
      end
    else
      @logger = Logger.new(nil)
    end
    @logger
  end
end


module Storage
  def self.file_path(name)
    "#{STORAGE_FILE_PREFIX}#{name}.error"
  end

  def self.add(name, error_message)
    File.open(file_path(name), 'w') do |file|
      file.puts error_message
    end
    logger.info "storage - adding error for #{name}"
  end

  def self.get(name)
    path = file_path(name)
    if File.exist?(path)
      logger.info "storage - error file exists for #{name}"
      File.open(path, 'r') do |file|
        return file.read
      end
    end
    nil
  end

  def self.destroy(name)
    path = file_path(name)
    if File.exist?(path)
      File.delete(path)
      logger.info "storage - destroyed error file for #{name}"
    end
  end
  
  def logger
    LoggingUtility.logger
  end
  
  module_function :logger
end


module Ruff
  include Configuration
  include LoggingUtility
  include Storage
  
  @document = nil
  
  module_function
  
  def read_stdin
    @document = STDIN.read
  end  

  def document
    @document
  end

  def document=(value)
    @document = value
  end
  
  def document_empty?
    document.nil? || document.empty? || document.match(/\S/).nil?
  end

  def reset_markers
    system(ENV["TM_MATE"], "--uuid", ENV["TM_DOCUMENT_UUID"], "--clear-mark=note",
                                                              "--clear-mark=warning",
                                                              "--clear-mark=error"
    )
  end

  def set_marker(mark, line, msg)
    unless line.nil?
      tm_args = [
        '--uuid', ENV['TM_DOCUMENT_UUID'],
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
  
  def display_err(msg)
    TextMate.exit_show_tool_tip(boxify(msg))
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

  def bundle_enabled?
    TM_PYRUFF_DISABLE
  end
  
  def logger
    LoggingUtility.logger
  end
  
  def setup_ok?
    cmd = `command -v ruff`.chomp
    if cmd.empty?
      logger.warn "ruff binary not found"
      return false, "ruff binary not found"
    end
    $CMD = cmd
    return true, "SETUP OK"
  end
  
  def any_config_file_exist?
    ["pyproject.toml", "ruff.toml"].each do |config|
      return true if File.exist?(File.join(TM_PROJECT_DIRECTORY, config))
    end
    return false
  end
  
  def run_ruff(subcmd)
    cmd = $CMD
    logger.info "cmd: #{cmd}"

    args = ["--output-format", "grouped"]
    
    if TM_PYRUFF_OPTIONS && any_config_file_exist?
      opts = TM_PYRUFF_OPTIONS.split(" ")
      logger.debug "opts: #{TM_PYRUFF_OPTIONS}"
      args.concat(opts)
    end
    
    case subcmd
    when "check"
      args.unshift("check")
    when "autofix"
      args.unshift("check")
      args.concat(["--fix", "--stdin-filename", ENV['TM_FILENAME'], "-"])
    when "imports"
      args.unshift("check")
      args.concat(["--select", "I", "--fix", "--stdin-filename", ENV['TM_FILENAME'], "-"])
    when "noqalize"
      args = ["check", "--add-noqa"]
    end

    cmd_version = `#{cmd} --version`.chomp
    logger.debug "cmd: #{cmd} | version: #{cmd_version} | args: #{args.join(" ")}"

    case subcmd
    when "check","noqalize"
      result, err = TextMate::Process.run(cmd, args, ENV['TM_FILEPATH'])
    when "autofix", "imports"
      result, err = TextMate::Process.run(cmd, args, :input => document)
    end

    unless err.empty?
      logger.error "run has an error on #{subcmd}: #{err}"
    end
    return result, err
  end
  
  def noqalize_all
    logger.info "running noqalize_all"
    reset_markers

    TextMate.exit_discard unless bundle_enabled?
    read_stdin

    TextMate.exit_discard if document_empty?
    TextMate.exit_discard if document.split("\n").first.include?("# TM_PYRUFF_DISABLE")

    ok, err = setup_ok?
    display_err(err) unless ok

    result, err = run_ruff("noqalize")
    logger.info "noqalize err: #{err}, #{err.empty?}"
    display_err(err)
  end
  
  # callback.document.will-save.50
  def auto_fix_errors(manual=false)
    logger.info "running auto_fix_errors"
    reset_markers

    TextMate.exit_discard unless bundle_enabled?
    read_stdin

    TextMate.exit_discard if document_empty?
    TextMate.exit_discard if document.split("\n").first.include?("# TM_PYRUFF_DISABLE")

    ok, err = setup_ok?
    display_err(err) unless ok
    
    result, err = run_ruff("imports")
    if err.include?("ruff failed")
      Storage.add("imports", err)
      display_err(err)
    else
      self.document = result
      Storage.destroy("imports")
    end
    
    if TM_PYRUFF_ENABLE_AUTOFIX || manual
      result, err = run_ruff("autofix")
      if err.include?("failed") || err.include?("error")
        Storage.add("autofix", err)
        display_err(err)
      else
        self.document = result
        Storage.destroy("autofix")
      end
    end
    
    print document
  end
  
  # callback.document.did-save.50
  def run_ruff_linter
    logger.info "running run_ruff_linter"

    TextMate.exit_discard unless bundle_enabled?
    read_stdin
    
    TextMate.exit_discard if document_empty?
    TextMate.exit_discard if document.split("\n").first.include?("# TM_PYRUFF_DISABLE")
    
    ok, err = setup_ok?
    display_err(err) unless ok
    
    if !Storage.get("imports").nil?
      logger.info "skip running run_ruff_linter, due to imports error"
      TextMate.exit_discard
    end

    if !Storage.get("autofix").nil?
      logger.info "skip running run_ruff_linter, due to autofix error"
      TextMate.exit_discard
    end
    
    all_errors = {}
    
    result, err = run_ruff("check")

    unless err.empty?
      lerr = "⚠️ possible configuration or parse error ⚠️\n\n#{err}"

      if err.include?(TM_FILENAME)
        regex = /^(\w+):\s+.*#{Regexp.escape(TM_FILENAME)}:(\d+):(\d+)/
        matches = err.match(regex)
        if matches
          mark = matches[1]
          line_number = matches[2]
          set_marker(mark, line_number, err.chomp)
        end
      end
      display_err(lerr)
    end

    extra_information = extract_ruff_errors(result, all_errors)
    set_markers("error", all_errors)
    error_report = generate_error_report(all_errors, extra_information)

    logger.info "run_ruff_linter completed, will popup error_report"
    display_err(error_report.join("\n")) if error_report
  end
  
  def generate_error_report(all_errors, extra_information)
    non_fixable_errors = []
    fixable_errors = []
    
    all_errors.each do |line_number, errors|
      errors.each do |error|
        if error[:fixable]
          fixable_errors << error
        else
          non_fixable_errors << error
        end
      end
    end

    non_fixable_error_count = non_fixable_errors.size
    fixable_error_count = fixable_errors.size
    error_report = []
    
    if all_errors.size == 0
      error_report << "🎉 you have zero errors 👍"
    else
      error_report << "⚠️ found #{non_fixable_error_count+fixable_error_count} error(s) ⚠️"
      error_report << ""
      if non_fixable_error_count > 0
        error_report << "[#{non_fixable_error_count}] non-fixable error(s)"
        non_fixable_errors.each do |err|
          error_report << "  - #{err[:message]} in line: #{err[:line_number]}"
        end
        error_report << ""
      end
      if fixable_error_count > 0
        error_report << "[#{fixable_error_count}] fixable error(s)"
        fixable_errors.each do |err|
          error_report << "  - #{err[:message]} in line: #{err[:line_number]}"
        end
        error_report << ""
      end
    end
    
    error_report.concat(extra_information) if extra_information
    return error_report
  end
  
  def extract_ruff_errors(errors, all_errors)
    extra_information = []

    # skip first line, name of the file.
    errors.split("\n")[1..-1].each do |line|
      if line.start_with?(" ")
        match = line.match(/(\d+):(\d+)\s+(\w+)\s+(\[\*\]\s+)?(.+)/)
        if match
          line_number = match[1].to_i
          column = match[2].to_i
          code = match[3]
          fixable = !match[4].nil?
          message = match[5].strip
          
          all_errors[line_number] = [] unless all_errors.has_key?(line_number)
          all_errors[line_number] << {
            :line_number => line_number,
            :column => column,
            :code => code,
            :fixable => fixable,
            :message => "[#{code}]: #{message}",
            :type => "ruff",
          }
        end
      else
        extra_information << line unless line.include?("Found")
      end
    end

    extra_information
  end
end
