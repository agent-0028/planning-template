# frozen_string_literal: true

# Tests for bin/lib/planning.rb. Most of these started as characterization of
# behavior that predates them, so where one looks like it is pinning down
# something odd, that is the point — the oddity is the behavior, and a change to
# it should show up here as a deliberate edit rather than as a surprise.

require_relative "helper"

class FeatureLookupTest < PlanningTest
  def test_all_returns_features_in_lifecycle_order
    tmp_tree do |root|
      Planning::LIFECYCLES.each { |lifecycle| feature(root, lifecycle, "thing") }

      assert_equal Planning::LIFECYCLES, Planning::Feature.all(root).map(&:lifecycle)
    end
  end

  def test_all_sorts_within_a_lifecycle
    tmp_tree do |root|
      %w[zebra apple mango].each { |slug| feature(root, "active", slug) }

      assert_equal %w[apple mango zebra], Planning::Feature.all(root).map(&:slug)
    end
  end

  def test_all_skips_dotfiles_and_plain_files
    tmp_tree do |root|
      feature(root, "active", "real")
      feature(root, "active", ".hidden")
      File.write(File.join(root, "features", "active", "loose.md"), "# Not a feature\n")

      assert_equal %w[real], Planning::Feature.all(root).map(&:slug)
    end
  end

  def test_find_returns_every_lifecycle_holding_the_slug
    tmp_tree do |root|
      feature(root, "active", "dupe")
      feature(root, "shipped", "dupe")

      found = Planning::Feature.find("dupe", root)

      assert_equal %w[active shipped], found.map(&:lifecycle)
    end
  end

  def test_find_returns_nothing_for_an_unknown_slug
    tmp_tree do |root|
      feature(root, "active", "real")

      assert_empty Planning::Feature.find("imaginary", root)
    end
  end

  def test_paths
    tmp_tree do |root|
      feature(root, "proposed", "static-site-https")
      found = Planning::Feature.find("static-site-https", root).first

      assert_equal "features/proposed/static-site-https", found.rel_dir
      assert_equal File.join(root, "features/proposed/static-site-https"), found.dir
    end
  end
end

class FeatureTitleTest < PlanningTest
  def title_for(files)
    tmp_tree do |root|
      feature(root, "proposed", "some-slug", files)
      return Planning::Feature.find("some-slug", root).first.title
    end
  end

  def test_reads_the_first_h1_from_the_spec
    assert_equal "Static site HTTPS",
      title_for("feature-specification.md" => "# Static site HTTPS\n\nProse.\n")
  end

  def test_strips_a_leading_label
    assert_equal "Static site HTTPS",
      title_for("feature-specification.md" => "# Feature Specification: Static site HTTPS\n")
  end

  def test_trims_trailing_hashes
    assert_equal "Closing hashes",
      title_for("feature-specification.md" => "# Closing hashes ###\n")
  end

  def test_prefers_the_spec_over_an_alphabetically_earlier_file
    assert_equal "From the spec", title_for(
      "aaa-earlier.md" => "# From the other file\n",
      "feature-specification.md" => "# From the spec\n"
    )
  end

  def test_falls_back_to_any_other_top_level_markdown
    assert_equal "From the notes", title_for("notes.md" => "# From the notes\n")
  end

  def test_ignores_headings_below_the_top_level_of_the_folder
    assert_equal "some-slug", title_for("artifacts/decision-log.md" => "# Buried heading\n")
  end

  def test_falls_back_to_the_slug_when_no_heading_exists
    assert_equal "some-slug", title_for("notes.md" => "Prose with no heading at all.\n")
  end

  def test_falls_back_to_the_slug_for_an_empty_folder
    assert_equal "some-slug", title_for({})
  end
end

class FeatureUpdatedTest < PlanningTest
  def test_uses_the_last_commit_touching_the_folder
    tmp_repo do |root|
      feature(root, "active", "settled", "feature-specification.md" => "# Settled\n")
      commit_all(root, date: "2020-01-02")

      assert_equal "2020-01-02", Planning::Feature.find("settled", root).first.updated.to_s
    end
  end

  def test_reports_today_when_the_folder_has_uncommitted_changes
    tmp_repo do |root|
      dir = feature(root, "active", "churning", "feature-specification.md" => "# Churning\n")
      commit_all(root, date: "2020-01-02")
      File.write(File.join(dir, "feature-specification.md"), "# Churning\n\nEdited.\n")

      assert_equal today, Planning::Feature.find("churning", root).first.updated.to_s
    end
  end

  def test_reports_today_for_a_folder_in_no_commit
    tmp_repo do |root|
      feature(root, "active", "brand-new", "feature-specification.md" => "# Brand new\n")

      assert_equal today, Planning::Feature.find("brand-new", root).first.updated.to_s
    end
  end
