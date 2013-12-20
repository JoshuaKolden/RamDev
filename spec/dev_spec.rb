load 'dev'


describe SystemInfo do

  it "gets the size of system memory" do
    si = SystemInfo.new
    si.memory.should eq(25769803776)
  end

  # it "gets the user's home path"
  # it "gets the user's name"
  # it "creates a missing rc file"
  # it "loads an existing rc file"
end

describe RamDev do

  it "creates a ramdisk"

  it "copies paths from rc file to ramdisk"

  it "it launches a listen process"

end

