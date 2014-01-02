# RamDev

[![Gem Version](https://badge.fury.io/rb/ramdev.png)](http://badge.fury.io/rb/ramdev)

---

RamDev is a ruby gem for boosting your work flow. It creates a ramdrive and copies your project files to it.  All files are automatically synced back to the hard drive in the background as you work using `rsync`.

Working in ram is extremely high performance, often 'real time' for software development and testing. Be sure to use high performance settings with other tools such as make's `-j` option to maximize the benefit.

## Installation

    $ gem install ramdev

## Platforms

Currently only OS X is supported.

## Instructions

To start the ram disk and copy files.

    $ ramdev up

By default ramdev will use half the system's ram for the ramdisk. Specify `-m` option to set different amount of memory to use:

    $ ramdev up -m 300MB # use 300 Megabytes

or

    $ ramdev up -m 2GB # use 2 Gegabytes

To shutdown the ramdisk, and restore paths.

    $ ramdev down

To fix paths and links after an unexpected shutdown.

    $ ramdev fix

## Configuration

By default ramdev looks for a .ramdevrc file in your home directory. You can specify a different file on the command line with the `-r` option:

    $ ramdev up -r path/to/ramdevrc

### ramdevrc format

```yaml
# This a yaml format file with settings for "ramdev".
# See https://github.com/JoshuaKolden/RamDev for more information.

ramdisk:
  name: "NameOfDisk"
  mountpoint: "/path/to/mount/point"
  paths: # list of paths to copy to ramdisk, and location on ramdisk 
    -
      source: "/path/to/source/folder"
      destination: "" # no leading "/" moutpoint will be prepended
    -
      source: "/another/path"
      destination: "different/location/under/mountpoint"
```

The name of the lowest folder in the source path is appended to the 'destination' path which in tern is appended to the mountpoint.

###Example

```yaml
ramdisk:
  name: "ramdrive"
  mountpoint: "/mnt"
  paths: # list of paths to copy to ramdisk, and location on ramdisk 
    -
      source: "/foo/bar/bat"
      destination: "baz"
```

    $ ramdev up
    
Will create the following path on the ramdisk:

`/mnt/baz/bat`

This will have a full copy of `/foo/bar/bat`, so keep the size of your project (including temporary files) in mind.

`/foo/bar/bat` will be renamed to `/foo/bar/bat_ramdev`

And `/foo/bar/bat` will be a symbolically linked to `/mnt/baz/bat`

As you make changes to the ramdisk copy `/mnt/baz/bat` they will be automatically synced back to `/foo/bar/bat_ramdev` in the background.

Your project folders will effectively appear to be in the same place, but are in fact linked to ram. 

    $ ramdev down

When you run `ramdev down` the `/foo/bar/bat` link is removed and `/foo/bar/bat_ramdev` is renamed back to `/foo/bar/bat`; the ramdrive is then unmounted and the memory freed.

## TODO

- Code cleanup.
- Support for creating new folders in the ramdisk root path.

**Platforms**

 - Support for Unix.

Windows will have to be done by someone else, but if you do it I'll merge it.

**Features**

    $ ramdev sync
> To force sync

    $ ramdev check
> To check if ramdev_sync is running correctly:


## License

MIT License. Copyright 2013-2014 Joshua Kolden.
