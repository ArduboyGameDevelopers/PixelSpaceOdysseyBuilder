require 'zip'

module Common

  def fail_script(message)
    raise "Build failed! #{message}"
  end

  def fail_script_unless(condition, message)
    fail_script message unless condition
  end

  def fail_script_if(condition, message)
    fail_script message if condition
  end

  def fail_script_unless_file_exists(path)
    fail_script_unless path != nil && (File.directory?(path) || File.exists?(path)), "File doesn't exist: '#{path}'"
  end

  def not_nil(something)
    fail_script_unless something != nil, 'Not nil expected'
    something
  end

  def extract_regex(text, pattern)
    text =~ pattern
    return $1
  end

  def resolve_path(path)
    fail_script_unless_file_exists path
    return path
  end

  def make_dir(path, options = {})
    if options[:overwrite]
      FileUtils.rmtree path
    end

    FileUtils.mkpath path
  end

  def exec_shell(command, error_message, options = {})
    puts "Running command: #{command}" unless options[:silent] == true
    result = `#{command}`
    if options[:dont_fail_on_error] == true
      puts error_message unless $?.success?
    else
      fail_script_unless($?.success?, "#{error_message}\nShell failed: #{command}\n#{result}")
    end

    return result
  end

  def zip_dir(path, out_file = nil)

    fail_script_unless_file_exists path
    out_file = "#{File.basename(path)}.zip" if out_file.nil?

    path.sub!(%r[/$],'')

    FileUtils.rm out_file, :force => true
    basedir = File.basename(out_file, '.zip')

    Zip::File.open(out_file, Zip::File::CREATE) do |zip_file|
      Dir["#{path}/**/**"].each do |file|
        dest = "#{basedir}/#{file.sub("#{path}/", '')}"
        zip_file.add(dest, file)
      end
    end

    return File.expand_path out_file
  end

  def get_release_notes(dir_repo, version)

    header = "## v.#{version}"

    file_release_notes = resolve_path "#{dir_repo}/CHANGELOG.md"

    lines = File.readlines file_release_notes

    start_index = -1
    end_index = -1

    (0 .. lines.length - 1).each do |index|
      line = lines[index]
      if line.include? header
        start_index = index + 1
        break
      end
    end

    (start_index + 1 .. lines.length - 1).each do |index|
      line = lines[index]
      if line =~ /## v\.\d+\.\d+\.\d+/
        end_index = index - 1
        break
      end
    end


    fail_script_unless start_index != -1 && end_index != -1, "Can't extract release notes"

    notes = lines[start_index..end_index].join
    notes.strip!
    notes.gsub! '"', '\\"'

    return notes

  end

end
