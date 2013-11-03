# Based upon https://gist.github.com/jeffreyiacono/1772989
namespace :assets do
  desc 'compile assets'
  task :compile => [:compile_js, :compile_css] do
  end

  desc 'setup sprockets'
  task :setup_sprockets do
    # TODO Get an already setup sprockets from padrino-sprockets
    @sprockets = Sprockets::Environment.new Quantum::App.root
    @sprockets.append_path 'assets/javascripts'
    @sprockets.append_path 'assets/stylesheets'
    @sprockets.css_compressor = YUI::CssCompressor.new
    @sprockets.register_postprocessor "application/javascript", Sprockets::JSMinifier
  end

  desc 'compile js assets'
  task :compile_js => [:environment, :setup_sprockets] do
    %w{application circuits}.each do |js|
      asset     = @sprockets["#{js}.js"]
      outpath   = File.join(Padrino.root, 'public', 'compiled')
      outfile   = Pathname.new(outpath).join("#{js}.js")

      FileUtils.mkdir_p outfile.dirname

      asset.write_to(outfile)
      asset.write_to("#{outfile}.gz")
    end
    puts "successfully compiled js assets"
  end

  desc 'compile css assets'
  task :compile_css => :environment do
    %w{application circuits}.each do |css|
      asset     = @sprockets["#{css}.css"]
      outpath   = File.join(Padrino.root, 'public', 'compiled')
      outfile   = Pathname.new(outpath).join("#{css}.css")

      FileUtils.mkdir_p outfile.dirname

      asset.write_to(outfile)
      asset.write_to("#{outfile}.gz")
    end
    puts "successfully compiled css assets"
  end
end
