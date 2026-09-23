# frozen_string_literal: true

# Fixture builders for the Planning lib tests.
#
# Two levels, because only one thing in the lib touches git:
#
#   tmp_tree   a plain directory tree. Everything that reads files — titles,
#              lookups, table rendering — needs nothing more than this.
#   tmp_repo   tmp_tree plus `git init`, for the four tests that exercise
#              Feature#updated, which shells out to `git log` and
#              `git status`. Nothing else should reach for it.
#
# In a plain tmp_tree those git calls fail, Feature#updated falls through to
# Date.today, and that is a perfectly good fixture for anything that does not
# care what the date is.
#
# Stdlib only, matching the lib itself. Minitest ships with Ruby.

require "minitest/autorun"
require "fileutils"
require "tmpdir"
require "date"

require_relative "../bin/lib/planning"

module Fixtures
  # A README still carrying the old generated-index markers, as a repo that has
  # not yet been cleaned up would have. Nothing in the lib may touch this file
  # any more, and one test exists to prove it.
  README = <<~MARKDOWN
    # planning

    Intro prose that must survive.

    <!-- BEGIN GENERATED INDEX — edited by bin/index, do not hand-edit -->

    stale content

    <!-- END GENERATED INDEX -->

    Trailing prose that must survive.
  MARKDOWN

  # The hand-written instructions. Like the README, nothing in the lib may read
  # or rewrite it; the same test covers both.
  INSTRUCTIONS = <<~MARKDOWN
    # Instructions

    Prose that must survive untouched.
  MARKDOWN

  # A fixed date for committed fixtures, well clear of Date.today so tests can
  # tell "last commit" and "today" apart without ambiguity.
  COMMITTED_ON = "2020-01-02"

  def tmp_tree
    Dir.mktmpdir("planning-test") do |root|
      Planning::LIFECYCLES.each do |lifecycle|
        FileUtils.mkdir_p(File.join(root, "features", lifecycle))
      end
      File.write(File.join(root, "README.md"), README)
      File.write(File.join(root, "INSTRUCTIONS.md"), INSTRUCTIONS)
      yield root
    end
  end

  def tmp_repo
    tmp_tree do |root|
      git(root, "init", "--quiet")
      git(root, "config", "user.email", "test@example.invalid")
      git(root, "config", "user.name", "Planning Tests")
      git(root, "config", "commit.gpgsign", "false")
      yield root
    end
  end

  # Writes a feature folder. `files` maps relative names to contents, so a
  # folder with nothing in it is just as easy to build as a fully worked one.
  def feature(root, lifecycle, slug, files = {})
    dir = File.join(root, "features", lifecycle, slug)
    FileUtils.mkdir_p(dir)
    files.each do |name, content|
      path = File.join(dir, name)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end
    dir
  end

  def git(root, *args, date: nil)
    env = date ? {"GIT_AUTHOR_DATE" => "#{date}T12:00:00+0000", "GIT_COMMITTER_DATE" => "#{date}T12:00:00+0000"} : {}
    ok = system(env, "git", "-C", root, *args, out: File::NULL, err: File::NULL)
    raise "fixture: git #{args.join(" ")} failed" unless ok
  end

  # Commits everything currently in the tree at a pinned date, so the Updated
  # column is the same on every machine and every run.
  def commit_all(root, message: "fixture", date: COMMITTED_ON)
    git(root, "add", "-A")
    git(root, "commit", "-m", message, date: date)
  end

  def today = Date.today.to_s
end

class PlanningTest < Minitest::Test
  include Fixtures
end
