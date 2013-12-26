require 'ramdisk'
require 'ramdev'
# require 'ramdev_sync'

describe 'ramdev ' do

  # describe 'up' do

  #   let(:test_ramdisk_mountpoint_real) {"test/ramdisk_real"}
  #   let(:rcfile)  {YAML.load_file("spec/fixtures/ramdevrc")}
  #   let(:paths)   {rcfile["ramdisk"]["paths"]}
  #   let(:mountpoint) {rcfile["ramdisk"]["mountpoint"]}

  #   it "spins up a ramdisk" do
  #     run "ramdev up"
  #     ramdisk = Ramdisk.new(test_ramdisk_mountpoint_real)
  #     ramdisk.should be_mounted
  #   end

  #   it "copies, renames, and links folders to ramdrive" do
  #     run "ramdev up"
  #     path_in  = paths[0]["source"]
  #     path_out = mountpoint+"/"+paths[0]["source"][/([^\/]*)\/*$/,1]
  #     path_backup = paths[0]["source"]+"_ramdev"

  #     puts "path_in: #{path_in}"
  #     puts "path_out: #{path_out}"
  #     puts "path_backup: #{path_backup}"

  #     File.directory?(path_out).should eq(true)
  #     File.directory?(path_backup).should eq(true)
  #     File.symlink?(path_in).should eq(true)
  #   end

  #   it "starts ramdev_sync in the background" do
  #     run "ramdev up"
  #     ramdisk = Ramdisk.new(test_ramdisk_mountpoint_real)
  #     ramdisk_sync.should be_running
  #   end

  #   after(:each) do
  #     ramdisk = Ramdisk.new(test_ramdisk_mountpoint_real)
  #     if ramdisk.mounted?
  #       ramdisk.unmount
  #       ramdisk.deallocate
  #     end
  #   end

  # end

  describe "down" do

    it "spins down a disk" do
      run "ramdev down"
    end

  end

  def run(shell_command)

    args = shell_command.sub(/^ramdev /, '').shellsplit
    case args[0]
    when "up"
      rd = RamDev.new
      rd.build("spec/fixtures/ramdevrc", 10485760) #10MB
    when "down"
      rd = RamDev.new
      rd.unbuild("spec/fixtures/ramdevrc")
    end
  end

end