end

class IndexEscapeTest < PlanningTest
  def test_escapes_pipes_so_they_cannot_break_the_table
    assert_equal "before \\| after", Planning::Index.escape("before | after")
  end

  def test_collapses_whitespace_onto_one_line
    assert_equal "one two three", Planning::Index.escape("one\n  two\tthree")
  end

  def test_strips_surrounding_whitespace
    assert_equal "trimmed", Planning::Index.escape("  trimmed  ")
  end
end

class IndexTableTest < PlanningTest
  def test_renders_none_for_an_empty_lifecycle
    assert_equal "## Active\n\n_None._\n\n", Planning::Index.table("active", [])
  end

  def test_renders_a_row_per_feature
    tmp_tree do |root|
      feature(root, "proposed", "static-site-https", "feature-specification.md" => "# Static site HTTPS\n")

      table = Planning::Index.table("proposed", Planning::Feature.all(root))

      assert_equal <<~MARKDOWN, table
        ## Proposed

        | Feature | Updated |
        | --- | --- |
        | [Static site HTTPS](features/proposed/static-site-https/) | #{today} |

      MARKDOWN
    end
  end

  def test_sorts_newest_first
    tmp_repo do |root|
      feature(root, "active", "older", "feature-specification.md" => "# Older\n")
      commit_all(root, date: "2020-01-02")
      feature(root, "active", "newer", "feature-specification.md" => "# Newer\n")
      commit_all(root, date: "2021-06-07")

      table = Planning::Index.table("active", Planning::Feature.all(root))

      assert_operator table.index("Newer"), :<, table.index("Older")
    end
  end

  def test_breaks_ties_on_title_case_insensitively
    tmp_tree do |root|
      feature(root, "active", "zebra", "feature-specification.md" => "# zebra\n")
      feature(root, "active", "apple", "feature-specification.md" => "# Apple\n")

      table = Planning::Index.table("active", Planning::Feature.all(root))

      assert_operator table.index("Apple"), :<, table.index("zebra")
    end
  end
end

class IndexCurrentTest < PlanningTest
  def test_points_at_index_md
    assert_equal File.join("/somewhere", "INDEX.md"), Planning::Index.index_path("/somewhere")
  end

  def test_reads_the_file_when_it_exists
    tmp_tree do |root|
      File.write(File.join(root, "INDEX.md"), "# Feature index\n")

      assert_equal "# Feature index\n", Planning::Index.current(root)
    end
  end

  # A repo that has only just adopted this tooling has no INDEX.md. Callers
  # compare against this, so it has to be a string rather than an exception.
  def test_returns_empty_when_the_file_is_missing
    tmp_tree do |root|
      refute_path_exists File.join(root, "INDEX.md")

      assert_equal "", Planning::Index.current(root)
    end
  end
end

class IndexRenderTest < PlanningTest
  def test_renders_a_whole_file_not_a_spliced_block
    tmp_tree do |root|
      rendered = Planning::Index.render(root)

      assert rendered.start_with?("# Feature index\n"), "expected a heading of its own"
      assert_equal rendered, rendered.rstrip + "\n", "expected exactly one trailing newline"
      refute_includes rendered, "GENERATED INDEX"
    end
  end

  def test_renders_every_lifecycle
    tmp_tree do |root|
      feature(root, "proposed", "static-site-https", "feature-specification.md" => "# Static site HTTPS\n")

      rendered = Planning::Index.render(root)

      assert_includes rendered, "| [Static site HTTPS](features/proposed/static-site-https/) | #{today} |"
      %w[Active Proposed Shipped Abandoned].each { |heading| assert_includes rendered, "## #{heading}" }
      assert_equal 3, rendered.scan("_None._").length
    end
  end

  # README.md is hand-written now. Nothing in the lib may read or rewrite it.
  def test_leaves_the_readme_alone
    tmp_tree do |root|
      before = File.read(File.join(root, "README.md"))
      Planning::Index.render(root)

      assert_equal before, File.read(File.join(root, "README.md"))
    end
  end
end
