require 'fileutils'
require 'ramdisk'
require 'ramdev'
require 'ramdev_sync'
require 'rainbow'

describe 'ramdev' do

  let(:test_ramdisk_mountpoint_real) {"test/ramdisk_real"}
  let(:rcfile)  {"spec/fixtures/ramdevrc"}
  let(:rc_hash)  {YAML.load_file(rcfile)}
  let(:paths)   {rc_hash["ramdisk"]["paths"]}
  let(:mountpoint) {rc_hash["ramdisk"]["mountpoint"]}

  before(:all) do
    FileUtils.mkdir_p("test/ramdisk_real")
    FileUtils.mkdir_p("test/ramdisk")
    FileUtils.mkdir_p("test/real_source1")
    FileUtils.mkdir_p("test/real_source2")
    FileUtils.mkdir_p("test/real_source3")
    FileUtils.mkdir_p("test/test_source")
    FileUtils.mkdir_p("test/test_source2")
    FileUtils.touch("test/test_source/testfile.md")
    FileUtils.touch("test/test_source2/test2.md")

    FileUtils.touch("test/real_source1/real_source1_file1")
    FileUtils.touch("test/real_source1/real_source1_file2")
    FileUtils.touch("test/real_source1/real_source1_file3")
    FileUtils.touch("test/real_source2/real_source2_file1")
    FileUtils.touch("test/real_source2/real_source2_file2")
    FileUtils.touch("test/real_source2/real_source2_file3")
    FileUtils.touch("test/real_source3/real_source3_file1")
    FileUtils.touch("test/real_source3/real_source3_file2")
    FileUtils.touch("test/real_source3/real_source3_file3")
  end

  describe 'up' do

    it "spins up a ramdisk" do
      run "ramdev up"
      ramdisk = Ramdisk.new(test_ramdisk_mountpoint_real)
      ramdisk.should be_mounted
    end

    it "copies, renames, and links folders to ramdrive" do
      run "ramdev up"
      path_in  = paths[0]["source"]
      path_out = mountpoint+"/"+paths[0]["source"][/([^\/]*)\/*$/,1]
      path_backup = paths[0]["source"]+"_ramdev"

      File.directory?(path_out).should eq(true)
      File.directory?(path_backup).should eq(true)
      File.symlink?(path_in).should eq(true)
    end

    it "starts ramdev_sync in the background" do
      run "ramdev up"
      ramdisk_sync = RamDevSync.new(File.open(rcfile))
      ramdisk_sync.should be_running
    end

    after(:each) do
      run "ramdev down"
    end

  end

  describe "down" do

    before(:each) do
      run "ramdev up"
    end

    it "spins down a ramdisk" do
      ramdisk = Ramdisk.new(test_ramdisk_mountpoint_real)
      ramdisk.should be_mounted
      run "ramdev down"
      ramdisk.should_not be_mounted
    end

  end

  describe "fix" do

    before(:each) do
      run "ramdev up"
    end

    it "fixes files paths if they break" do
      sleep 2
      kill_ramdev
      run "ramdev fix"

      path_in  = paths[0]["source"]
      path_backup = paths[0]["source"]+"_ramdev"

      File.exists?(path_in).should eq(true)
      File.symlink?(path_in).should eq(false)
      File.exists?(path_backup).should eq(false)

    end

    it "doesn't run if ramdev_sync is running" do
      run "ramdev fix"

      path_in  = paths[0]["source"]
      path_backup = paths[0]["source"]+"_ramdev"
      File.exists?(path_in).should eq(true)
      File.symlink?(path_in).should eq(true)
      File.exists?(path_backup).should eq(true)
    end

    after(:each) do
      run "ramdev down -f"
    end

  end

  after(:all) do
    FileUtils.rm_rf("test")
  end

  def kill_ramdev
    @store = PStore.new("/tmp/ramdev.pstore")
    pid = @store.transaction do |s|
      s["pid"]
    end
    puts "Killing process #{pid}".color(:red)
    Process.kill(9, pid)
  end

  def run(shell_command)
    args = shell_command.sub(/^ramdev /, '').shellsplit

    if args[0] == "up"
      puts "ruby -Ilib bin/ramdev up #{args.join(' ')} -r#{rcfile} -m 10MB"
      system("ruby -Ilib bin/ramdev up #{args.join(' ')} -r#{rcfile} -m 10MB")
    else
      puts "ruby -Ilib bin/ramdev #{args.join(' ')} -r#{rcfile}"
      system("ruby -Ilib bin/ramdev #{args.join(' ')} -r#{rcfile}")
    end
    # when "down"
    #   rd = RamDev.new
    #   if args[1] == "-f"
    #     rd.unbuild(rcfile, force: true)
    #   else
    #     rd.unbuild(rcfile)
    #   end
    # when "fix"
    #   rd = RamDev.new
    #   rd.fix(rcfile)
    # end
  end

end
