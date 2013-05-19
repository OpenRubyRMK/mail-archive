require "sinatra"

class MlArchive < Sinatra::Base

  set :root, File.expand_path(File.join(File.dirname(__FILE__), ".."))

  configure :development do
    enable :static
    enable :logging
  end

  get "/" do
    erb :startpage
  end

  get "/:ml/search" do
    "This is the search."
  end

end
