require 'ramdisk'
require 'ramdev_sync'
require 'pstore'
require 'fileutils'

class RamDev
  attr_reader :diskname, :ramdisk, :mountpoint
    #path to rc file, and 10 mb default size.

  def initialize(sufix = "_ramdev")
    @backupSuffix = sufix
    @store = PStore.new("/tmp/ramdev.pstore")
  end

  def unbuild(rcpath)
    #TODO force sync
    load_runcom(rcpath)

    if !restore_folders
      puts "Ramdisk shutdown was halted because there was a problem restoring folders."
      puts "Eject the ramdisk manually once you've sorted out any issues."
      return
    end
    ramdisk = Ramdisk.new(mountpoint)

    pid = @store.transaction do |s|
      s["pid"]
    end

    kill("QUIT", pid) if pid

    ramdisk.unmount
    ramdisk.deallocate

    "RAM disk removed at #{mountpoint}"
  end

  def memory
    if @memory.nil?
      r = `/usr/sbin/system_profiler SPHardwareDataType`.split("\n").collect { |s| s == "" ? nil : s.strip }.compact
      r = r.collect { |s| s.split(":").collect { |ss| ss.strip }}
      memstring = ""
      r.each do |i|
        memstring = i[1] if i[0] == "Memory"
      end
      @memory = memstring.match(/([0-9]+) GB/)[1].to_i * 1073741824
    end
    @memory
  end

  def build(rcpath, size = nil)
    @size = size
    @size ||= memory / 2
    load_runcom(rcpath)


    ramdisk = Ramdisk.new(mountpoint)

    puts "Allocating ramdisk size: #{@size / 1073741824} GB "
    if( !ramdisk.allocate(@size) )
      puts "Allocation failed. Size: #{@size} bytes"
      exit
    end
    if( !ramdisk.format(diskname, :hfs) )
      puts "Failed to format disk."
      exit
    end
    if( !ramdisk.mount )
      puts "Failed to mount at #{mountpoint}"
      ramdisk.deallocate
      exit
    end


    copy_folders if valid_paths?

    puts "RAM disk mounted at #{mountpoint}"

    #FIX: Not compatible with Windows:




    fork do
      puts "ramdev_sync pid #{Process.pid}"

      @store.transaction do |s|
        s["pid"] = Process.pid
      end

      trap("QUIT") do
        puts "Interrupted by signal, ramdev_sync will stop now."
        exit
      end

      watcher = RamDevSync.new(File.open(rcpath))
      watcher.listen
      puts "ramdev_sync listening..."
      sleep
    end

  end

  def load_runcom(rcfile)

    return if @loaded == true
    rc = YAML.load(File.open(rcfile))
    if rc.nil?
      @mountpoint = "/ramdev"
      @diskname   = "ramdev"
      @paths      ||= []
      @paths.push({ source: Dir.pwd, destination: "" })
    else
      @mountpoint = rc["ramdisk"]["mountpoint"]
      @diskname  = rc["ramdisk"]["name"]
        # TODO: Get size of paths and create default ramdisk size based it (2x)
      @paths     = rc["ramdisk"]["paths"]
      @size      ||= rc["ramdisk"]["size"] if rc["ramdisk"]["size"]
      @loaded    = true
    end

  end

  def valid_paths?
    @paths.each do |p|
      src   = p["source"].gsub(/\/+$/,"")
      if File.exist?("#{src}#{@backupSuffix}")
        puts "A backup already exists for: '#{src}' at: '#{src}#{@backupSuffix}'"
        return false
      end
    end
    return true
  end

  def restore_folders
    @paths.each do |p|
      src   = p["source"].gsub(/\/+$/,"")

      if !File.exists? src+@backupSuffix || !File.symlink?(src)
        puts "Referenced files don't appear to be linked properly. "
        return false
      end
    end

    @paths.each do |p|
      src   = p["source"].gsub(/\/+$/,"")
      FileUtils.safe_unlink src
      FileUtils.move(src+@backupSuffix, src)
    end
    true
  end

  def copy_folders
    @paths.each do |p|
      src   = p["source"].gsub(/\/+$/,"")
      next if src.nil? || src.length < 1
      des   = p["destination"].gsub(/\/+$/,"").gsub(/^\/+/,"")
      name  = src.match(/([^\/\\]+)$/)[1]
      if des.length > 0
        des = mountpoint+"/#{des}"
        des = des.gsub(/\/{2,}/,"/")
      else
        des = mountpoint
      end
      des = File.absolute_path(des)
      print "Copying #{src}...\n"
      FileUtils.mkdir_p(des) unless File.exist?(des)
      IO.popen("rsync --progress -ra #{src} #{des}") do |rsync_io|
        until rsync_io.eof?
          line = rsync_io.readline
          line = line.gsub("\n","")
          next unless line =~ /to-check/
          m = line.match(/to-check=([0-9]+)\/([0-9]+)/)
          scale = (m[1].to_f / m[2].to_f)
          prog = "#{[9613].pack('U*')}" * ( (1.0 - scale) * 30.0).round

          prog += " " * (scale * 30.0).round
          print "#{prog}| #{des}/#{name}  "
          print "\r"
        end
      end
      print "\n"

      FileUtils.move(src, src+@backupSuffix)

      puts "Linking: #{name}"

      File.symlink("#{des}/#{name}", src)
    end
  end

