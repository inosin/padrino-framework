Dir["{lib/tasks/**,tasks/**,test,spec}/*.rake"].each do |file|
  begin
    load(file)
  rescue LoadError => e
    warn "#{file}: #{e.message}"
  end
end

# Loads the Padrino applications mounted within the project.
# Setting up the required environment for Padrino.
task :environment do
  require File.expand_path('config/boot.rb', Rake.application.original_dir)

  Padrino.mounted_apps.each do |app|
    app.app_obj.setup_application!
  end
end

desc "Generate a secret key"
task :secret do
  shell.say SecureRandom.hex(32)
end

def list_app_routes(app, args)
  app_routes = app.named_routes
  app_routes.reject! { |r| r.identifier.to_s !~ /#{args.query}/ } if args.query.present?
  app_routes.map! { |r| [r.verb, r.name, r.path] }
  return if app_routes.empty?
  shell.say "\nApplication: #{app.app_class}", :yellow
  app_routes.unshift(["REQUEST", "URL", "PATH"])
  max_col_1 = app_routes.max { |a, b| a[0].size <=> b[0].size }[0].size
  max_col_2 = app_routes.max { |a, b| a[1].size <=> b[1].size }[1].size
  app_routes.each_with_index do |row, i|
    message = [row[1].ljust(max_col_2+2), row[0].center(max_col_1+2), row[2]]
    shell.say("    " + message.join(" "), i==0 ? :bold : nil)
  end
end

desc "Displays a listing of the named routes within a project, optionally only those matched by [query]"
task :routes, [:query] => :environment do |t, args|
  Padrino.mounted_apps.each do |app|
    list_app_routes(app, args)
  end
end

desc "Displays a listing of the named routes a given app [app]"
namespace :routes do
  task :app, [:app] => :environment do |t, args|
    app = Padrino.mounted_apps.find { |app| app.app_class == args.app }
    list_app_routes(app, args) if app
  end
end
