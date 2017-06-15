
shared_context 'in a new module' do |name|
  before(:all) do
    system("pdk new module #{name} --skip-interview") || raise
    Dir.chdir(name)
  end

  after(:all) do
    Dir.chdir('..')
    FileUtils.rm_rf(name)
  end
end
