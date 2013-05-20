# -*- coding: utf-8 -*-
require "sinatra"
require "sinatra/content_for"
require_relative "mlmmj-rbarchive/archiver"

class MlArchive < Sinatra::Base
  helpers Sinatra::ContentFor

  # Check interval for new mails in the mail cache
  CHECK_INTERVAL = 60 * 30 # 0,5h

  # Basic settings
  set :root, File.expand_path(File.join(File.dirname(__FILE__), ".."))
  set :ml_archive_dir, File.join(settings.public_folder, "lists")
  set :ml_cache_dir, File.join(settings.root, "mail-cache")

  # Configure development mode
  configure :development do
    enable :static
    enable :logging

    set :ml_root, "#{settings.root}/test-mls"
  end

  # Configure production mode
  configure :production do
    set :ml_root, "/var/spool/mlmmj"
  end

  ########################################
  # Archive

  set :ml_archiver, Archiver.new(settings.ml_cache_dir,
                                 settings.ml_archive_dir,
                                 header: "<p>OpenRubyRMK Mailing list archives</p>",
                                 searchtarget: "../../search",
                                 stylefile: "../../../archive.css",
                                 archiveadmin: "quintus [ät] quintilianus [döt] eu")

  configure :development do
    Thread.abort_on_exception = true
    settings.ml_archiver.debug_mode = true
  end

  Pathname.new(settings.ml_root).each_child do |mldir|
    settings.ml_archiver << mldir
  end

  # Preprocess all existing mails, then watch for new ones
  settings.ml_archiver.preprocess_mlmmj_mails!
  settings.ml_archiver.watch_mlmmj_mails!

  # Every now and then, take all the new mails and convert
  # them to HTML.
  Thread.new do
    loop do
      settings.ml_archiver.archive!
      sleep CHECK_INTERVAL
    end
  end

  ########################################
  # Routes

  get "/" do
    erb :startpage
  end

  get "/lists/:ml" do
    @mlname = params[:ml]

    @index_files = []
    Pathname.new(settings.ml_archive_dir).join(@mlname).each_child do |yeardir|
      yeardir.each_child do |monthdir|
        @index_files << ["#{yeardir.basename}-#{monthdir.basename}", "/lists/#@mlname/#{yeardir.basename}/#{monthdir.basename}/index.html"]
      end
    end
    @index_files.sort_by!{|ary| ary.first}

    erb :ml
  end

  get "/lists/:ml/" do
    redirect "/lists/#{params[:ml]}"
  end

  get "/lists/:ml/search" do
    @mlname = params[:ml]
    erb :search
  end

  get "/lists/:ml/search/" do
    redirect "/lists/#{params[:ml]}/search"
  end

  post "/lists/:ml/search" do
    @mlname = params[:ml]
    @query = params[:query]

    if @query.empty?
      @results = []
    else
      @results = settings.ml_archiver.search(@mlname, @query).map do |path|
        ["/lists/#@mlname/#{path}", path.to_s]
      end
    end

    erb :searchresult
  end

end
