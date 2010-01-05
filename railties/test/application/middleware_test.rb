require 'isolation/abstract_unit'

module ApplicationTests
  class MiddlewareTest < Test::Unit::TestCase
    include ActiveSupport::Testing::Isolation

    def setup
      build_app
      boot_rails
      FileUtils.rm_rf "#{app_path}/config/environments"
    end

    test "default middleware stack" do
      boot!

      assert_equal [
        "ActionDispatch::Static",
        "Rack::Lock",
        "Rack::Runtime",
        "ActionDispatch::ShowExceptions",
        "ActionDispatch::Callbacks",
        "ActionDispatch::Session::CookieStore",
        "ActionDispatch::ParamsParser",
        "Rack::MethodOverride",
        "Rack::Head",
        "ActionDispatch::StringCoercion",
        "ActiveRecord::ConnectionAdapters::ConnectionManagement",
        "ActiveRecord::QueryCache"
      ], middleware
    end

    test "removing activerecord omits its middleware" do
      use_frameworks []
      boot!
      assert !middleware.include?("ActiveRecord::ConnectionAdapters::ConnectionManagement")
      assert !middleware.include?("ActiveRecord::QueryCache")
    end

    test "removes lock if allow concurrency is set" do
      add_to_config "config.action_controller.allow_concurrency = true"
      boot!
      assert !middleware.include?("Rack::Lock")
    end

    test "removes static asset server if serve_static_assets is disabled" do
      add_to_config "config.serve_static_assets = false"
      boot!
      assert !middleware.include?("ActionDispatch::Static")
    end

    test "use middleware" do
      use_frameworks []
      add_to_config "config.middleware.use Rack::Config"
      boot!
      assert_equal "Rack::Config", middleware.last
    end

    private
      def boot!
        require "#{app_path}/config/environment"
      end

      def middleware
        AppTemplate::Application.instance.middleware.active.map(&:klass).map(&:name)
      end
  end
end