end


# require 'etc'
# require 'yaml'
# require 'fileutils'


#class RamDev
  #-------
  # attr_reader :ramDiskSize, :sectors

  # def initialize
  #   @backupSuffix = "_backup_DEV"
  #   @systemInfo = SystemInfo.new
  #   @ramDiskSize = (@systemInfo.memory / 2)
  # end

  # def build(diskname = "x", mountpoint = "/x", paths = [])
  #   unbuild(diskname, mountpoint, paths)
  #   build = false

  #   if @ramDiskSize > 0
  #     @sectors = @ramDiskSize / 512

  #     ramdisk = `hdid -nomount ram://#{sectors}`.strip
  #     system "newfs_hfs -v '#{diskname}' #{ramdisk}"
  #     build = system "sudo mount -o noatime -t hfs #{ramdisk} #{mountpoint}"
  #     print "RAM disk mounted at #{mountpoint}\n"

  #     if build
  #       paths.each do |p|
  #         print "#{p}\n"
  #         src   = p["source"].gsub(/\/+$/,"")
  #         validate(src)
  #       end
  #       paths.each do |p|
  #         src   = p["source"].gsub(/\/+$/,"")
  #         next if src.nil? || src.length < 1
  #         des   = p["destination"].gsub(/\/+$/,"").gsub(/^\/+/,"")
  #         name  = src.match(/([^\/\\]+)$/)[1]
  #         if des.length > 0
  #           des = mountpoint+"/#{des}"
  #           des = des.gsub(/\/{2,}/,"/")
  #         else
  #           des = mountpoint
  #         end
  #         print "Copying #{src}...\n"
  #         FileUtils.mkdir_p(des) if !File.exist?(des)
  #         IO.popen("rsync --progress -ra #{src} #{des}") do |rsync_io|
  #           until rsync_io.eof?
  #             line = rsync_io.readline
  #             line = line.gsub("\n","")
  #             next unless line =~ /to-check/
  #             m = line.match(/to-check=([0-9]+)\/([0-9]+)/)
  #             scale = (m[1].to_f / m[2].to_f)
  #             prog = "#{[9613].pack('U*')}" * ( (1.0 - scale) * 30.0).round

  #             prog += " " * (scale * 30.0).round
  #             print "#{prog}| #{des}/#{name}  "
  #             print "\r"
  #           end
  #         end
  #         print "\n"

  #         FileUtils.move(src, src+@backupSuffix)

  #         puts "Linking: #{name}"

  #         File.symlink("#{des}/#{name}", src)
  #       end
  #     end
  #   end
  # end

  # def unbuild(diskname = "x", mountpoint = "/x", paths = [])
  #   paths.each do |p|
  #     print "#{p}\n"
  #     src   = p["source"].gsub(/\/+$/,"")
  #     next if src.nil? || src.length < 1
  #     des   = p["destination"].gsub(/\/+$/,"").gsub(/^\/+/,"")
  #     name  = src.match(/([^\/\\]+)$/)[1]

  #     if File.exists? src+@backupSuffix
  #       FileUtils.safe_unlink src if File.symlink?(src)
  #       if File.exist?(src)
  #         print "Conflict between #{src} and #{src+@backupSuffix}"
  #         next
  #       end
  #       FileUtils.move(src+@backupSuffix, src)
  #     end
  #   end

  #   unmount = `diskutil unmount force #{mountpoint}`
  #   if unmount =~ /Volume .* on (.*) unmounted/
  #     m = unmount.match(/Volume .* on (.*) unmounted/)
  #     system "hdiutil detach /dev/#{m[1]}"
  #   else
  #     print unmount
  #   end
  # end

  # private

  # def validate(src)
  #   if File.exist?("#{src}#{@backupSuffix}")
  #     abort "Stopping for safety. A backup already exists for: '#{src}' at: '#{src}#{@backupSuffix}'"
  #   end
  # end

