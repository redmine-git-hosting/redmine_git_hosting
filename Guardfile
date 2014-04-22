# More info at https://github.com/guard/guard#readme

guard :rspec, :cmd => "bundle exec rspec --color --format nested --fail-fast" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end

guard :spork, :rspec_env => { 'RAILS_ENV' => 'test' }, :rspec_port => 9090 do
  watch(%r{^lib/(.+)\.rb$})
  watch('Gemfile.lock')
  watch('spec/spec_helper.rb') { :rspec }
end
