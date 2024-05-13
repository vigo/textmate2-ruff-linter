require ENV["TM_BUNDLE_SUPPORT"] + "/lib/logger"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/linter"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/storage"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/helpers"

module RuffLinter
  include Logging
  
  TM_PYRUFF_DISABLE = !!ENV["TM_PYRUFF_DISABLE"]
  TM_PYRUFF = ENV["TM_PYRUFF"] || `command -v ruff`.chomp
  TM_PYRUFF_ENABLE_AUTOFIX = !ENV["TM_PYRUFF_ENABLE_AUTOFIX"].nil?
  
  @document = nil
  
  module_function
  
  def enabled?
    !TM_PYRUFF_DISABLE
  end

  def can_run?
    !`command -v #{TM_PYRUFF}`.chomp.empty?
  end
  
  def document_empty?
    @document.nil? || @document.empty? || @document.match(/\S/).nil?
  end

  def document_has_first_line_comment?
    @document.split("\n").first.include?("# TM_PYRUFF_DISABLE")
  end
  
  def run_document_will_save(options={})
    Helpers.reset_markers
    Storage.destroy

    unless can_run?
      logger.fatal "ruff required"
      errors = ["Warning", "You need to install ruff to continue!"]
      Storage.add(errors)
      Helpers.exit_boxify_tool_tip(errors.join("\n"))
    end

    Helpers.exit_discard unless enabled?
    
    @document = STDIN.read
    
    Helpers.exit_discard if document_empty?
    Helpers.exit_discard if document_has_first_line_comment?
    
    errors_sort_imports = nil
    errors_format_code = nil

    out, errors_sort_imports = Linter.sort_imports(:cmd => TM_PYRUFF, :input => @document)
    @document = out
    
    if errors_sort_imports.nil?
      out, errors_format_code = Linter.format_code(:cmd => TM_PYRUFF, :input => @document)
      @document = out
    else
      logger.error "errors_sort_imports: #{errors_sort_imports.inspect}"
    end
    
    if errors_format_code.nil?
      if options[:autofix] || TM_PYRUFF_ENABLE_AUTOFIX
        out = Linter.autofix(:cmd => TM_PYRUFF, :input => @document)
        @document = out
      else
        logger.error "errors_format_code: #{errors_format_code.inspect}"
      end
    end
    
    print @document
  end
  
  def run_document_did_save
    Helpers.exit_discard unless can_run?
    Helpers.exit_discard unless enabled?

    @document = STDIN.read
    
    Helpers.exit_discard if document_empty?
    Helpers.exit_discard if document_has_first_line_comment?

    storage_err = Storage.get
    if storage_err
      logger.error "storage_err: #{storage_err.inspect}"
      Helpers.exit_boxify_tool_tip(storage_err)
    end
    
    Linter.check(:cmd => TM_PYRUFF, 
                 :document_line_count => @document.split("\n").size)
  end

  def noqalize_all
    Helpers.reset_markers
    Storage.destroy

    unless can_run?
      logger.fatal "ruff required"
      Helpers.exit_boxify_tool_tip("Warning\nYou need to install ruff to continue!")
    end
    Helpers.exit_discard unless enabled?
    
    @document = STDIN.read
    
    Helpers.exit_discard if document_empty?
    Helpers.exit_discard if document_has_first_line_comment?
    
    Storage.destroy(true)
    Linter.noqalize(:cmd => TM_PYRUFF)
  end
end
