require 'fileutils'

require 'ramdev_sync'

describe RamDevSync do

  let(:watcher) {RamDevSync.new ( File.open( "spec/fixtures/ramdevrc_noMount") )}

  before(:all) do
    FileUtils.mkdir_p("test/ramdisk")
    FileUtils.mkdir_p("test/ramdisk/test_source")
    FileUtils.mkdir_p("test/ramdisk/test_source2")
    FileUtils.mkdir_p("test/ramdisk/other_path/test_source3")
  end

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
    ## Other tests may slow this process down so we pause
    ## at the beginning to let the system flush IO from previous test.
    watcher2 = RamDevSync.new ( File.open( "spec/fixtures/ramdevrc_noMount") )
    watcher2.should_receive(:rsync)
    watcher2.listen
    sleep 1
    FileUtils.touch('test/ramdisk/test_source/testfile.md')
    sleep 1 # one second tolerance, failure to sync within 1 sec is a fail!
  end

  after(:all) do
    FileUtils.rm_rf("test")
  end

  ##TODO tests for forking

end
