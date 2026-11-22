# frozen_string_literal: true

# Tests for the pieces of bin/lib/planning.rb behind bin/toc: documents, their
# headings, their dates, and the rendered table of contents.

require_relative "helper"

class FeatureSortTest < PlanningTest
  def test_slugs_sort_case_insensitively
    tmp_tree do |root|
      %w[beta Alpha gamma].each { |slug| feature(root, "active", slug) }

      assert_equal %w[Alpha beta gamma], Planning::Feature.all(root).map(&:slug)
    end
  end
end

class FeatureDocumentsTest < PlanningTest
  def documents_for(files)
    tmp_tree do |root|
      feature(root, "active", "thing", files)
      return Planning::Feature.find("thing", root).first.documents.map(&:name)
    end
  end

  def test_lists_top_level_markdown_alphabetically
    assert_equal %w[alpha.md Beta.md gamma.md],
      documents_for("gamma.md" => "", "Beta.md" => "", "alpha.md" => "")
  end

  def test_ignores_subfolders_and_other_files
    assert_equal %w[spec.md], documents_for(
      "spec.md" => "# Spec\n",
      "artifacts/decision-log.md" => "# Buried\n",
      "deep/er/still.md" => "# Deeper\n",
      "diagram.png" => "binary"
    )
  end

  def test_empty_ignores_dotfiles
    tmp_tree do |root|
      feature(root, "active", "blank", ".gitkeep" => "")
      feature(root, "active", "nested", "artifacts/log.md" => "# Log\n")

      assert Planning::Feature.find("blank", root).first.empty?
      refute Planning::Feature.find("nested", root).first.empty?
    end
  end
end

class MarkdownHeadingTest < PlanningTest
  def heading(text) = Planning::Markdown.first_heading(text)

  def test_reads_the_first_h1
    assert_equal "First", heading("intro\n# First\n# Second\n")
  end

  def test_keeps_a_leading_label
    assert_equal "Feature Specification: Static site HTTPS",
      heading("# Feature Specification: Static site HTTPS\n")
  end

  def test_trims_closing_hashes
    assert_equal "Closing hashes", heading("# Closing hashes ###\n")
  end

  def test_ignores_lower_level_headings
    assert_nil heading("## Two\n### Three\n")
  end

  def test_ignores_a_hash_with_no_space
    assert_nil heading("#hashtag\n")
  end

  def test_skips_backtick_fences
    assert_equal "Real", heading("```bash\n# a shell comment\n```\n# Real\n")
  end

  def test_skips_tilde_fences
    assert_equal "Real", heading("~~~\n# not a title\n~~~\n# Real\n")
  end

  def test_a_different_fence_character_does_not_close
    assert_nil heading("```\n~~~\n# still inside\n")
  end

  def test_a_shorter_fence_does_not_close
    assert_equal "After", heading("````\n```\n# inside\n````\n# After\n")
  end

  def test_an_unclosed_fence_hides_the_rest
    assert_nil heading("```\n# inside forever\n")
  end
end

class DocumentTitleTest < PlanningTest
  def title_for(content, name: "notes.md")
    tmp_tree do |root|
      feature(root, "active", "thing", name => content)
      return Planning::Feature.find("thing", root).first.documents.first.title
    end
  end

  def test_uses_the_heading
    assert_equal "Notes", title_for("# Notes\n\nProse.\n")
  end

  def test_falls_back_to_a_snippet_on_one_line
    assert_equal "Some prose that wraps here.", title_for("Some prose\nthat wraps\n\n  here.\n")
  end

  def test_truncates_the_snippet
    assert_equal "a" * 125, title_for("a" * 300)
  end

  def test_falls_back_to_the_filename_for_an_empty_file
    assert_equal "empty.md", title_for("  \n\n", name: "empty.md")
  end
end

