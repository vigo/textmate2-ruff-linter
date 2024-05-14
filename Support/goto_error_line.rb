require ENV['TM_SUPPORT_PATH'] + '/lib/ui'

require ENV["TM_BUNDLE_SUPPORT"] + "/lib/constants"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/storage"

module RuffLinter
  include Constants
  include Storage
  
  module_function
  
  def goto_error
    if File.exist?(GOTO_FILE)

      goto_errors = File.read(GOTO_FILE)
      if goto_errors
        goto_errors = goto_errors.split("\n").sort
        selected_index = TextMate::UI.menu(goto_errors)

        unless selected_index.nil?
          selected_error = goto_errors[selected_index]
          if selected_error
            line = selected_error.split(" ").first
            system(ENV["TM_MATE"], "--uuid", TM_DOCUMENT_UUID, "--line", line)
          end
        end
      end

    end
  end
end