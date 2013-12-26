#!/usr/bin/env ruby

require 'listen'
require 'yaml'
# require 'pstore'
# store = PStore.new("ramdev_sync.pstore")

class RamDevSync
  attr_reader :paths, :listener

  def initialize(rcpath, sufix = "_ramdev")
    @backupSuffix = sufix
    load_runcom(rcpath)

    # store.transaction do |s|
    # end
  end

    #FIX: This is *almost* duplicated from ramdev.rb:
  def load_runcom(rcpath)

    return if @loaded == true

    rc = YAML.load(rcpath)
    if rc.nil?
      @mountpoint = "/ramdev"
      @diskname   = "ramdev"
      @paths      = []

      for pathset in rc["ramdisk"]["paths"] do
        @paths.push([Dir.pwd, "#{@mountpoint}"])
      end
    else
      @mountpoint = rc["ramdisk"]["mountpoint"]
      @diskname  = rc["ramdisk"]["name"]
      @paths     = []
        # TODO: Get size of paths and create default ramdisk size (x2)
      for pathset in rc["ramdisk"]["paths"] do
        @paths.push([pathset["source"], "#{@mountpoint}/#{pathset['destination']}"])
      end

      @loaded    = true

    end
    puts "ramdev_sync configured for: #{@mountpoint}"
  end

  def running?
    return true if !@listener.nil? && @listener.listen?
    return false
  end

  def watchpaths
    return @paths.collect do |i|
        # path being watched
      ["#{i[1]}/#{i[0][/([^\/]*)\/*$/,1]}".gsub(/\/{2,}/,"/"),
          # origin path to sync to
      "#{i[0][/(.*[^\/]+)\/*$/,1]}#{@backupSuffix}".gsub(/\/{2,}/,"/")]
    end
  end

  def listen
    @listener = Listen.to watchpaths.collect { |i| i[0]} do |modified, added, removed|
      rsync [modified,added,removed]
    end
    @listener.start # not blocking
  end

  def rsync(change_list)
    list = change_list.flatten
    for wp in watchpaths
      list.each do |i|
        if i.include? wp[0]
          system("date >> /tmp/ramdev_sync_#{Process.pid}.log")
          system("rsync -a --delete -v --stats \"#{wp[0]}/\" \"#{wp[1]}/\" >> /tmp/ramdev_sync_#{Process.pid}.log"  )
          break
        end
      end
    end

  end

  def remove_log
    File.delete("/tmp/ramdev_sync_#{Process.pid}.log")
  end

end
