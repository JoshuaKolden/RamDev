require 'etc'

class SystemInfo
  attr_reader :user, :home, :memory

  def initialize()
    @user = Etc.getlogin
    @home = Dir.home(user)

    r = `/usr/sbin/system_profiler SPHardwareDataType`.split("\n").collect { |s| s == "" ? nil : s.strip }.compact
    r = r.collect { |s| s.split(":").collect { |ss| ss.strip }}
    memstring = ""
    r.each do |i|
      if i[0] == "Memory"
        memstring = i[1]
        break
      end
    end
    @memory = memstring.match(/([0-9]+) GB/)[1].to_i * 1073741824
  end

end
