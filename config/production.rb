Iridium::Ember::Engine.configure do
  config.dependencies.swap "ember-debug", :ember

  config.handlebars.compiler = Iridium::Ember::HandlebarsFileCompiler

  js do |pipeline|
    pipeline.strip %r{^\s*(Ember|Em)\.(assert|deprecate|warn)\((.*)\).*$}
  end

  js do |pipeline|
    pipeline.replace /([Ember|Em]\.Handlebars\.compile)\(['"](.+)['"]\)/ do |foo, _, template|
      Iridium::Ember::InlineHandlebarsCompiler.call template
    end
  end
end
