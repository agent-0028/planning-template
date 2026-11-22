# frozen_string_literal: true

# Shared support for bin/toc, bin/move, bin/delete and bin/check.
# Stdlib only. See INSTRUCTIONS.md for the (very short) contract these assume.

require "set"

module Planning
  ROOT = File.expand_path("../..", __dir__)

  LIFECYCLES = %w[active proposed shipped abandoned].freeze

  # What bin/toc shows with no arguments: the work in flight. Shipped and
  # abandoned plans accumulate without bound, and keeping them out of the
  # default view is the reason the lifecycle folders exist.
  DEFAULT_SCOPE = %w[active proposed].freeze

  # Case-insensitive, with the exact string breaking ties, so the order never
  # depends on the filesystem and two names never compare equal.
  def self.sort_key(name) = [name.downcase, name]

  # A feature is a directory under features/<lifecycle>/. Nothing about its
  # contents is required, so every lookup below has to degrade to something.
  class Feature
    attr_reader :lifecycle, :slug

    def self.all(root = ROOT)
      LIFECYCLES.flat_map { |lifecycle|
        Dir.glob(File.join(root, "features", lifecycle, "*"))
          .select { |path| File.directory?(path) }
          .reject { |path| File.basename(path).start_with?(".") }
          .map { |path| File.basename(path) }
          .sort_by { |slug| Planning.sort_key(slug) }
          .map { |slug| new(lifecycle, slug, root) }
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

    # The markdown files directly inside the folder, alphabetically. Anything in
    # a subfolder is deliberately not a document as far as bin/toc is concerned.
    def documents
      @documents ||= Dir.glob(File.join(dir, "*.md"))
        .select { |path| File.file?(path) }
        .map { |path| File.basename(path) }
        .sort_by { |name| Planning.sort_key(name) }
        .map { |name| Document.new(self, name) }
    end

    # The folders directly inside this one, alphabetically. bin/toc names them
    # without looking inside, so a reader knows there is more to open.
    def subfolders
      @subfolders ||= Dir.children(dir)
        .reject { |name| name.start_with?(".") }
        .select { |name| File.directory?(File.join(dir, name)) }
        .sort_by { |name| Planning.sort_key(name) }
    end

    # Nothing in the folder at all. Dotfiles do not count, so a folder holding
    # only a .gitkeep or a .DS_Store is still empty.
    def empty?
      Dir.children(dir).none? { |name| !name.start_with?(".") }
    end
  end

  # One top-level markdown file in a feature folder.
  class Document
    SNIPPET_LENGTH = 125

    attr_reader :feature, :name

    def initialize(feature, name)
      @feature = feature
      @name = name
    end

    def path = File.join(@feature.dir, @name)
    def rel_path = File.join(@feature.rel_dir, @name)

    # The first `# heading` outside a fenced code block, or nil.
    def heading
      return @heading if defined?(@heading)
      @heading = Markdown.first_heading(text)
    end

    # The heading, or failing that the opening of the file on one line, or
    # failing that the file's name — so every document has something to show.
    def title
      heading || snippet || @name
    end

    def snippet
      flat = text.gsub(/\s+/, " ").strip
      flat.empty? ? nil : flat[0, SNIPPET_LENGTH].rstrip
    end

    private

    def text
      @text ||= File.read(path, encoding: "UTF-8").scrub
    end
  end

  module Markdown
    HEADING_RE = /\A\#\s+(.+?)\s*\#*\s*\z/
    FENCE_RE = /\A {0,3}(`{3,}|~{3,})/

    module_function

    # A line opening with ``` or ~~~ starts a fence, and only a run of the same
    # character at least as long closes it. A heading-shaped line inside one is
    # a shell comment or an example, not a title.
    def first_heading(text)
      fence = nil
      text.each_line do |line|
        line = line.chomp
        if (match = FENCE_RE.match(line))
          marker = match[1]
          if fence.nil?
            fence = marker
          elsif marker[0] == fence[0] && marker.length >= fence.length && line.strip == marker
            fence = nil
          end
          next
        end
        next if fence
        heading = line[HEADING_RE, 1]
        return heading.strip if heading
      end
      nil
    end
  end

  # Last-commit dates for documents, read in one `git log` pass per lifecycle
  # rather than one call per file. A path with uncommitted changes, or with no
  # commit at all, reads as "uncommitted".
  class Dates
    UNCOMMITTED = "uncommitted"

    def initialize(root = ROOT)
      @root = root
      @committed = {}
      @dirty = nil
    end

    def for(document)
      dirty.include?(document.rel_path) ? UNCOMMITTED : committed(document.feature.lifecycle).fetch(document.rel_path, UNCOMMITTED)
    end

    private

    def git(*args)
      out = IO.popen(["git", "-C", @root, "-c", "core.quotePath=false", *args], err: File::NULL, &:read)
      $?.success? ? out : ""
    end

    # Newest commit first, so the first time a path appears is its last change.
    def committed(lifecycle)
      @committed[lifecycle] ||= begin
        dates = {}
        current = nil
        git("log", "--format=\x01%as", "--name-only", "--", File.join("features", lifecycle)).each_line do |line|
          line = line.chomp
          if line.start_with?("\x01")
            current = line.delete_prefix("\x01")
          elsif !line.empty? && current
            dates[line] ||= current
          end
        end
        dates
      end
    end

    def dirty
      @dirty ||= git("status", "--porcelain", "--untracked-files=all", "--", "features").lines.filter_map { |line|
        path = line.chomp[3..]
        path&.split(" -> ")&.last
      }.to_set
    end
  end

  # The table of contents bin/toc prints: lifecycle, then feature by slug, then
  # each top-level document by its heading, with its path and date beneath,
  # then each subfolder by name — one level only.
  module Toc
    USAGE = <<~TEXT
      usage: bin/toc [--shipped] [--abandoned] [--all]

      Lists every plan in flight: each feature folder under features/active/ and
      features/proposed/, by slug, with each of its top-level markdown documents
      by its first `# heading`, its path, and the date of its last commit,
      followed by the names of its subfolders. Nothing inside a subfolder is
      listed.

        (no flags)   active and proposed only — the default, and what to read
                     first when orienting
        --shipped    shipped only
        --abandoned  abandoned only
        --all        every lifecycle

      --shipped and --abandoned can be used alone or together; either one
      replaces the default rather than adding to it. --all overrides both.
    TEXT

    module_function

    # Flags to lifecycles, in lifecycle order. Raises ArgumentError on anything
    # it does not recognize, positional arguments included.
    def scope(args)
      chosen = []
      all = false
      args.each do |arg|
        case arg
        when "--shipped" then chosen << "shipped"
        when "--abandoned" then chosen << "abandoned"
        when "--all" then all = true
        else raise ArgumentError, "unknown argument #{arg.inspect}"
        end
      end
      return LIFECYCLES.dup if all
      return DEFAULT_SCOPE.dup if chosen.empty?
      LIFECYCLES & chosen
    end

    def render(lifecycles, root = ROOT, dates: Dates.new(root))
      features = Feature.all(root)
      sections = lifecycles.map { |lifecycle|
        section(lifecycle, features.select { |feature| feature.lifecycle == lifecycle }, dates)
      }
      sections.join("\n").rstrip + "\n"
    end

    def section(lifecycle, features, dates)
      out = +"## #{lifecycle.capitalize}\n\n"
      return out << "_None._\n" if features.empty?
      out << features.map { |feature| entry(feature, dates) }.join("\n")
    end

    def entry(feature, dates)
      out = +"### #{feature.slug}\n\n"
      feature.documents.each do |document|
        out << "- #{document.title}\n"
        out << "  - #{document.rel_path}\n"
        out << "  - #{dates.for(document)}\n"
      end
      feature.subfolders.each { |name| out << "- #{name}/\n" }
      return out unless feature.documents.empty? && feature.subfolders.empty?

      # Neither documents nor subfolders: say why the heading has nothing under it.
      out << (feature.empty? ? "- _Empty._\n" : "- _No markdown documents._\n")
    end
  end

  # Repo-level checks for bin/check. Each check is a method returning findings;
  # a finding is a warning or a failure, and only failures change the exit code.
  # Add a check by writing a method and listing it in CHECKS.
  module Check
    Finding = Struct.new(:level, :message) do
      def failure? = level == :failure
    end

    CHECKS = %i[documents_without_headings missing_changelog].freeze

    module_function

    def run(root = ROOT)
      CHECKS.flat_map { |check| send(check, root) }
    end

    def warning(message) = Finding.new(:warning, message)
    def failure(message) = Finding.new(:failure, message)

    # Only the work in flight: a finished plan nobody will edit again would
    # otherwise warn on every run forever.
    def documents_without_headings(root = ROOT)
      Feature.all(root)
        .select { |feature| DEFAULT_SCOPE.include?(feature.lifecycle) }
        .flat_map(&:documents)
        .reject(&:heading)
        .map { |document| warning("#{document.rel_path} has no `# heading`; bin/toc shows a snippet of it instead") }
    end

    def missing_changelog(root = ROOT)
      return [] if File.exist?(File.join(root, "CHANGELOG.md"))
      [warning("CHANGELOG.md is missing; it ships with the template and records what each VERSION brought")]
    end
  end
end
