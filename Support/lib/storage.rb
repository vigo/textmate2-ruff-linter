require ENV["TM_BUNDLE_SUPPORT"] + "/lib/constants"
require ENV["TM_BUNDLE_SUPPORT"] + "/lib/logger"

module Storage
  include Constants
  extend Logging::ClassMethods

  FILE_PREFIX = "/tmp/textmate-ruff-#{TM_DOCUMENT_UUID}"

  ERROR_FILE = "#{FILE_PREFIX}.error"
  GOTO_FILE = "#{FILE_PREFIX}.goto"

  module_function

  def create_storage(errors, goto=false)
    filename = ERROR_FILE
    filename = GOTO_FILE if goto
    File.open(filename, 'a') do |file|
      file.puts errors.join("\n")
    end
    logger.info "storage.add for #{TM_DOCUMENT_UUID} (#{filename})"
  end

  def get_storage(goto=false)
    filename = ERROR_FILE
    filename = GOTO_FILE if goto
    if File.exist?(filename)
      File.open(filename, 'r') do |file|
        return file.read
      end
    end
    logger.warn "storage.get not found for #{TM_DOCUMENT_UUID} (#{filename})"
    nil
  end
  
  def destroy_storage(goto=false)
    filename = ERROR_FILE
    filename = GOTO_FILE if goto
    if File.exist?(filename)
      File.delete(filename)
      logger.info "storage.destroy for #{TM_DOCUMENT_UUID} - (#{filename})"
    else
      logger.warn "storage.destroy not found for #{TM_DOCUMENT_UUID} - (#{filename})"
    end
  end
end