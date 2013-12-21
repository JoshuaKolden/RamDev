#!/usr/bin/env rvm ruby-2.0.0-p353@support do ruby

require 'listen'
require 'yaml'

class RamDevSync
  attr_reader :paths, :listener

  def initialize(rcpath)
    @paths = []
    rc = YAML.load rcpath
    @mountpoint = rc["ramdisk"]["mountpoint"]
    for pathset in rc["ramdisk"]["paths"] do
      @paths.push([pathset["source"], "#{@mountpoint}/#{pathset['destination']}"])
    end
  end

  def watchpaths
    return @paths.collect do |i|
        # path being watched
      ["#{i[1]}/#{i[0][/([^\/]*)\/*$/,1]}".gsub(/\/{2,}/,"/"),
          # origin path to sync to
      "#{i[0][/(.*[^\/]+)\/*$/,1]}_backup_DEV".gsub(/\/{2,}/,"/")]
    end
  end

  def listen
    @listener = Listen.to watchpaths.collect { |i| i[0]} do |modified, added, removed|
      rsync [modified,added,removed]
    end
    @listener.start # not blocking
  end

  def rsync change_list
    list = change_list.flatten
    for wp in watchpaths
      list.each do |i|
        system("rsync -a --delete --stats \"#{wp[0]}/\" \"#{wp[1]}/\"") if i.include? wp[0]
        break
      end
    end

  end

end
