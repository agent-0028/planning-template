# frozen_string_literal: true

# Tests for feature lookup in bin/lib/planning.rb. Most of these started as characterization of
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