class DatesTest < PlanningTest
  def date_for(root, slug, name)
    feature = Planning::Feature.find(slug, root).first
    document = feature.documents.find { |doc| doc.name == name }
    Planning::Dates.new(root).for(document)
  end

  def test_uses_the_last_commit_touching_each_file
    tmp_repo do |root|
      dir = feature(root, "active", "thing", "old.md" => "# Old\n", "new.md" => "# New\n")
      commit_all(root, date: "2020-01-02")
      File.write(File.join(dir, "new.md"), "# New\n\nEdited.\n")
      commit_all(root, date: "2021-03-04")

      assert_equal "2020-01-02", date_for(root, "thing", "old.md")
      assert_equal "2021-03-04", date_for(root, "thing", "new.md")
    end
  end

  def test_reports_uncommitted_for_a_modified_file
    tmp_repo do |root|
      dir = feature(root, "active", "thing", "spec.md" => "# Spec\n")
      commit_all(root)
      File.write(File.join(dir, "spec.md"), "# Spec\n\nEdited.\n")

      assert_equal "uncommitted", date_for(root, "thing", "spec.md")
    end
  end

  def test_reports_uncommitted_for_a_file_in_no_commit
    tmp_repo do |root|
      feature(root, "active", "thing", "spec.md" => "# Spec\n")

      assert_equal "uncommitted", date_for(root, "thing", "spec.md")
    end
  end

  def test_reports_uncommitted_for_a_staged_move
    tmp_repo do |root|
      feature(root, "proposed", "thing", "spec.md" => "# Spec\n")
      commit_all(root)
      git(root, "mv", "features/proposed/thing", "features/active/thing")

      assert_equal "uncommitted", date_for(root, "thing", "spec.md")
    end
  end

  def test_reports_uncommitted_outside_a_repository
    tmp_tree do |root|
      feature(root, "active", "thing", "spec.md" => "# Spec\n")

      assert_equal "uncommitted", date_for(root, "thing", "spec.md")
    end
  end
end

class TocScopeTest < PlanningTest
  def scope(*args) = Planning::Toc.scope(args)

  def test_defaults_to_active_and_proposed
    assert_equal %w[active proposed], scope
  end

  def test_shipped_alone
    assert_equal %w[shipped], scope("--shipped")
  end

  def test_abandoned_alone
    assert_equal %w[abandoned], scope("--abandoned")
  end

  def test_shipped_and_abandoned_together_in_lifecycle_order
    assert_equal %w[shipped abandoned], scope("--abandoned", "--shipped")
  end

  def test_all_overrides_the_others
    assert_equal Planning::LIFECYCLES, scope("--shipped", "--all")
  end

  def test_rejects_unknown_flags_and_positional_arguments
    assert_raises(ArgumentError) { scope("--bogus") }
    assert_raises(ArgumentError) { scope("active") }
  end
end

class TocRenderTest < PlanningTest
  def test_renders_features_and_documents
    tmp_repo do |root|
      feature(root, "proposed", "static-site-https",
        "feature-specification.md" => "# Feature Specification: Static site HTTPS\n",
        "feature-implementation-plan.md" => "# Implementation Plan: Static site HTTPS\n")
      commit_all(root, date: "2020-01-02")

      assert_equal <<~MARKDOWN, Planning::Toc.render(%w[active proposed], root)
        ## Active

        _None._

        ## Proposed

        ### static-site-https

        - Implementation Plan: Static site HTTPS
          - features/proposed/static-site-https/feature-implementation-plan.md
          - 2020-01-02
        - Feature Specification: Static site HTTPS
          - features/proposed/static-site-https/feature-specification.md
          - 2020-01-02
      MARKDOWN
    end
  end

  def test_shows_only_the_selected_lifecycles
    tmp_tree do |root|
      feature(root, "active", "live", "a.md" => "# Live\n")
      feature(root, "shipped", "done", "a.md" => "# Done\n")

      rendered = Planning::Toc.render(%w[shipped], root)

      assert_includes rendered, "### done"
      refute_includes rendered, "live"
      refute_includes rendered, "## Active"
    end
  end

  def test_sorts_features_alphabetically_whatever_their_dates
    tmp_repo do |root|
      feature(root, "active", "zebra", "a.md" => "# Z\n")
      commit_all(root, date: "2020-01-02")
      feature(root, "active", "apple", "a.md" => "# A\n")
      commit_all(root, date: "2024-01-02")

      rendered = Planning::Toc.render(%w[active], root)

      assert_operator rendered.index("### apple"), :<, rendered.index("### zebra")
    end
  end

  def test_marks_empty_folders_and_folders_without_documents
    tmp_tree do |root|
      feature(root, "active", "blank")
      feature(root, "active", "nested", "artifacts/log.md" => "# Log\n")

      assert_equal <<~MARKDOWN, Planning::Toc.render(%w[active], root)
        ## Active

        ### blank

        - _Empty._

        ### nested

        - _No top-level documents._
      MARKDOWN
    end
  end
end
