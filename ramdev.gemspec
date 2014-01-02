Gem::Specification.new do |s|
  s.name          = 'ramdev'
  s.version       = '0.2.0'
  s.date          = %q{2014-01-02}
  s.summary       = "Work in ram for ultra high performance."
  s.description   =
    'A management tool for creating a ramdrive and syncing folders back to the hard drive automatically while you work.'
  s.authors       = ["Joshua Kolden"]
  s.email         = ["joshua@crackcreative.com"]
  s.executables   = ['ramdev', 'ramdev_sync']
  s.files         = [ "lib/ramdev.rb", "lib/ramdev_sync.rb", "lib/ramdisk.rb"]
  s.add_runtime_dependency "listen", ["~> 2.0"]
  s.add_runtime_dependency "main", [">= 0.0"]
  s.add_runtime_dependency "plist", ['>= 3.1.0']
  s.add_runtime_dependency "rainbow", ["~> 1.99.1"]
  s.homepage      = "https://github.com/JoshuaKolden/RamDev"
  s.license       = 'MIT'
end
