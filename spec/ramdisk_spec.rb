require 'ramdisk'

class FakeSystemInfo

  def self.read_hdutil
    plist = Plist::parse_xml("spec/fixtures/hdiutil_info_output.plist")

    diskImages = []
    plist.each do |n|
      diskImages.concat n[1] if n[0] == "images"
    end

    response = []
    diskImages.each do |i|
      if i["image-path"] =~ /^ram\:\/\//
        response.push([i["system-entities"][0]["dev-entry"], i["system-entities"][0]["mount-point"]])
      end
    end

    response
  end

  def self.ramdisks
    @@ramdisks ||= read_hdutil
  end


end

describe 'Ramdisk' do

  let(:temp_ramdisk_mountpoint) {"test/ramdisk_moutpoint"}

  it "reads system info and finds ramdisks" do
    ramdisk = Ramdisk.new(temp_ramdisk_mountpoint, FakeSystemInfo)
    ramdisk.list.should eq(FakeSystemInfo.ramdisks)
  end

  it "confirms if a string is a mountpoint and mounted" do
    ramdisk = Ramdisk.new(temp_ramdisk_mountpoint, FakeSystemInfo)
    ramdisk.mounted?(temp_ramdisk_mountpoint).should eq(true)
  end

end
