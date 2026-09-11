require "capybara/rspec"
require "selenium-webdriver"
require "warden/test/helpers"

# System specs need a real browser: the movement forms enable and reveal their
# fields from Stimulus, so a rack-test driver would see everything disabled.
Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--disable-gpu")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--window-size=1400,1600")

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_max_wait_time = 5

module SystemAuthHelpers
  # Warden test mode rather than the sign-in form: submitting the form through
  # Turbo races the next `visit` and makes every spec intermittently land on
  # the login page. Form login itself is covered in spec/requests/auth_spec.rb.
  def sign_in_as(role)
    user = create(:user, role)
    login_as(user, scope: :user)
    user
  end
end

RSpec.configure do |config|
  config.include Warden::Test::Helpers, type: :system
  config.include SystemAuthHelpers, type: :system

  config.before(:each, type: :system) do
    driven_by :headless_chrome
    Warden.test_mode!
  end

  # The movement cart lives in the session cookie, so a cart left open by one
  # example hides the "Iniciar nueva ..." button in the next one.
  #
  # Capybara.reset_sessions! alone is not enough: it navigates to about:blank
  # before clearing, and Chrome has no cookie context there, so the cookie
  # survives. Clear it while the browser is still on the application host.
  config.after(:each, type: :system) do
    Capybara.current_session.driver.browser.manage.delete_all_cookies if page.current_url.start_with?("http")
    Capybara.reset_sessions!
    Warden.test_reset!
  end
end
