# frozen_string_literal: true

# Tests for Planning::Check, behind bin/check.

require_relative "helper"

class CheckHeadingsTest < PlanningTest
  def messages(root) = Planning::Check.documents_without_headings(root).map(&:message)

  def test_warns_for_a_document_without_a_heading
    tmp_tree do |root|
      feature(root, "active", "thing", "notes.md" => "Just prose.\n", "spec.md" => "# Spec\n")

      found = Planning::Check.documents_without_headings(root)

      assert_equal 1, found.length
      assert_equal :warning, found.first.level
      assert_includes found.first.message, "features/active/thing/notes.md"
    end
  end

  def test_a_heading_inside_a_fence_does_not_count
    tmp_tree do |root|
      feature(root, "proposed", "thing", "notes.md" => "```\n# comment\n```\n")

      assert_equal 1, messages(root).length
    end
  end

  def test_checks_active_and_proposed_only
    tmp_tree do |root|
      %w[active proposed shipped abandoned].each { |lifecycle| feature(root, lifecycle, "x-#{lifecycle}", "notes.md" => "prose\n") }

      found = messages(root).join("\n")

      assert_includes found, "x-active"
      assert_includes found, "x-proposed"
      refute_includes found, "x-shipped"
      refute_includes found, "x-abandoned"
    end
  end

  def test_ignores_documents_in_subfolders
    tmp_tree do |root|
      feature(root, "active", "thing", "spec.md" => "# Spec\n", "artifacts/raw.md" => "prose\n")

      assert_empty messages(root)
    end
  end
end

class CheckChangelogTest < PlanningTest
  def test_warns_when_missing
    tmp_tree do |root|
      found = Planning::Check.missing_changelog(root)

      assert_equal [:warning], found.map(&:level)
    end
  end

  def test_quiet_when_present
    tmp_tree do |root|
      File.write(File.join(root, "CHANGELOG.md"), "# Changelog\n")

      assert_empty Planning::Check.missing_changelog(root)
    end
  end
end

class CheckRunTest < PlanningTest
  def test_collects_every_check_and_nothing_fails_today
    tmp_tree do |root|
      feature(root, "active", "thing", "notes.md" => "prose\n")

      found = Planning::Check.run(root)

      assert_equal 2, found.length
      assert found.none?(&:failure?)
    end
  end
end
