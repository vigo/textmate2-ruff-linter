#!/usr/bin/env ruby18 -W0

require ENV['TM_SUPPORT_PATH'] + '/lib/tm/executor'

$DOCUMENT = STDIN.read
$OUTPUT = ""

TOOLTIP_LINE_LENGTH = ENV["TM_PYRUFF_TOOLTIP_LINE_LENGTH"] || "120"
TOOLTIP_LEFT_PADDING = ENV["TM_PYRUFF_RESULT_TM_PYRUFF_TOOLTIP_LEFT_PADDING"] || "20"
TOOLTIP_BORDER_CHAR = ENV["TM_PYRUFF_TOOLTIP_BORDER_CHAR"] || "-"

LINT_SUCCESS_MESSAGE = "all good 👍"
RUFF_NOT_FOUND_MESSAGE = "error, ruff executable not found, please install ruff or set TM_PYRUFF environment variable"
AUTOFIX_ENABLER_MESSAGE = "set TM_PYRUFF_ENABLE_AUTOFIX environment variable to fix automatically"

PYRUFF_DISABLE = ENV["TM_PYRUFF_DISABLE"] || nil
PYRUFF_ENABLE_AUTOFIX = ENV["TM_PYRUFF_ENABLE_AUTOFIX"] || nil
PYRUFF_DEBUG = ENV["TM_PYRUFF_DEBUG"] || nil

CMD = ENV["TM_PYRUFF"] || `command -v ruff`.chomp

module Ruff
  module_function

  def pluralize(n, singular, plural=nil)
    return plural.nil? ? singular + "s" : plural if n > 1
    return singular
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
            words_len = words_matrix[words_matrix_index].join(' ').size
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
        words_matrix.each do |row|
          rows << row.join(" ")
        end
      
        padding_word = " " * left_padding
        out << rows.join("\n" + padding_word)
      else
        out << line
      end
    end
    out.join("\n")
  end

  def boxify(txt)
    s = chunkify(txt, TOOLTIP_LINE_LENGTH.to_i, TOOLTIP_LEFT_PADDING.to_i)
    s = s.split("\n")
    ll = s.map{|l| l.size}.max
    lsp = TOOLTIP_BORDER_CHAR * ll
    s.unshift(lsp)
    s << lsp
    s = s.map{|l| "  #{l}  "}
    s.join("\n")
  end

  def reset_markers
    system(
      ENV["TM_MATE"],
      "--uuid",
      ENV["TM_DOCUMENT_UUID"],
      "--clear-mark=note",
      "--clear-mark=warning",
      "--clear-mark=error"
    )
  end

  def mark_errors(payload)
    out = []
    extra = []

    error_counter = 0
    errors = {}
    
    payload.split("\n").each do |line|
      line = line.sub(ENV["TM_FILENAME"], "")

      chunks = line.split(%r{:(\d+):(\d+):\s([A-Z0-9]+)\s})
      if chunks[0].size == 0
        error_counter = error_counter + 1

        line_number = chunks[1]
        column_number = chunks[2]
        error_code = chunks[3]
        error_message = chunks[4]
        
        errors[line_number] = [] unless errors.has_key?(line_number)
        errors[line_number] << [column_number, error_code, error_message]
        
        out << sprintf(
          "[%03d] %03d:%03d -> %s [%s]",
          error_counter,
          line_number,
          column_number,
          error_message,
          error_code
        )
      else
        extra << line
      end
    end
    
    if extra
      out << ["", extra]
      out << ["", AUTOFIX_ENABLER_MESSAGE] unless PYRUFF_ENABLE_AUTOFIX
    end
    
    error_codes = []
    
    errors.each do |line_number, vals|
      messages = []
      vals.each do |val|
        error_code = val[1]
        error_message = val[2]
        messages << "#{error_code} - #{error_message}"
        error_codes << error_code
      end
      
      tm_args = [
        "--uuid",
        ENV["TM_DOCUMENT_UUID"],
        "--line",
        "#{line_number}",
        "--set-mark",
        "error:#{messages.join("\n")}",
      ]
      system(ENV["TM_MATE"], *tm_args)
    end
    
    return error_counter, out.join("\n"), error_codes
  end

  def show_message(msg)
    if PYRUFF_DEBUG
      TextMate.exit_create_new_document(msg)
    else
      TextMate.exit_show_tool_tip(msg)
    end
  end

  def document_first_line_has_disable_comment(env_name)
    return $DOCUMENT.split('\n').first.include?(env_name)
  end

  def setup
    reset_markers

    TextMate.exit_discard if $DOCUMENT.empty? or PYRUFF_DISABLE
    TextMate.exit_discard if document_first_line_has_disable_comment("TM_PYRUFF_DISABLE")

    show_message(boxify(RUFF_NOT_FOUND_MESSAGE)) if CMD.empty?
  end
  

  def auto_fix_errors
    TextMate.exit_discard unless PYRUFF_ENABLE_AUTOFIX
    setup

    $OUTPUT = $DOCUMENT
    
    show_message(boxify(RUFF_NOT_FOUND_MESSAGE)) if CMD.empty?

    args = ["--fix", "--stdin-filename", ENV["TM_FILENAME"], "-"]
    $OUTPUT, err = TextMate::Process.run(CMD, args, :input => $DOCUMENT)

    show_message(boxify(err)) unless err.empty?

    print $OUTPUT
  end

  def show_rules
    setup

    args = ["--stdin-filename", ENV["TM_FILENAME"], "-"]
    out, err = TextMate::Process.run(CMD, args, :input => $DOCUMENT)
    show_message(err) unless err.empty?
    
    unless out.empty?
      _, _, error_codes = mark_errors(out)
      
      # data = []
      # error_codes.each do |error_code|
      # end
      
      rule_docs = []
      error_codes.each do |error_code|
        args = ["rule", error_code]
        doc, err_doc = TextMate::Process.run(CMD, args)
        show_message(err_doc) unless err_doc.empty?
        rule_docs << doc
        rule_docs << "---"
        rule_docs << ""
      end

      TextMate.exit_create_new_document(rule_docs.join("\n"))
    end
    
  end
  
  def run_ruff_linter
    setup
    
    args = []
    out, err = TextMate::Process.run(CMD, args, ENV["TM_FILEPATH"])
    show_message(err) unless err.empty?
    
    if out.empty?
      show_message(boxify(LINT_SUCCESS_MESSAGE))
    else
      error_amount, errors, error_codes = mark_errors(out)
      error_message = sprintf(
        "Fix (%d) %s:\n\n%s",
        error_amount, 
        pluralize(error_amount, "error"), 
        errors
      )
      show_message(boxify(error_message))
    end
  end
end
