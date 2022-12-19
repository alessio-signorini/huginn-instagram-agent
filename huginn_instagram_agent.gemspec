# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "huginn_instagram_agent"
  spec.version       = '0.4.4'
  spec.license       = 'MIT'
  spec.authors       = ["Alessio Signorini", "Víctor A. Rodríguez"]
  spec.email         = ["alessio@signorini.us", "victor@bit-man.guru"]

  spec.summary       = "Huginn Agent that monitors public Instagram accounts"

  spec.homepage      = "https://github.com/alessio-signorini/huginn-instagram-agent"


  spec.files         = Dir['LICENSE.txt', 'lib/**/*']
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = Dir['spec/**/*.rb'].reject { |f| f[%r{^spec/huginn}] }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", ">= 12.3"

  spec.add_runtime_dependency "huginn_agent", ">= 0.6"
  spec.add_runtime_dependency "httparty", ">= 0.7"

end
