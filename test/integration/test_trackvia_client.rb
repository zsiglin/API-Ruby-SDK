require 'minitest/autorun'
require 'minitest/unit'
require 'trackvia-api-sdk'
require 'logger'
require 'tempfile'
require 'uri'

# == Integration tests for the Trackvia API SDK
#
# Integration tests are dual purpose:
#
# 1. Provides documented usage patterns of the client
# 2. Provides client-library maintainers a set of tests to verify program correctness
#
# ===Setup before running
#
# Being a client to the Trackvia service, tests require a running Trackvia service.
#
# Before running tests, configure the following:
#
# 1. Create a Trackvia user/password, authenticated on every test setup.
# 2. Obtain a 3Scale API user_key, checked on every /openapi endpoint access.
# 3. Create an "Integration Testing" application in your target Trackvia environment
# 4. Create a table named "TestSupport" to read/write test records, having these fields:
#
#   Field Name       Field Type
#   ==========       ==========
#   firstName        Single Line (shortAnswer)
#   lastName         Single Line (shortAnswer)
#   email            Email
#   phone            Single Line (shortAnswer)
#   file1            Document
#
# Test setup uses the "TestSupport" table's default view, saving its identifier for test execution.  Most tests
# access data in the context of this view.
#
# === Running
#
# A Rakefile is provided, with a default task configured to run these integration tests.  However, you will need
# to export several environment variables before executing rake.  For example:
#
#   export TRACKVIA_USERNAME=tester
#   export TRACKVIA_PASSWORD=secret
#   export TRACKVIA_USER_KEY=1234abcd
#   export TRACKVIA_URI=https://go.trackvia.com:443/
#
# These settings accomplish several things:
#
#   1. Sets the base service URI to call => https://go.trackvia.com:443/
#   2. Authenticates using the given username/password credential => tester/secret
#   3. Passes the API key '1234abcd' on every API call
#
# Of course, your username, password and API key will be different values.
#
# Once set to good values, run the tests:
#
#   rake or rake test:integration
#
# Remember:
#  TRACKVIA_URI has the default value: https://go.trackvia.com:443/
#  You must provide values for: TRACKVIA_USERNAME, TRACKVIA_PASSWORD, and TRACKVIA_USER_KEY
#

