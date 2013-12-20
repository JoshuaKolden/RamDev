# RamDev

RamDev is a ruby gem that creates a ramdisk, copies the folders you specify to the ramdrive then links them back to the original location.  It renames your original source folders and uses rsync to asynchronously copy any changes you make in the ramdisk back to the originals.

This means that all compiling, testing, and other processes that you run on your code happen very quickly in ram. File synchronization to disk happens in the background so it doesn't impact your work flow.

When you're done working, a single command insures your files are synced and unmounts the ramdisk.

## Installation

__Not ready yet__
    $ gem install ramdev

## Platforms

Currently only OS X is supported.

## Instructions

To start the ram disk and copy files.

    $ ramdev up

To sync files and shutdown the ram disk.

    $ ramdev down

## Configuration

Ramdev looks for a .ramdevrc file in your home directory.

```yaml
# This a yaml format file with settings for "ramdev".
# See ramdev for more information.

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

The name of the lowest folder in the source path is appended to the 'destination' path which in tern is appended to the mountpoint. For example

* Mount point: `/mnt`
* Source: `/usr/joshua/myproject`
* Destination: `current`

Will create the the following path on the ramdisk:

`/mnt/current/myproject`

This will have a full copy of `/usr/joshua/myproject` And 

`/usr/joshua/myproject` will be renamed to `/usr/joshua/myproject_ramdev`

`/usr/joshua/myproject` will be a symbolic link to `/mnt/current/myproject`

As you make changes to `/mnt/current/myproject` they will be automatically synced back to `/usr/joshua/myproject_ramdev`

When you run `ramdev.down` `rsync` is run again just to be sure everything is
in sync, then the `/usr/joshua/myproject` link is removed and `/usr/joshua/myproject_ramdev` is renamed back to `/usr/joshua/myproject`.

## Problems

If you loose power or run into problems, you can run

    $ ramdev fix

Your original folders will be moved back into place.

To force sync:

    $ ramdev sync

To check if the ramdev file monitoring process is running correctly:

    $ ramdev check

---

By Joshua Kolden.  License info coming soon.
