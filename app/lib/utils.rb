module Utils
  def read_json_file(path)
    return unless File.exist?(path)

    file = File.open(path, 'r')
    json = file.read
    return unless json

    content = JSON.parse(json)
    return unless content

    content
  end

  module_function :read_json_file
end
