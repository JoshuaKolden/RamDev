require 'plist'

class SystemInfo

  def self.read_hdutil
    raise "hdutil system command not setup yet."
  end

  def self.ramdisks
    @@ramdisks ||= read_hdutil
  end

end

  # class that represents all information associated with a ram disk
class Ramdisk

  attr_accessor :systemInterface, :mountpoint

  def initialize(mountpoint, systemInterface = SystemInfo)
    self.mountpoint = mountpoint if mountpoint
    self.systemInterface = systemInterface
  end

  def mounted?(mountpoint)
    list.each do |i|
      return true if i[1] == mountpoint
    end
    return false
  end

  def list
    @list ||= systemInterface.ramdisks
  end

end
