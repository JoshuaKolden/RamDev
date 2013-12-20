# begin
#   gem "rsync"
# rescue LoadError
#   system("gem install rsync")
#   Gem.clear_paths
# end

require 'pathname'
require 'fileutils'
# require 'rsync'

wd = "#{File.dirname(__FILE__)}"

require "#{wd}/systeminfo"

class RamDev
  attr_reader :ramDiskSize, :sectors

  def initialize(userSize)
    @backupSuffix = "_backup_DEV"
    if userSize.nil?
      @systemInfo = SystemInfo.new
      @ramDiskSize = (@systemInfo.memory / 2)
    else
      @ramDiskSize = (userSize / 2)
    end
  end

  def build(diskname = "x", mountpoint = "/x", paths = [])
    unbuild(diskname, mountpoint, paths)
    build = false

    if @ramDiskSize > 0
      @sectors = @ramDiskSize / 512

      ramdisk = `hdid -nomount ram://#{sectors}`.strip
      system "newfs_hfs -v '#{diskname}' #{ramdisk}"
      build = system "sudo mount -o noatime -t hfs #{ramdisk} #{mountpoint}"
      print "RAM disk mounted at #{mountpoint}\n"

      if build
        paths.each do |p|
          src   = p["source"].gsub(/\/+$/,"")
          if File.exist?("#{src}#{@backupSuffix}")
            puts "Stopping for safety. A backup already exists for: '#{src}' at: '#{src}#{@backupSuffix}'"
            return
          end
        end
        paths.each do |p|
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
          print "Copying #{src}...\n"
          FileUtils.mkdir_p(des) if !File.exist?(des)
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
            #529 100%    0.38kB/s    0:00:01 (xfer#91800, to-check=178548/288630)

          end
          print "\n"

          FileUtils.move(src, src+@backupSuffix)

          puts "Linking: #{name}"

          File.symlink("#{des}/#{name}", src)
        end
      end
    end
  end

  def unbuild(diskname = "x", mountpoint = "/x", paths = [])
    paths.each do |p|
      src   = p["source"].gsub(/\/+$/,"")
      next if src.nil? || src.length < 1
      des   = p["destination"].gsub(/\/+$/,"").gsub(/^\/+/,"")
      name  = src.match(/([^\/\\]+)$/)[1]

      if File.exists? src+@backupSuffix
        FileUtils.safe_unlink src if File.symlink?(src)
        if File.exist?(src)
          print "Conflict between #{src} and #{src+@backupSuffix}"
          next
        end
        FileUtils.move(src+@backupSuffix, src)
      end
    end

    unmount = `diskutil unmount force #{mountpoint}`
    if unmount =~ /Volume .* on (.*) unmounted/
      m = unmount.match(/Volume .* on (.*) unmounted/)
      system "hdiutil detach /dev/#{m[1]}"
    else
      print unmount
    end
  end

end
