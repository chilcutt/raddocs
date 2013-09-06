module Raddocs
  class App < Sinatra::Base
    set :haml, :format => :html5
    set :root, File.join(File.dirname(__FILE__), "..")

    use Rack::Auth::Basic, "Restricted Area" do |username, password|
      if Raddocs.configuration.use_http_basic_auth
        username == Raddocs.configuration.http_basic_auth_username and password == Raddocs.configuration.http_basic_auth_password
      else
        true
      end
    end

    get "/" do
      index = JSON.parse(index_json)
      haml :index, :locals => { :index => index }
    end

    get "/custom-css/*" do
      file = "#{docs_dir}/styles/#{params[:splat][0]}"

      if !File.exists?(file)
        raise Sinatra::NotFound
      end

      content_type :css
      File.read(file)
    end

    get "/*" do
      example = JSON.parse(file_json)
      example["parameters"] = Parameters.new(example["parameters"]).parse
      haml :example, :locals => { :example => example }
    end

    not_found do
      "Example does not exist"
    end

    helpers do
      def link_to(name, link)
        %{<a href="#{request.env["SCRIPT_NAME"]}#{link}">#{name}</a>}
      end

      def url_location
        request.env["SCRIPT_NAME"]
      end

      def api_name
        Raddocs.configuration.api_name
      end

      def css_files
        files = ["#{url_location}/codemirror.css", "#{url_location}/application.css"]

        if Raddocs.configuration.include_bootstrap
          files << "#{url_location}/bootstrap.min.css"
        end

        Dir.glob(File.join(docs_dir, "styles", "*.css")).each do |css_file|
          basename = Pathname.new(css_file).basename
          files << "#{url_location}/custom-css/#{basename}"
        end

        files.concat Array(Raddocs.configuration.external_css)

        files
      end
    end

    def docs_dir
      Raddocs.configuration.docs_dir
    end

    def s3_file_prefix
      Raddocs.configuration.aws_s3_file_prefix
    end

    def index_json
      if Raddocs.configuration.aws_storage
        aws_directory.files.get("#{s3_file_prefix}/index.json").body
      else
        File.read("#{docs_dir}/index.json")
      end
    end

    def file_json
      if Raddocs.configuration.aws_storage
        file = "#{s3_file_prefix}/#{params[:splat][0]}.json"
        aws_file = aws_directory.files.get(file)
        if !aws_file
          raise Sinatra::NotFound
        end
        aws_file.body
      else
        file = "#{docs_dir}/#{params[:splat][0]}.json"
        if !File.exists?(file)
          raise Sinatra::NotFound
        end
        File.read(file)
      end
    end

    def aws_directory
      @aws_storage ||= Fog::Storage.new(:aws_access_key_id => Raddocs.configuration.aws_access_key_id,
                                        :aws_secret_access_key => Raddocs.configuration.aws_secret_access_key,
                                        :provider => 'AWS')
      @aws_directory ||= @aws_storage.directories.get(Raddocs.configuration.aws_s3_bucket)
    end
  end
end
