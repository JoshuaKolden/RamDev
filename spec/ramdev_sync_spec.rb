require 'fileutils'

require 'ramdev_sync'

describe RamDevSync do

  before(:each) do
    @watcher = RamDevSync.new ( File.open( "spec/fixtures/devrc") )
  end

  it "it loads rc file and parses paths" do
    @watcher.paths.length.should eq(2)
  end

  it "has correct path for watch target" do
    @watcher.watchpaths[0][0].should eq("test/ramdisk/test_source")
      #ignore trailing '/'
    @watcher.watchpaths[1][0].should eq("test/ramdisk/test_source2")
    @watcher.watchpaths[2][0].should eq("test/ramdisk/other_path/test_source3")
  end

  it "has correct path for rsync target" do
    @watcher.watchpaths[0][1].should eq("test/test_source_backup_DEV")
    @watcher.watchpaths[1][1].should eq("test/test_source2_backup_DEV")
    @watcher.watchpaths[2][1].should eq("test/test_source3_backup_DEV")
  end

  it "listens for changes in watchpaths" do
    @watcher.listen
    @watcher.listener.listen?.should eq(true)
  end

  it "should call rsync when watchpaths change" do
    @watcher.should_receive(:rsync)
    @watcher.listen
    FileUtils.touch('test/ramdisk/test_source/testfile.md')
    sleep 1
  end

end
