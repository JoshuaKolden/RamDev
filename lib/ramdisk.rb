require 'plist'

class SystemInfo

  def self.hdiutil(sectors)
    `hdiutil attach -nomount ram://#{sectors}`
  end

  def self.newfs_hfs(diskname, ramdisk)
    `newfs_hfs -v '#{diskname}' #{ramdisk}`
  end

  def self.mount(mountpoint, ramdisk)
    `mount -o noatime -t hfs #{ramdisk} #{mountpoint}`
  end

  def self.unmount(mountpoint)
    `umount -f #{mountpoint}`
  end

  def self.deallocate(ramdisk)
    `hdiutil detach #{ramdisk}`
    device = ramdisk[/\/*([^\/]*)$/,1]
    return "\"#{device}\" unmounted.\n\"#{device}\" ejected.\n"
  end

  def self.read_hdutil
    plist = Plist::parse_xml(`hdiutil info -plist`)

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


  # class that represents all information associated with a ram disk
class Ramdisk

  attr_accessor :system_interface, :mountpoint, :size, :name, :ramdisk

  def initialize(mountpoint, system_interface = SystemInfo)
    self.mountpoint = mountpoint
    self.system_interface = system_interface
  end

  def mounted?
    list.each do |i|
      return true if i[1] =~ /#{mountpoint}$/
    end
    return false
  end

  def list
    @list ||= system_interface.ramdisks
  end

  def ramdisk
    return @ramdisk if @ramdisk
    list.each do |i|
      return i[0] if i[1] =~ /#{mountpoint}$/
    end
    # else return nil
  end

  def allocate(size)
    sectors = size / 512
    self.ramdisk = system_interface.hdiutil(sectors).strip
  end

  def deallocate
    msg = system_interface.deallocate(ramdisk)
    if msg =~ /.*unmounted\./
      return true
    end
    throw "ramdisk failed to deallocate ramdisk with this message: #{msg}"
    return false
  end

  def format(drivename = "ramdev", fileSystemFormat = :hfs)
    self.name = drivename
    case fileSystemFormat
    when :hfs
      msg = system_interface.newfs_hfs(name,ramdisk)
      if msg =~ /Initialized .*#{ramdisk[/\/*([^\/]*)$/,1]} as a/
        return true
      else
        throw "ramdisk failed to format HFS volume #{ramdisk}"
      end
    else
      throw "ramdisk doesn't understand how to build #{fileSystemFormat} file system"
    end
    return flase
  end

  def mount
    msg = system_interface.mount(mountpoint, ramdisk)
    if msg == ""
      return true
    else
      throw "ramdisk failed to mount with this message: #{msg}"
      return false
    end
  end

  def unmount
    msg = system_interface.unmount(mountpoint)
    if msg == ""
      return true
    else
      throw "ramdisk failed to un-mount with this message: #{msg}"
      return false
    end
  end

  # def unmount(mountpoint)
  # end
end

