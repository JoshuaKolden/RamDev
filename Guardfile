# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard :rspec, :cmd => "rspec --color --tty" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }

  # watch('dev') { "spec/dev_spec.rb" }
  # watch('dev_sync_ramdisk') { "spec/dev_sync_ramdisk_spec.rb" }
  # watch('rspec/fixtures/devrc') { "spec/dev_sync_ramdisk_spec.rb" }


end

