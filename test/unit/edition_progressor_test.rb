require 'test_helper'
require 'edition_progressor'

# The EditionProgressor expects to receive a WorkflowActor.
# In our system that's usually a User object, but it doesn't
# have to be. The DummyActor implements just enough behaviour
# to operate as a WorkflowActor without the overhead of creating
# a (database-persisted) User.
class DummyActor
  include WorkflowActor

  def id
    "fake-id"
  end
end

class EditionProgressorTest < ActiveSupport::TestCase
  setup do
    @laura = DummyActor.new
    @guide = FactoryGirl.create(:guide_edition, panopticon_id: FactoryGirl.create(:artefact).id)
    stub_register_published_content
  end

  test "should be able to progress an item" do
    @guide.update_attribute(:state, :ready)

    activity = {
      :request_type       => "send_fact_check",
      :comment            => "Blah",
      :email_addresses    => "user@example.com",
      :customised_message => "Hello"
    }

    command = EditionProgressor.new(@guide, @laura)
    assert command.progress(activity)

    @guide.reload
    assert_equal 'fact_check', @guide.state
  end

  test "should not progress to fact check if the email addresses were blank" do
    @guide.update_attribute(:state, :ready)

    activity = {
      :request_type       => "send_fact_check",
      :comment            => "Blah",
      :email_addresses    => "",
      :customised_message => "Hello"
    }

    command = EditionProgressor.new(@guide, @laura)
    refute command.progress(activity)
  end

  test "should not progress to fact check if the email addresses were invalid" do
    @guide.update_attribute(:state, :ready)

    activity = {
      :request_type       => "send_fact_check",
      :comment            => "Blah",
      :email_addresses    => "nouseratexample.com",
      :customised_message => "Hello"
    }

    command = EditionProgressor.new(@guide, @laura)
    refute command.progress(activity)
  end

  context "scheduled_publishing" do
    teardown do
      ScheduledPublisher.jobs.clear
      Sidekiq::ScheduledSet.new.clear
    end

    should "enqueue a job for sidekiq to perform later" do
      Sidekiq::Testing.fake! do
        @guide.update_attribute(:state, :ready)
        publish_at = 1.day.from_now
        activity = { request_type: "schedule_for_publishing", comment: "schedule!", publish_at: publish_at }

        command = EditionProgressor.new(@guide, @laura)
        assert command.progress(activity)

        assert_equal publish_at.to_i, ScheduledPublisher.jobs.first['at'].to_i
      end
    end

    should "dequeue a scheduled job" do
      Sidekiq::Testing.disable! do
        publish_at = 1.day.from_now
        @guide.update_attributes(state: :scheduled_for_publishing, publish_at: publish_at)
        ScheduledPublisher.perform_at(publish_at, @guide.id.to_s)

        activity = { request_type: "cancel_scheduled_publishing", comment: "stop!" }
        command = EditionProgressor.new(@guide, @laura)
        assert command.progress(activity)

        assert_equal 0, Sidekiq::ScheduledSet.new.size
      end
    end
  end
end
