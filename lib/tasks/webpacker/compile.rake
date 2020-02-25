$stdout.sync = true

def yarn_install_available?
  rails_major = Rails::VERSION::MAJOR
  rails_minor = Rails::VERSION::MINOR

  rails_major > 5 || (rails_major == 5 && rails_minor >= 1)
end

def enhance_assets_precompile
  # yarn:install was added in Rails 5.1
  deps = yarn_install_available? ? [] : ["webpacker:yarn_install"]
  Rake::Task["assets:precompile"].enhance(deps) do
    Rake::Task["webpacker:compile"].invoke
  end
end

namespace :webpacker do
  desc "Compile JavaScript packs using webpack for production with digests"
  task compile: ["webpacker:verify_install", :environment] do
    Webpacker.with_node_env(ENV.fetch("NODE_ENV", "production")) do
      Webpacker.ensure_log_goes_to_stdout do
        if Webpacker.compile
          # Successful compilation!
        else
          # Failed compilation
          exit!
        end
      end
    end
  end
end

# Compile packs after we've compiled all other assets during precompilation
skip_webpacker_precompile = %w(no false n f).include?(ENV["WEBPACKER_PRECOMPILE"])

# We remove this code to make it work  in opsworks
#
#
# In opsworks we run into issues because opsworks is so old and crusty
# we can not easily install a current version of node.
#
# We also can not specify the WEBPACKER_PRECOMPILE env var early enough in the setup and deploy process
# That means despite our best effort this piece of code was always running.
#
# It would then error out because we don't have a version of node'
# Which was causing the whole setup to fail
#
# And because forking a branch is literally easier than than making changes to opsworks this is the solution we have gone with.
#
# From here we can specify this specific commit and repo in the gem file.
# And everyting works again.
# unless skip_webpacker_precompile
#   if Rake::Task.task_defined?("assets:precompile")
#     enhance_assets_precompile
#   else
#     Rake::Task.define_task("assets:precompile" => ["webpacker:yarn_install", "webpacker:compile"])
#   end
# end
