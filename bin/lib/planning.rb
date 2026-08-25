# frozen_string_literal: true

# Shared support for bin/adopt, bin/move, bin/index and bin/check.
# Stdlib only. See AGENTS.md for the (very short) contract these assume.

require "date"

module Planning
  ROOT = File.expand_path("../..", __dir__)

  LIFECYCLES = %w[active proposed shipped abandoned].freeze

  # A feature is a directory under features/<lifecycle>/. Nothing about its
  # contents is required, so every lookup below has to degrade to something.
  class Feature
    attr_reader :lifecycle, :slug

    def self.all(root = ROOT)
      LIFECYCLES.flat_map { |lifecycle|
        Dir.glob(File.join(root, "features", lifecycle, "*"))
          .select { |path| File.directory?(path) }
          .reject { |path| File.basename(path).start_with?(".") }
          .sort
          .map { |path| new(lifecycle, File.basename(path), root) }
      }
    end

    def self.find(slug, root = ROOT)
      all(root).select { |feature| feature.slug == slug }
    end

    def initialize(lifecycle, slug, root = ROOT)
      @lifecycle = lifecycle
      @slug = slug
      @root = root
    end

    def dir = File.join(@root, "features", @lifecycle, @slug)
    def rel_dir = File.join("features", @lifecycle, @slug)

    # The first `# heading` in the folder, preferring the conventional spec
    # filename, with a "Feature Specification: " style label stripped. Falls
    # back to the slug, which is always there.
    def title
      @title ||= heading_from_markdown || @slug
    end

    # The last commit that touched the folder — or today, when the folder has
    # uncommitted changes. Without the second half, `bin/move` would write a
    # README that goes stale the moment it commits the move it just staged.
    def updated
      @updated ||= dirty? ? Date.today : (last_commit_date || Date.today)
    end

    private

    def markdown_files
      top = Dir.glob(File.join(dir, "*.md")).sort
      preferred = top.find { |path| File.basename(path) == "feature-specification.md" }
      preferred ? [preferred] + (top - [preferred]) : top
    end

    def heading_from_markdown
      markdown_files.each do |path|
        heading = File.foreach(path, encoding: "UTF-8")
          .lazy
          .filter_map { |line| line[/\A\#\s+(.+?)\s*\#*\s*\z/, 1] }
          .first
        next unless heading
        return heading.sub(/\A[A-Z][A-Za-z ]{2,40}:\s+/, "").strip
      end
      nil
    end

    def git(*args)
      out = IO.popen(["git", "-C", @root, *args], err: File::NULL, &:read)
      $?.success? ? out : nil
    end

    def dirty?
      status = git("status", "--porcelain", "--", rel_dir)
      !status.to_s.strip.empty?
    end

    def last_commit_date
      stamp = git("log", "-1", "--format=%as", "--", rel_dir).to_s.strip
      stamp.empty? ? nil : (Date.parse(stamp) rescue nil)
    end
  end

  # Renders the block between the GENERATED INDEX markers in README.md.
  module Index
    BEGIN_RE = /^<!--\s*BEGIN GENERATED INDEX\b.*?-->\s*$/
    END_RE = /^<!--\s*END GENERATED INDEX\b.*?-->\s*$/

    module_function

    def readme_path(root = ROOT) = File.join(root, "README.md")

    def render(root = ROOT)
      features = Feature.all(root)
      block = LIFECYCLES.map { |lifecycle|
        table(lifecycle, features.select { |feature| feature.lifecycle == lifecycle })
      }.join
      splice(File.read(readme_path(root), encoding: "UTF-8"), block.rstrip)
    end

    def table(lifecycle, features)
      out = +"## #{lifecycle.capitalize}\n\n"
      return out << "_None._\n\n" if features.empty?

      out << "| Feature | Updated |\n| --- | --- |\n"
      features
        .sort_by { |feature| [-feature.updated.jd, feature.title.downcase] }
        .each { |feature| out << "| [#{escape(feature.title)}](#{feature.rel_dir}/) | #{feature.updated} |\n" }
      out << "\n"
    end

    def escape(text) = text.to_s.gsub("|", "\\|").gsub(/\s+/, " ").strip

    def splice(readme, block)
      lines = readme.lines
      first = lines.index { |line| line.match?(BEGIN_RE) }
      last = lines.index { |line| line.match?(END_RE) }
      raise "README.md has no GENERATED INDEX markers" if first.nil? || last.nil?
      raise "README.md END marker precedes BEGIN marker" if last < first

      (lines[0..first] + ["\n", block, "\n", "\n"] + lines[last..]).join
    end
  end
end
