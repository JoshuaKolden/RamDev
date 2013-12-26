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

class RamDev
  def self.create(command, *args)
    case command
    when "up"
      puts "DevRam up"
    end

  end
end

describe 'ramdev command' do

  describe 'up' do

    let(:temp_ramdisk_mountpoint) {"test/ramdisk_moutpoint"}

    it "spins up a ramdisk" do
      run "ramdev up --test"
      ramdisk = Ramdisk.new(temp_ramdisk_mountpoint, FakeSystemInfo)
      ramdisk.should be_mounted(temp_ramdisk_mountpoint)
    end

    # after(:each) do
    #   RamDev.tear_down(temp_ramdisk_mountpoint)
    # end

  end

  def run(shell_command)
    args = shell_command.sub(/^ramdev /, '').shellsplit
    RamDev.create(*args)
  end

end
