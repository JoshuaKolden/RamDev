require 'ramdisk'
require 'fixtures/fakesysteminfo'

describe 'Ramdisk' do

  let(:temp_ramdisk_mountpoint) {"test/ramdisk_fake"}

  it "reads system info and finds ramdisks" do
    ramdisk = Ramdisk.new(temp_ramdisk_mountpoint, FakeSystemInfo)
    ramdisk.list.should eq(FakeSystemInfo.ramdisks)
  end

  it "confirms if a string is a mountpoint and mounted" do
    ramdisk = Ramdisk.new(temp_ramdisk_mountpoint, FakeSystemInfo)
    ramdisk.should be_mounted
  end

  it "allocates memory of a specified size" do
    ramdisk = Ramdisk.new(temp_ramdisk_mountpoint, FakeSystemInfo)
    ramdisk.allocate(10 * 1048576).should eq("/dev/disk666")
  end

  it "formats a memory image with the specified file system" do
    ramdisk = Ramdisk.new(temp_ramdisk_mountpoint, FakeSystemInfo)
    ramdisk.allocate(10 * 1048576)
    ramdisk.format("FakeRamdisk", :hfs).should eq(true)
  end

  it "mounts the ramdisk at the specified moutpoint" do
    ramdisk = Ramdisk.new(temp_ramdisk_mountpoint, FakeSystemInfo)
    ramdisk.allocate(10 * 1048576)
    ramdisk.format("FakeRamdisk",:hfs).should eq(true)
    ramdisk.mount.should eq(true)
  end

  it "un-mounts the ramdisk at the specified moutpoint" do
    ramdisk = Ramdisk.new(temp_ramdisk_mountpoint, FakeSystemInfo)
    ramdisk.allocate(10 * 1048576)
    ramdisk.format("FakeRamdisk",:hfs).should eq(true)
    ramdisk.mount.should eq(true)
    ramdisk.should be_mounted

    ramdisk.unmount.should eq(true)
  end

  it "removes ram allocation" do
    ramdisk = Ramdisk.new(temp_ramdisk_mountpoint, FakeSystemInfo)
    ramdisk.allocate(10 * 1048576)
    ramdisk.deallocate.should eq(true)
  end


end
