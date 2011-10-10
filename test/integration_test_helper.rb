require 'test_helper'
require 'capybara/rails'

class ActionDispatch::IntegrationTest
  include Capybara::DSL

  teardown do
    DatabaseCleaner.clean
  end
end

class MockImminence

  def initialize(app)
    @app = app
  end

  def call(env)
    if env['PATH_INFO'] == '/places/registry-offices.json'
      return [ 200, {}, "[]" ]
    else
      @app.call(env)
    end
  end
end

Capybara.default_driver = :webkit
Capybara.app = Rack::Builder.new do
 map "/" do
   run Capybara.app
 end
end