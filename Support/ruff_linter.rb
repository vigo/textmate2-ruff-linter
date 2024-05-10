require ENV["TM_BUNDLE_SUPPORT"] + "/lib/logger"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/linter"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/storage"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/helpers"

module RuffLinter
  include Logging
  include Linter
  include Storage
  
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

  def document_has_first_line_comment?
    document.split("\n").first.include?("# TM_PYRUFF_DISABLE")
  end
  
  def run_document_will_save(options={})
    logger.info "bundle can_run?: #{can_run?}"
    logger.info "bundle enabled?: #{enabled?}"

    Helpers.reset_markers
    Storage.destroy

    Helpers.alert :title => "Warning", :message => "You need to install ruff to continue!" unless can_run?
    Helpers.exit_discard unless enabled?
    
    read_stdin
    
    Helpers.exit_discard if document_empty?
    Helpers.exit_discard if document_has_first_line_comment?
    
    out = Linter.sort_imports(:cmd => TM_PYRUFF, :input => document)
    document = out

    out = Linter.format_code(:cmd => TM_PYRUFF, :input => document)
    document = out
    
    if options[:autofix] || TM_PYRUFF_ENABLE_AUTOFIX
      logger.info "autofix enabled"
      out = Linter.autofix(:cmd => TM_PYRUFF, :input => document)
      document = out
    end
    
    print document
  end
  
  def run_document_did_save
    Helpers.exit_discard unless can_run?
    Helpers.exit_discard unless enabled?

    read_stdin
    
    Helpers.exit_discard if document_empty?
    Helpers.exit_discard if document_has_first_line_comment?
    Helpers.exit_discard if Storage.get
    
    logger.info "running run_document_did_save"
    
    Linter.check(:cmd => TM_PYRUFF)
  end

  def noqalize_all
    logger.info "bundle can_run?: #{can_run?}"
    logger.info "bundle enabled?: #{enabled?}"

    Helpers.reset_markers
    Storage.destroy

    Helpers.alert :title => "Warning", :message => "You need to install ruff to continue!" unless can_run?
    Helpers.exit_discard unless enabled?
    
    read_stdin
    
    Helpers.exit_discard if document_empty?
    Helpers.exit_discard if document_has_first_line_comment?
    
    logger.info "aaaaaaaaaa"
    
    Linter.noqalize(:cmd => TM_PYRUFF)
  end
end
