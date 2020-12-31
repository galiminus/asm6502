Gem::Specification.new do |s|
  s.name = "r6502"
  s.version = "0.1.1"
  s.author = "Gallimimus"
  s.date = %q{2020-12-31}
  s.summary = %q{Write 6502 assembly from Ruby code}
  s.files = `git ls-files -z`.split("\x0")
  s.require_paths = ["lib"]
end
