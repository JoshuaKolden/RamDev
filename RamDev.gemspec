Gem::Specification.new do |s|
  s.name          = 'RamDev'
  s.version       = '0.1.0'
  s.date          = '2013-12-26'
  s.summary       = "Work flow performance boost with a ramdrive."
  s.description   =
    'A management tool for creating a ramdrive and syncing folders back to the hard drive automatically.'
  s.authors       = ["Joshua Kolden"]
  s.email         = ["joshua@crackcreative.com"]
  s.executables   = ['ramdev', 'ramdev_sync']
  s.files         = [ "lib/ramdev.rb", "lib/ramdev_sync.rb", "lib/ramdisk.rb"]
  s.homepage      = "https://github.com/JoshuaKolden/RamDev"
  s.license       = 'MIT'
end