#end


# if opts.ram?
#   print "Building RAM disk"
#   rd = RamDev.new opts[:ram]
#   rd.build(rc["ramdisk"]["name"],rc["ramdisk"]["mountpoint"],rc["ramdisk"]["paths"])
# elsif opts.fix?
#   print "fixing links"
#   rd = RamDev.new opts[:ram]
#   rd.unbuild(rc["ramdisk"]["name"],rc["ramdisk"]["mountpoint"],rc["ramdisk"]["paths"])
# end


# def getrc
#   si = SystemInfo.new
#   si.loadOrCreateRC
# end

# def build_ramdisk
#   rc = getrc
#   rd = RamDev.new #options?
#   rd.build(rc["ramdisk"]["name"],rc["ramdisk"]["mountpoint"],rc["ramdisk"]["paths"])
# end

# def teardown_ramdisk
#   rc = getrc
#   rd = RamDev.new #options?
#   rd.unbuild(rc["ramdisk"]["name"],rc["ramdisk"]["mountpoint"],rc["ramdisk"]["paths"])
# end

# -------------------

#require 'main'

# Main do
#   mode 'up' do
#     def run
#       puts 'building RAMDISK...'
#       build_ramdisk
#     end
#   end

#   mode 'down' do
#     def run
#       puts 'tearing down RAMDISK...'
#       teardown_ramdisk
#     end
#   end

#   mode 'aws' do
#     def run
#       puts 'do something with AWS...'
#     end
#   end

#   def run()
#     puts 'doing something different'
#   end
# end
# class SystemInfo

#   def memory
#     if @memory.nil?
#       r = `/usr/sbin/system_profiler SPHardwareDataType`.split("\n").collect { |s| s == "" ? nil : s.strip }.compact
#       r = r.collect { |s| s.split(":").collect { |ss| ss.strip }}
#       memstring = ""
#       r.each do |i|
#         memstring = i[1] if i[0] == "Memory"
#       end
#       @memory = memstring.match(/([0-9]+) GB/)[1].to_i * 1073741824
#     end
#     @memory
#   end

#   def home
#     @home ||= Dir.home(user)
#   end

#   def user
#     @user ||= Etc.getlogin
#   end

#   def loadOrCreateRC
#     rcpath = "#{home}/.devrc"
#     unless File.exist? rcpath
#       File.open(rcpath, "w") do |f|
#         f.puts '# This is a yaml format file with settings for "dev".'
#         f.puts '# See dev -h for more information.'
#       end
#     end
#     puts "Loading devrc: #{rcpath}"
#     YAML.load_file rcpath
#   end

# end
