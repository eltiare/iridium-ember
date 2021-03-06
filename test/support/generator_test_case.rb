require 'pathname'

class GeneratorTestCase < MiniTest::Unit::TestCase
  def setup
    super
    FileUtils.rm_rf destination_root
    FileUtils.mkdir_p destination_root
    Iridium.application = TestApp.instance
  end

  def teardown
    super
    FileUtils.rm_rf destination_root
  end

  def read(*path)
    File.read destination_root.join(*path)
  end

  def invoke(*args)
    options = args.extract_options!
    task_name = args.shift
    runner = command.new args, options
    runner.destination_root = destination_root
    capture_io { runner.invoke task_name }
  end

  def assert_file(*path)
    full_path = destination_root.join *path

    assert File.exists?(full_path), 
      "#{full_path} should be a file. Current Files: #{Dir[destination_root.join("**", "*").inspect]}"
  end

  def assert_defined(object_name, file)
    content = read file
    namespace = Iridium.application.class.to_s

    assert_includes content, "#{namespace}.#{object_name} = "
  end

  def destination_root
    @destination_root ||= Pathname.new File.expand_path("../../sandbox", __FILE__)
  end
end
