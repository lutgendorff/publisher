require 'test_helper'

class PrimaryListingPresenterTest < ActiveSupport::TestCase

  setup do
    json = JSON.dump("name" => "Childcare", "slug" => "childcare")
    stub_request(:get, %r{http://panopticon\.test\.gov\.uk/artefacts/.*\.js}).
      to_return(:status => 200, :body => json, :headers => {})
  end

  def setup_users
    alice = User.create
    bob = User.create
    return alice, bob
  end

  test "should filter by draft state" do
    presenter = PrimaryListingPresenter.new(Edition, :all)

    a = FactoryGirl.create(:guide_edition)
    a.update_attribute(:state, 'draft')
    assert a.draft?

    b = FactoryGirl.create(:guide_edition)
    b.update_attribute(:state, 'published')
    b.save
    b.reload
    assert !b.draft?

    assert_equal [a], presenter.draft.to_a
  end

  test "should filter by published state" do
    presenter = PrimaryListingPresenter.new(Edition, :all)

    a = FactoryGirl.create(:guide_edition)
    assert !a.published?

    b = FactoryGirl.create(:guide_edition)
    b.update_attribute(:state, 'published')
    b.reload
    assert b.published?

    assert_equal [b], presenter.published.to_a
  end

  test "should filter by archived state" do
    presenter = PrimaryListingPresenter.new(Edition, :all)

    a = FactoryGirl.create(:guide_edition)
    assert ! a.archived?

    b = FactoryGirl.create(:guide_edition)
    b.update_attribute(:state, 'published')
    b.archive
    b.save

    assert b.archived?

    assert_equal [b], presenter.archived.to_a
  end

  test "should filter by in_review state" do
    presenter = PrimaryListingPresenter.new(Edition, :all)
    user = User.create

    a = FactoryGirl.create(:guide_edition)
    assert !a.in_review?

    b = FactoryGirl.create(:guide_edition)
    b.update_attribute(:state, 'in_review')
    b.reload
    assert b.in_review?

    assert_equal [b], presenter.in_review.to_a
  end

  test "should filter by fact checking state" do
    presenter = PrimaryListingPresenter.new(Edition, :all)
    user = User.create

    a = FactoryGirl.create(:guide_edition)
    assert !a.fact_check?

    b = FactoryGirl.create(:guide_edition)
    b.update_attribute(:state, 'fact_check')
    b.reload
    assert b.fact_check?

    assert_equal [b], presenter.fact_check.to_a
  end

  test "should select publications assigned to a user" do
    alice, bob = setup_users

    a = FactoryGirl.create(:guide_edition)
    assert_nil a.assigned_to
    assert a.draft?

    b = FactoryGirl.create(:guide_edition)
    alice.assign(b, bob)
    assert_equal bob, b.assigned_to
    assert b.draft?

    presenter = PrimaryListingPresenter.new(Edition, bob)
    assert_equal [b], presenter.draft.to_a
  end

  test "should select publications assigned to nobody" do
    alice, bob = setup_users

    a = FactoryGirl.create(:guide_edition, title: 'My First Guide')
    assert_nil a.assigned_to
    assert a.draft?

    b = FactoryGirl.create(:guide_edition, title: 'My Second Guide')
    alice.assign(b, bob)
    assert_equal bob, b.assigned_to
    assert b.draft?

    presenter = PrimaryListingPresenter.new(Edition, :nobody)
    assert_equal [a], presenter.draft.to_a
  end

  test "should select all publications" do
    alice, bob = setup_users

    a = FactoryGirl.create(:guide_edition)
    assert_nil a.assigned_to
    assert a.draft?

    b = FactoryGirl.create(:guide_edition)
    alice.assign(b, bob)
    assert_equal bob, b.assigned_to
    assert b.draft?

    presenter = PrimaryListingPresenter.new(Edition, :all)
    assert_equal [b, a].collect { |i| i.id.to_s }.sort, presenter.draft.to_a.collect { |i| i.id.to_s }.sort
  end

  test "should select and filter" do
    alice, bob = setup_users

    a = FactoryGirl.create(:guide_edition)
    assert_nil a.assigned_to
    assert a.draft?

    b = FactoryGirl.create(:guide_edition)
    alice.assign(b, bob)
    assert_equal bob, b.assigned_to
    assert b.draft?

    c = FactoryGirl.create(:guide_edition)
    alice.assign(c, bob)
    assert_equal bob, c.assigned_to
    assert c.draft?

    presenter = PrimaryListingPresenter.new(Edition, bob)
    assert_equal [b, c].sort_by(&:title), presenter.draft.to_a.sort_by(&:title)

    presenter = PrimaryListingPresenter.new(Edition, :nobody)
    assert_equal [a], presenter.draft.to_a

    presenter = PrimaryListingPresenter.new(Edition, :all)
    assert_equal [a, b, c].sort_by(&:title), presenter.draft.to_a.sort_by(&:title)
  end

  test "can filter publications by title substring" do
    FactoryGirl.create(:guide_edition, title: "First")

    FactoryGirl.create(:guide_edition, title: "Second")

    presenter = PrimaryListingPresenter.new(Edition, :all)
    presenter.filter_by_substring("Sec")
    assert_equal ["Second"], presenter.all.map(&:title)
  end

  test "can filter publications by title substring regardless of capitalization" do
    FactoryGirl.create(:guide_edition, title: "First")

    FactoryGirl.create(:guide_edition, title: "Second")

    presenter = PrimaryListingPresenter.new(Edition, :all)
    presenter.filter_by_substring("sec")
    assert_equal ["Second"], presenter.all.map(&:title)
  end

  test "Can handle regexp reserved characters for title filter" do
    FactoryGirl.create(:guide_edition, title: "First")

    FactoryGirl.create(:guide_edition, title: "(Second")

    presenter = PrimaryListingPresenter.new(Edition, :all)
    presenter.filter_by_substring("(sec")
    assert_equal ["(Second"], presenter.all.map(&:title)
  end
end
