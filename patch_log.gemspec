require File.expand_path('../lib/patch_log/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "patch_log"
  s.version = PatchLog::VERSION
  s.requirements = "GNU diff or equivalent"
  s.author = 'Mat Brown'
  s.email = 'mat.a.brown@gmail.com'
  s.homepage = 'https://github.com/outoftime/patch_log'
  s.license = 'MIT'
  s.summary = "Store version history for ActiveRecord text fields as patches"
  s.description = <<DESC
PatchLog extends ActiveRecord to efficiently store version history for text
fields. Changes are stored in a separate table containing only the output of
diff, which can be used to reconstruct previous versions without having to store
every version in its entirety.
DESC
  s.has_rdoc = false
  s.files = Dir.glob(File.expand_path('../lib/**/*.rb', __FILE__)) +
            Dir.glob(File.expand_path('../spec/**/*.rb', __FILE__)) +
            ['README.md', 'HISTORY.md']
  s.test_files = Dir.glob(File.expand_path('../spec/examples/**/*.rb', __FILE__))
  s.add_dependency 'activerecord'
  s.add_dependency 'activesupport', '~>3.0'
  s.add_development_dependency 'rspec'
end
