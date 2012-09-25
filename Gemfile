source "http://rubygems.org"

group :test do
  gem 'rake'
  # Patched version of rspec-core that allows win32console to be used for color
  gem 'rspec-core', :git => "https://github.com/L2G/rspec-core",
                    :branch => "bring-back-win32console"
  gem 'rspec'
  gem 'fuubar'
  gem 'cloudservers'
  gem 'ir_b'
  gem 'minitar'

  # for color test output in Windows
  if /mingw|mswin/ === Config::CONFIG['host_os']
    gem 'win32console'
  end
end
