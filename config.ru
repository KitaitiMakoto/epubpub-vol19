require 'erb'
require 'cgi'
require 'pathname'
require 'epub/parser'

class EPUBListServer
  include ERB::Util

  def initialize(dir)
    @dir = Pathname(dir)
    raise 'Not a directory' unless @dir.directory?
    $stderr.puts "Serving list of EPUB files in #{@dir}"
  end

  def call(env)
    files = Pathname.glob("#{@dir}/*.epub")
    last_modified = files.collect(&:mtime).max

    request = Rack::Request.new(env)
    response = Rack::Response.new

    if_modifed_since = env['HTTP_IF_MODIFIED_SINCE']
    if if_modifed_since and last_modified.to_s <= Time.httpdate(if_modifed_since).to_s
      response.status = Rack::Utils.status_code(:not_modified)
    elsif !request.head?
      response.body << <<EOH
<!DOCTYPE html>
<link rel="stylesheet" type="text/css" href="/index.css">
<ul>
EOH
      files.each do |file|
        response.body << <<EOH
<li>
  <a href="/#{u file.basename}">#{h file.basename}</a>
  <ul class="readers">
    <li>[bib]</li>
    <li>[<a href="/readium.html##{u file.basename}">SimpleReadium</a>]</li>
    <li>[<a href="/epubjs.html##{u file.basename}">epub.js</a>]</li>
  </ul>
</li>
EOH
      end
      response.body << <<EOH
</ul>
EOH
    end

    response['Content-Type'] = 'text/html'
    response['Last-Modified'] = last_modified.httpdate
    response.finish
  end
end

class ZipServer
  def initialize(dir)
    @dir = Pathname(dir)
    raise 'Not a directory' unless @dir.directory?
    $stderr.puts "Serving files in zip archives in #{@dir}"
  end

  def call(env)
    request = Rack::Request.new(env)
    response = Rack::Response.new

    match_data = %r|/(?<filename>[^/]+)/(?<path>.+)|.match(request.env['REQUEST_PATH'])
    if match_data
      Zip::Archive.open (@dir + CGI.unescape(match_data[:filename])).to_path do |archive|
        begin
          path = Pathname(match_data[:path])
          response.body << archive.fopen(path.to_path).read
          response['Content-Type'] =
            case path.extname.downcase
            when '.xhtml' then 'application/xhtml+xml'
            when '.html' then 'text/html'
            when '.xml' then 'application/xml'
            when '.png' then 'image/png'
            when '.jpeg', '.jpg' then 'image/jpeg'
            when '.gif' then 'image/gif'
            when '.svg' then 'image/svg+xml'
            when '.css' then 'text/css'
            when '.js' then 'text/javascript'
            when '.opf' then EPUB::MediaType::ROOTFILE
            else 'application/octet-stream'
            end
        rescue Zip::Error => error
          $stderr.puts error
          response.status = Rack::Utils.status_code(:not_found)
        end
      end
    else
      response.status = Rack::Utils.status_code(:not_found)
    end
    response.finish
  end
end

docroot = ENV['DOCROOT']
map '/index.html' do
  run EPUBListServer.new(docroot)
end
run Rack::Cascade.new([Rack::File.new(docroot), ZipServer.new(docroot)])