module Trackvia
  class ClientIntegrationTest < Minitest::Unit::TestCase
    LOG = Logger.new('trackvia_test.log', 1)

    ############################################################################################################
    # Integration test parameters
    ############################################################################################################
    TEST_VIEW_NAME  =   'Default TestSupport View'
    TEST_USERNAME   =   ENV['TRACKVIA_USERNAME'] || fail("Set environment variable TRACKVIA_USERNAME first")
    TEST_PASSWORD   =   ENV['TRACKVIA_PASSWORD'] || fail("Set environment variable TRACKVIA_PASSWORD first")
    USER_KEY        =   ENV['TRACKVIA_USER_KEY'] || fail("Set environment variable TRACKVIA_USER_KEY first")
    SERVICE_URI     =   ENV['TRACKVIA_URI'] || 'https://go.trackvia.com:443/'

    uri = URI.parse(SERVICE_URI)
    SCHEME = uri.scheme
    HOST = uri.host
    PORT = uri.port
    BASE_PATH = uri.path

    TEST_ENV = { 'TEST_USERNAME' => TEST_USERNAME, 'TEST_PASSWORD' => TEST_PASSWORD, 'USER_KEY' => USER_KEY,
                 'SCHEME' => SCHEME, 'HOST' => HOST, 'PORT' => PORT, 'BASE_PATH' => BASE_PATH }

    ############################################################################################################

    def setup
      LOG.debug("Test environment => #{TEST_ENV}")

      @client = Trackvia::Client.new(scheme: SCHEME, host: HOST, port: PORT, base_path: BASE_PATH, user_key: USER_KEY)
      @client.authorize(TEST_USERNAME, TEST_PASSWORD)
      view = @client.get_view(TEST_VIEW_NAME)
      @test_view_id = view['id']
    end

    def single_record_batch
      # create a record for updating later
      records = []
      batch = { "data" => records }
      firstName = "Franklin #{Time.now.to_i}"
      record = {
          "firstName" => firstName,
          "lastName" => "Roosevelt",
          "email" => "fdr@gmail.com",
          "phone" => "303-555-1212"
      }
      records << record

      batch
    end

    def test_authorize_account_user
      @client.authorize(TEST_USERNAME, TEST_PASSWORD)
    end

    def test_get_view
      # force retry mechanism to execute
      @client.invalidate_auth_token

      view = @client.get_view(TEST_VIEW_NAME)

      LOG.debug("test_get_view(): expect a view object and got #{view}")

      assert !view.nil?
      assert !view['id'].nil?

      # test for a non-existent view
      view = @client.get_view('does not exist')

      LOG.debug("test_get_view(): expect no view object and got #{view}")

      assert view.nil?
    end

    def test_get_users
      # force retry mechanism to execute
      @client.invalidate_auth_token

      users = @client.get_users

      LOG.debug("test_get_users(): response contains users=#{users}")

      assert !users.nil?
      assert !users.empty?
    end

    def test_create_user
      email = "joe_#{Time.now.to_i}@example.com"

      # force retry mechanism to execute
      @client.invalidate_auth_token

      user = @client.create_user(email, 'Joe', 'Examples', 'MST')

      LOG.debug("test_create_user(): response contains user=#{user}")

      assert !user.nil?
    end

    def test_get_apps
      # force retry mechanism to execute
      @client.invalidate_auth_token

      apps = @client.get_apps

      LOG.debug("test_get_apps(): response contains apps=#{apps}")

      assert !apps.nil?
      assert !apps.empty?
    end

    def test_get_views
      # force retry mechanism to execute
      @client.invalidate_auth_token

      views = @client.get_views

      LOG.debug("test_get_views(): response contains views=#{views}")

      assert !views.nil?
      assert !views.empty?
    end

    def test_create_record
      records = []
      batch = { "data" => records }
      (1..5).each do
        firstName = "Johnny #{Time.now.to_i}"
        record = {
            "firstName" => firstName,
            "lastName" => "Dogooder",
            "email" => "jon.b.good@gmail.com",
            "phone" => "303-555-1212"
        }
        records << record
      end

      # force retry mechanism to execute
      @client.invalidate_auth_token

      created = @client.create_records(@test_view_id, batch)

      LOG.debug("test_create_records(): response contains #{created}")

      assert !created.nil?
      assert !created["data"].nil?
      assert !created["data"].empty?
    end

    def test_find_records
      # ensure there's at least a record
      batch = single_record_batch
      @client.create_records(@test_view_id, batch)

      # force retry mechanism to execute
      @client.invalidate_auth_token

      records = @client.find_records(@test_view_id, "", start: 0, max: 25)

      LOG.debug("test_find_records(): response contains records=#{records}")

      assert !records.nil?
      assert !records.empty?
    end

    def test_get_records
      # ensure there's at least a record
      batch = single_record_batch
      @client.create_records(@test_view_id, batch)

      # force retry mechanism to execute
      @client.invalidate_auth_token

      records = @client.get_records(@test_view_id)

      LOG.debug("test_get_records(): response contains records=#{records}")

      assert !records.nil?
      assert !records.empty?
    end

    def test_update_record
      # create a record for updating later
      batch = single_record_batch
      created = @client.create_records(@test_view_id, batch)

      # update this new record
      to_update = created["data"].at(0)
      id = to_update["id"]
      # FIXME: why can't the 'file1' field be updated, set to null value?
      to_update.delete("file1")
      updated_first_name = "Frederick Douglass #{Time.now.to_i}"
      to_update["firstName"] = updated_first_name

      begin
        # force retry mechanism to execute
        @client.invalidate_auth_token

        updated = @client.update_record(@test_view_id, id, to_update)

        assert !updated.nil?
        assert_equal updated_first_name, updated["data"].at(0)["firstName"]

      rescue Trackvia::ApiError => e
        log_trackvia_error(e)
        fail "unexpected exception - see trackvia_test.log"
      end
    end

    def test_delete_record
      # create a record for updating later
      batch = single_record_batch
      created = @client.create_records(@test_view_id, batch)

      # delete the record
      to_delete = created["data"].at(0)
      id = to_delete["id"]

      # force retry mechanism to execute
      @client.invalidate_auth_token

      @client.delete_record(@test_view_id, id)

      # confirm it's been wiped.
      verified = @client.get_record(@test_view_id, id)

      assert verified.nil?
    end

    def test_add_get_delete_file

      # create a record for updating
      batch = single_record_batch
      created = @client.create_records(@test_view_id, batch)

      assert !created.nil?
      assert_equal 1, created["totalCount"]

      created_id = created["data"].at(0)["id"]

      begin
        # 1) test file creation

        # create a temp file for upload
        file = Tempfile.new("trackvia-client")
        begin
          file.write("Singing in the rain, ain't so much fun, as being done.")
        ensure
          file.close unless file.nil?
        end

        begin
          # force retry mechanism to execute
          @client.invalidate_auth_token

          updated = @client.add_file(@test_view_id, created_id, "file1", file.path)

          assert !updated.nil?
          assert !updated["data"]["file1"].nil?
        ensure
          file.unlink unless file.nil?
        end

        # 2) test file retrieval

        save_path = "test-output-#{Time.now.to_i}.txt"
        assert !File.exist?(save_path)

        # force retry mechanism to execute
        @client.invalidate_auth_token

        @client.get_file(@test_view_id, created_id, "file1", save_path)

        begin
          assert File.exist?(save_path)
        ensure
          File.delete(save_path) unless !File.exist?(save_path)
        end

        # 3) test file deletion

        retrieved = @client.get_record(@test_view_id, created_id)

        assert !retrieved["data"]["file1"].nil?

        # force retry mechanism to execute
        @client.invalidate_auth_token

        @client.delete_file(@test_view_id, created_id, "file1")

        retrieved = @client.get_record(@test_view_id, created_id)

        assert retrieved["data"]["file1"].nil?
      ensure
        @client.delete_record(@test_view_id, created_id)
      end
    end

    def test_trackvia_api_error
      begin
        does_not_exist_id = -1
        @client.delete_file(@test_view_id, does_not_exist_id, 'does_not_exist_filename')

      rescue Trackvia::ApiError => e

        log_trackvia_error(e)

        assert e.code == '404'
        assert e.name == 'notFound'
      rescue
        fail "unexpected non-Trackvia::ApiError"
      end
    end

    def test_non_trackvia_api_error
      begin
        ignore_id = -1
        ignore_filename = 'file1'
        @client.add_file(@test_view_id, ignore_id, ignore_filename, '/path/does/not/exist')

      rescue Trackvia::ApiError
        fail "unexpected Trackvia::ApiError exception: #{e.inspect}"
      rescue
        # do nothing
      end
    end

    def test_refresh_token
      # show auth works
      users = @client.get_users
      assert !users.nil?

      begin
        @client.refresh_token
      rescue => e
        fail "unexpected exception: #{e.inspect}"
      end
    end

    def test_automatic_token_refresh
      # show auth works
      users = @client.get_users
      assert !users.nil?

      begin
        # force retry mechanism to execute
        @client.invalidate_auth_token

        users = @client.get_users

        assert !users.nil?

      rescue => e
        fail "unexpected exception: #{e.inspect}"
      end
    end

    def log_trackvia_error(e)
      LOG.debug "Trackvia exception information"
      LOG.debug " Errors:      #{e.errors}"
      LOG.debug " Message:     #{e.message}"
      LOG.debug " Name:        #{e.name}"
      LOG.debug " Code:        #{e.code}"
      LOG.debug " Backtrace:   #{e.backtrace}"
      LOG.debug " Error:       #{e.error}"
      LOG.debug " Description: #{e.description}"
    end
  end
end
