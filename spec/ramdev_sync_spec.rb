require 'fileutils'

require 'ramdev_sync'

describe RamDevSync do

  let(:watcher) {RamDevSync.new ( File.open( "spec/fixtures/ramdevrc_noMount") )}
  # before(:each) do
  #   @watcher =
  # end

  it "it loads rc file and parses paths" do
    watcher.paths.length.should eq(3)
  end

  it "has correct path for watch target" do
    watcher.watchpaths[0][0].should eq("test/ramdisk/test_source")
      #ignore trailing '/'
    watcher.watchpaths[1][0].should eq("test/ramdisk/test_source2")
    watcher.watchpaths[2][0].should eq("test/ramdisk/other_path/test_source3")
  end

  it "has correct path for rsync target" do
    watcher.watchpaths[0][1].should eq("test/test_source_ramdev")
    watcher.watchpaths[1][1].should eq("test/test_source2_ramdev")
    watcher.watchpaths[2][1].should eq("test/test_source3_ramdev")
  end

  it "listens for changes in watchpaths" do
    watcher.listen
    watcher.listener.listen?.should eq(true)
  end

  it "calls rsync when watchpaths change" do
    watcher.should_receive(:rsync)
    watcher.listen
    FileUtils.touch('test/ramdisk/test_source/testfile.md')
    sleep 1 # one second tolerance, failure to sync within 1 sec is a fail!
  end

  ##TODO tests for forking

end
