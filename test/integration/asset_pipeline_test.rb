require 'test_helper'

class AssetPipelineTest < MiniTest::Unit::TestCase
  include ActiveSupport::Testing::Isolation

  def config
    app.config
  end

  def setup
    super

    create_file "vendor/javascripts/handlebars.js", File.read(::Handlebars::Source.bundled_path)
    create_file "vendor/javascripts/ember-template-compiler.js", File.read(::Ember::Source.bundled_path_for('ember-template-compiler.js'))
  end

  def test_ember_precompiler_is_not_compiled
    create_file "app/javascripts/foo.js", "one js file is needed"

    create_file "vendor/javascripts/ember-template-compiler.js", "PRECOMPILER"

    compile ; assert_file "site/application.js"

    content = read "site/application.js"
    refute_includes content, "PRECOMPILER"
  end

  def test_ember_production_build_is_used
    create_file "app/javascripts/foo.js", "one js file is needed"

    create_file "vendor/javascripts/ember.min.js", "PRODUCTION BUILD"
    create_file "vendor/javascripts/ember.js", "DEV BUILD"

    compile :production ; assert_file "site/application.js"

    content = read "site/application.js"
    assert_includes content, "PRODUCTION BUILD"
    refute_includes content, "DEV BUILD"
  end

  def test_ember_development_build_is_used
    create_file "app/javascripts/foo.js", "one js file is needed"

    create_file "vendor/javascripts/ember.min.js", "PRODUCTION BUILD"
    create_file "vendor/javascripts/ember.js", "DEV BUILD"

    compile :development ; assert_file "site/application.js"

    content = read "site/application.js"
    refute_includes content, "PRODUCTION BUILD"
    assert_includes content, "DEV BUILD"
  end

  def test_templates_are_loaded_on_ember
    create_file "app/templates/home.hbs", "Hello {{name}}!"

    compile ; assert_file "site/application.js"

    content = read "site/application.js"
    assert_match /Ember\.TEMPLATES\['.+'\]=/, content
  end

  def test_templates_are_compiled_at_runtime_in_development
    create_file "app/templates/home.hbs", "Hello {{name}}"

    compile :development ; assert_file "site/application.js"

    content = read "site/application.js"

    assert_match /Ember\.TEMPLATES\['.+'\]=Ember\.Handlebars\.compile\(.+\);/m, content
  end

  def test_handlbars_templates_are_precompiled_in_production
    create_file "app/templates/home.hbs", "Hello {{name}}"

    compile :production ; assert_file "site/application.js"

    content = read "site/application.js"

    assert_match /Ember\.TEMPLATES\['.+'\]=Ember\.Handlebars\.template\(.+\);/m, content
  end

  def test_inline_handlebars_templates_are_precompiled_in_production
    create_file "app/javascripts/view.js", <<-js
      App.MyView = Ember.View.extend({
        template: Ember.Handlebars.compile('Hello {{name}}')
      })
    js

    compile :production ; assert_file "site/application.js"

    content = read "site/application.js"

    assert_match /template:\sEmber\.Handlebars\.template\(.+\)[^;]/, content

    compiled_template = Iridium::Ember::HandlebarsPrecompiler.compile 'Hello {{name}}'

    assert_includes content, compiled_template, 
      "Template did not compile correctly!"
  end

  def test_inline_handles_with_em_namespace_are_compiled
    create_file "app/javascripts/view.js", <<-js
      App.MyView = Ember.View.extend({
        template: Em.Handlebars.compile('Hello {{name}}')
      })
    js

    compile :production ; assert_file "site/application.js"

    content = read "site/application.js"

    assert_match /template:\sEmber\.Handlebars\.template\(.+\)[^;]/, content

    compiled_template = Iridium::Ember::HandlebarsPrecompiler.compile 'Hello {{name}}'

    assert_includes content, compiled_template, 
      "Template did not compile correctly!"
  end

  def test_ember_asserts_are_stripped_in_production
    create_file "app/javascripts/ember.coffee", <<-coffee
      Ember.assert 'ember assertion'
    coffee

    compile :production ; assert_file "site/application.js"

    content = read "site/application.js"
    refute_includes content, 'ember assertion'
  end

  def test_ember_warning_are_stripped_in_production
    create_file "app/javascripts/ember.coffee", <<-coffee
      Ember.warn 'ember warning'
    coffee

    compile :production ; assert_file "site/application.js"

    content = read "site/application.js"
    refute_includes content, 'ember warning'
  end

  def test_ember_deprecations_are_stripped_in_production
    create_file "app/javascripts/ember.coffee", <<-coffee
      Ember.deprecate 'ember deprecation'
    coffee

    compile :production ; assert_file "site/application.js"

    content = read "site/application.js"
    refute_includes content, 'ember deprecartion'
  end

  def test_ember_debug_calls_are_stripped_in_production
    create_file "app/javascripts/ember.coffee", <<-coffee
      Ember.debug 'debugger!'
    coffee

    compile :production ; assert_file "site/application.js"

    content = read "site/application.js"
    refute_includes content, 'debugger!'
  end

  private
  def compile(env = "test")
    ENV['IRIDIUM_ENV'] = env.to_s
    instance = TestApp.new
    instance.boot!
    instance.compile
  ensure
    ENV['IRIDIUM_ENV'] = "test"
  end
end
