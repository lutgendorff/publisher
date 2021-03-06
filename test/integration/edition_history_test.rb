require 'integration_test_helper'

class EditionHistoryTest < JavascriptIntegrationTest
  setup do
    setup_users
  end

  context "viewing the history and notes tab" do
    setup do
      @answer = FactoryGirl.create(:answer_edition, :state => "published")

      @answer.new_action(@author, Action::SEND_FACT_CHECK, {:comment => "first"})
      @answer.new_action(@author, Action::RECEIVE_FACT_CHECK, {:comment => "second"})
      @answer.new_action(@author, Action::PUBLISH, {:comment => "third"})

      assert_equal ["first", "second", "third"], @answer.actions.map(&:comment)

      @guide = @answer.build_clone(GuideEdition)

      @guide.new_action(@author, Action::SEND_FACT_CHECK, {:comment => "fourth"})
      @guide.new_action(@author, Action::RECEIVE_FACT_CHECK, {:comment => "fifth"})
      @guide.new_action(@author, Action::PUBLISH, {:comment => "sixth"})

      assert_equal ["fourth", "fifth", "sixth"], @guide.actions.map(&:comment)
    end

    should "have the first history actions visible" do
      visit "/editions/#{@guide.id}"
      click_on "History & Notes"

      assert page.has_css?('#edition-history div.panel:first-of-type div.panel-collapse.in')
    end

    should "hide actions when the edition title is clicked" do
      visit "/editions/#{@guide.id}"
      click_on "History & Notes"
      click_on "Edition 2"
      assert page.has_no_css?('#edition-history div.panel:first-of-type div.panel-collapse.in')
    end

    context "Important note" do
      should "be able to add a note" do
        visit "/editions/#{@guide.id}"
        click_on "History & Notes"
        fill_in "Important note", with: "This is an important note. Take note."
        click_on "Save important note"

        visit "/editions/#{@guide.id}"
        assert page.has_content? "This is an important note. Take note."

        click_on "History & Notes"
        assert_field_contains("This is an important note. Take note.", "Important note")
      end

      should "not be carried forward to new editions" do
        @edition = FactoryGirl.create(:answer_edition,
                                      :important_note => "This is an important note. Take note.",
                                      :state => "published")

        visit "/editions/#{@edition.id}"
        assert page.has_content? "This is an important note. Take note."

        click_on "Create new edition"
        assert page.has_no_content? "This is an important note. Take note."

        click_on "History & Notes"
        assert_field_contains("", "Important note")
      end
    end
  end
end
