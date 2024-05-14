require 'set'

require ENV["TM_SUPPORT_PATH"] + '/lib/tm/process'

require ENV["TM_BUNDLE_SUPPORT"] + "/lib/constants"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/logger"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/helpers"

module RuffLinter
  include Constants
  include Logging

  extend Helpers

  TM_PYRUFF = ENV["TM_PYRUFF"] || `command -v ruff`.chomp
  TM_PYRUFF_GFM_ZOOM_FACTOR = ENV["TM_PYRUFF_GFM_ZOOM_FACTOR"] || "100%"

  module_function

  def report_errors
    input = STDIN.read
    exit_boxify_tool_tip("Nothing to preview") if input.empty?

    cmd = TM_PYRUFF
    args = ["check", "--output-format", "grouped"]
    args += ["--config", get_ruff_config_file] if get_ruff_config_file
    args += get_ruff_extra_options if get_ruff_extra_options
    args += ["--stdin-filename", TM_FILENAME]

    out, err = TextMate::Process.run(cmd, args, :input => input)
    logger.debug "input:\n#{input.inspect}"
    logger.debug "out:\n#{out.inspect}"
    logger.error "err: #{err.inspect}"
    
    exit_boxify_tool_tip("Error\n#{err}") unless err.empty?
    exit_boxify_tool_tip("Error\nWe have a problem") if out.empty?
    exit_boxify_tool_tip("Nothing to preview") if out.start_with?("All checks passed")

    parsed = parse_out(out)
    logger.debug "parsed: #{parsed.inspect}"
    exit_boxify_tool_tip("Nothing to preview") if parsed.size == 0

    errors = parsed[:default_errors] + parsed[:fixable_errors]

    code_set = errors.inject(Set.new) do |set, hash|
      set.add(hash[:code])
      set
    end
    
    response = []
    code_set.each do |code|
      args = ["rule", code]
      out, err = TextMate::Process.run(cmd, args)
      response << out
    end
    
    markdown_to_html = IO.popen('"$TM_SUPPORT_PATH/bin/Markdown.pl"', 'r+') do |io|
      Thread.new { io.write(response.join("\n---\n")); io.close_write }
      io.read
    end

    extra_css_information = %Q{
      <style type="text/css">
        .github-gfm {
          zoom: #{TM_PYRUFF_GFM_ZOOM_FACTOR};
        }
      </style>
    }
    
    html = []
    html << '<html>'
    html << '<head>'
    html << '<title>Current Ruff Error ' + pluralize(response.size, "Description") +'</title>'
    html << '<link rel="stylesheet" href="file://' + ENV["TM_BUNDLE_SUPPORT"] + '/css/gfm.css?' + Time.now.strftime('%s') + '" />'
    html << extra_css_information
    html << '</head>'
    html << '<body>'
    html << '<div class="github-gfm">'
    html << markdown_to_html
    html << '</div>'
    html << '</body>'
    html << '</html>'
    
    puts html.join("\n")
  end
end