require 'fileutils'

class Source < Struct.new(:dir)
  def renumber
    check_filenames
    detect_moved_files

    # fix_references
    # move_files
  rescue => e
    puts e.message
  end

  private

    def check_filenames
      sources.each do |path|
        basename = File.basename(path)
        raise "Invalid filename: #{basename}.md" unless basename =~ /[\d]{2}-[\w_]+/
      end
    end

    def detect_moved_files
      sources.each do |path|
        p path
      end
    end

    def fix_references
      sources.each do |path|
        filename = "#{path}.md"
        content = File.read(filename)
        content = fix_links(content)
        content = fix_exercise_refs(content)
        File.write(filename, content)
      end
    end

    def move_files
      all.each do |source, target|
        next if source == target
        FileUtils.mv(source, target) if File.exists?(source)
        FileUtils.mv("#{source}.md", "#{target}.md") if File.exists?("#{source}.md")
      end
    end

    def fix_links(content)
      changed.each do |source, target|
        source = source.sub('source/', '')
        target = target.sub('source/', '')
        content.gsub!("/#{source}.html", "/#{target}.html")
      end
      content
    end

    def fix_exercise_refs(content)
      changed.each do |source, target|
        source = File.basename(source)
        target = File.basename(target)
        content.gsub!(/#{source}-([\d]{1,2}).rb/) { "#{target}-#{$1}.rb" }
      end
      content
    end

    def all
      @all ||= renumbered_paths(dir)
    end

    def changed
      all.select { |source, target| source != target }
    end

    def sources
      all.map(&:first)
    end

    def renumbered_paths(dir)
      result = []
      paths(dir).map.with_index do |path, number|
        number = (number + 1).to_s.rjust(2, '0')
        result << [path, path.sub(/(.*)[\d]{2}-/, "\\1#{number}-")]
        result += renumbered_paths(path)
      end
      result
    end

    def paths(dir)
      paths = Dir["#{dir}/*.md"]
      paths = paths.select { |path| path =~ /[\d]{2}-/ }
      paths = paths.map { |path| path.sub('.md', '') }.uniq.sort
    end
end

source = Source.new('source')
source.renumber
