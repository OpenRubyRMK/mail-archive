require "sinatra"
require_relative "mlmmj-rbarchive/archiver"

class MlArchive < Sinatra::Base

  # Check interval for new mails in the archive
  CHECK_INTERVAL = 60 * 120 # 2h

  set :root, File.expand_path(File.join(File.dirname(__FILE__), ".."))
  set :ml_archive_dir, File.join(settings.public_folder, "lists")

  configure :development do
    enable :static
    enable :logging

    set :ml_root, "#{settings.root}/test-mls"
  end

  configure :production do
    set :ml_root, "/var/spool/mlmmj"
  end

  ########################################
  # Archive

  set :ml_archiver, Archiver.new(settings.ml_archive_dir,
                                 header: "<p>OpenRubyRMK Mailing list archives</p>",
                                 searchtarget: "../../search",
                                 stylefile: "../../../archive.css")

  configure :development do
    Thread.abort_on_exception = true
    settings.ml_archiver.debug_mode = true
  end

  Pathname.new(settings.ml_root).each_child do |mldir|
    settings.ml_archiver << mldir
  end

  Thread.new do
    loop do
      settings.ml_archiver.archive!
      sleep CHECK_INTERVAL
    end
  end

  get "/" do
    erb :startpage
  end

  get "/lists/:ml" do
    @mlname = params[:ml]
    erb :ml
  end

  get "/lists/:ml/search" do
    "This is the search for the #{params[:ml]} mailinglist."
  end

end
