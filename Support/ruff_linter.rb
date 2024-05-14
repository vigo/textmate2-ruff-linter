require ENV["TM_BUNDLE_SUPPORT"] + "/lib/constants"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/logger"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/linter"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/storage"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/helpers"

module RuffLinter
  include Logging

  extend Helpers
  extend Storage
  
  @document = nil
  
  module_function
  
  def enabled?
    !Constants::TM_PYRUFF_DISABLE
  end

  def can_run?
    !`command -v #{Constants::TM_PYRUFF}`.chomp.empty?
  end
  
  def document_empty?
    @document.nil? || @document.empty? || @document.match(/\S/).nil?
  end

  def document_has_first_line_comment?
    @document.split("\n").first.include?("# TM_PYRUFF_DISABLE")
  end
  
  def run_document_will_save(options={})
    reset_markers
    destroy_storage

    unless can_run?
      logger.fatal "ruff required"
      errors = ["Warning", "You need to install ruff to continue!"]
      create_storage(errors)
      exit_boxify_tool_tip(errors.join("\n"))
    end

    exit_discard unless enabled?
    
    @document = STDIN.read
    
    exit_discard if document_empty?
    exit_discard if document_has_first_line_comment?
    
    errors_sort_imports = nil
    errors_format_code = nil

    out, errors_sort_imports = Linter.sort_imports :input => @document
    @document = out
    
    if errors_sort_imports.nil?
      out, errors_format_code = Linter.format_code :input => @document
      @document = out
    else
      logger.error "errors_sort_imports: #{errors_sort_imports.inspect}"
    end
    
    if errors_format_code.nil?
      if options[:autofix] || Constants::TM_PYRUFF_ENABLE_AUTOFIX
        out = Linter.autofix :input => @document, :manual => options[:autofix]
        @document = out
      else
        logger.error "errors_format_code: #{errors_format_code.inspect}"
      end
    end
    
    print @document
  end
  
  def run_document_did_save
    exit_discard unless can_run?
    exit_discard unless enabled?

    @document = STDIN.read
    
    exit_discard if document_empty?
    exit_discard if document_has_first_line_comment?

    storage_err = get_storage
    if storage_err
      logger.error "storage_err: #{storage_err.inspect}"
      exit_boxify_tool_tip(storage_err)
    end
    
    Linter.check :document_line_count => @document.split("\n").size
  end

  def noqalize_all
    reset_markers
    destroy_storage

    unless can_run?
      logger.fatal "ruff required"
      exit_boxify_tool_tip("Warning\nYou need to install ruff to continue!")
    end
    exit_discard unless enabled?
    
    @document = STDIN.read
    
    exit_discard if document_empty?
    exit_discard if document_has_first_line_comment?
    
    destroy_storage(true)
    Linter.noqalize
  end
end
