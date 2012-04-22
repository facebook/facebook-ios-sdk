require 'Raven.rb'
require 'RavenArtifact.rb'

include Rake::DSL

raven = Raven.new()

task :clean do
	raven.clean
end

task :resolve do
	raven.resolve
end

task :build, :configuration do |task, arg|
	raven.build(arg.configuration)
end

task :install do
	raven.install
end

task :release do
	raven.release
end

task :deploy do
	raven.deploy
end