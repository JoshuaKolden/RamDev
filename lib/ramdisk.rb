require 'plist'

class SystemInfo

  def self.hdiutil(sectors)
    `hdiutil attach -nomount ram://#{sectors}`
  end

  def self.newfs_hfs(diskname, ramdisk)
    `newfs_hfs -v '#{diskname}' #{ramdisk}`
  end

  def self.mount(mountpoint, ramdisk)
    system("mount -o noatime -t hfs #{ramdisk} #{mountpoint}")
  end

  def self.sudomount(mountpoint, ramdisk)
    system("sudo mount -o noatime -t hfs #{ramdisk} #{mountpoint}")
  end

  def self.unmount(mountpoint)
    system("umount -f #{mountpoint}")
  end

  def self.sudounmount(mountpoint, ramdisk)
    system("sudo hdiutil eject -force #{mountpoint}")
  end

  def self.deallocate(ramdisk)
    raise "Deallocate called with nil device." if ramdisk.nil?
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
      # cannot be ||= because state may have changed.
    @@ramdisks = read_hdutil
  end

end


  # class that represents all information associated with a ram disk
class Ramdisk

  attr_accessor :system_interface, :mountpoint, :size, :name, :ramdisk

  def initialize(mountpoint, system_interface = SystemInfo)
    self.mountpoint = mountpoint
    self.system_interface = system_interface
  end

  def unmounted=(m)
    @unmounted = m
  end

  def unmounted
    @unmounted ||= []
  end

  def mounted?
    list.each do |i|
      return true if i[1] =~ /#{mountpoint}$/
    end
    return false
  end

  def list
      # cannot be ||= because state may have changed.
    @list = system_interface.ramdisks
  end

  def ramdisk=(device)
    @ramdisk = device
  end

  def ramdisk
    return @ramdisk if !@ramdisk.nil?
    list.each do |i|
      if i[1] =~ /#{mountpoint}$/
        @ramdisk = i[0]
        break
      end
    end
    @ramdisk
  end

  def allocate(size)
    sectors = size / 512
    self.ramdisk = system_interface.hdiutil(sectors).strip
  end

  def deallocate
    unmounted.each do |u|
      msg = system_interface.deallocate(u)
      if !msg =~ /.*unmounted\./
        raise "ramdisk: #{u} failed to deallocate ramdisk with this message: #{msg}"
      end
    end
    unmounted = []
    return true
  end

  def format(drivename = "ramdev", fileSystemFormat = :hfs)
    self.name = drivename
    case fileSystemFormat
    when :hfs
      msg = system_interface.newfs_hfs(name,ramdisk)
      if msg =~ /Initialized .*#{ramdisk[/\/*([^\/]*)$/,1]} as a/
        return true
      else
        raise "ramdisk failed to format HFS volume #{ramdisk}"
      end
    else
      raise "ramdisk doesn't understand how to build #{fileSystemFormat} file system"
    end
    return flase
  end

  def mount
    if system_interface.mount(mountpoint, ramdisk)
      return true
    else
      puts "Unable to mount, trying again with 'sudo'"
      if system_interface.sudomount(mountpoint, ramdisk)
        return true
      else
        puts "ramdisk failed to mount"
        return false
      end
    end
  end

  def unmount
    unmounted_device = ramdisk
    if system_interface.unmount(mountpoint)
      unmounted.push(unmounted_device)
      return true
    else
      puts "Unable to unmount, trying again with 'sudo'."
      if system_interface.sudounmount(mountpoint, unmounted_device)
        return true
      else
        puts "ramdisk failed to un-mount."
        return false
      end
    end
  end

  # def unmount(mountpoint)
  # end
end

