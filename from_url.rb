require 'sax-machine'
require 'net/http'

class SAXParser
  include SAXMachine
  element :title
end

uri               = URI(ENV['URL'])
parser            = SAXParser.new
io_read, io_write = IO.pipe
parser_thread     = Thread.new { parser.parse(io_read) }

Net::HTTP.start(uri.host, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
  request = Net::HTTP::Get.new uri.request_uri

  http.request(request) do |response|
    response.read_body do |chunk|
      io_write << chunk.force_encoding('utf-8')
    end

    io_write.close
    parser_thread.join # Wait for parser to finish
  end
end
sleep