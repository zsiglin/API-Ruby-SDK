require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.name = 'test:integration'
  t.warning = true
  t.test_files = FileList['test/integration/**/test_*.rb']
end

desc "Run nit tests"
task :default => 'test:integration'
