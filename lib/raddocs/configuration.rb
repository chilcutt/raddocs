module Raddocs
  class Configuration
    def self.add_setting(name, opts = {})
      define_method("#{name}=") { |value| settings[name] = value }
      define_method("#{name}") do
        if settings.has_key?(name)
          settings[name]
        elsif opts[:default].respond_to?(:call)
          opts[:default].call(self)
        else
          opts[:default]
        end
      end
    end

    add_setting :docs_dir, :default => "docs"
    add_setting :docs_mime_type, :default => /text\/docs\+plain/
    add_setting :api_name, :default => "Api Documentation"
    add_setting :include_bootstrap, :default => true
    add_setting :external_css, :default => []
    add_setting :use_http_basic_auth, :default => false
    add_setting :http_basic_auth_username, :default => ''
    add_setting :http_basic_auth_password, :default => ''
    add_setting :aws_storage, :default => false
    add_setting :aws_access_key_id, :default => ''
    add_setting :aws_secret_access_key, :default => ''
    add_setting :aws_s3_bucket, :default => ''
    add_setting :aws_s3_file_prefix, :default => 'docs'

    def settings
      @settings ||= {}
    end
  end
end
