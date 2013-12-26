class FakeSystemInfo

  def self.hdiutil(sectors)
    # `hdiutil attach -nomount ram://#{sectors}`
    return ramdisks[0][0]
  end

  def self.newfs_hfs(diskname, ramdisk)
    #`newfs_hfs -v '#{diskname}' #{ramdisk}`
    # newfs_hfs: cannot create filesystem on /dev/rdisk14: No such file or directory
    "Initialized #{ramdisk} as a 10 MB case-insensitive HFS Plus volume"
  end

  def self.mount(mountpoint, ramdisk)
    #`mount -o noatime -t hfs /dev/disk12 ../../test/ramdisk_real`
      # Text only returned on error
      # mount: realpath /x/d/support/RamDev/test/ramdisk_rea: No such file or directory
    return ""
  end

  def self.unmount(mountpoint)
    #`umount -f #{mountpoint}`
    return ""
  end

  def self.deallocate(ramdisk)
    # `hdiutil detach #{ramdisk}`
     # "disk12" unmounted.
     # "disk12" ejected.
    device = ramdisk[/\/*([^\/]*)$/,1]
    return "\"#{device}\" unmounted.\n\"#{device}\" ejected.\n"
  end

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
