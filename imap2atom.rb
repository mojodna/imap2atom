#!/usr/bin/env ruby -w -rubygems

require 'builder'
require 'cgi'
require 'net/imap'
require 'time'
require 'optparse'
require 'uri'

options = {
  :count => 20,
  :port  => Net::IMAP::PORT
}

option_parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options] URI"

  opts.on("--gmail", "Treat as a Gmail account.") do
    options[:gmail] = true
    options[:port]  = 993
    options[:ssl]   = true
  end

  opts.on("--list", "List mailboxes.") do
    options[:list] = true
  end

  opts.on("-n COUNT", "--count COUNT") do |v|
    options[:count] = v.to_i - 1
  end

  opts.on("--password PASSWORD", "Specifies the password for the account URI.") do |v|
    options[:password] = v
  end

  opts.on("-p", "--port PORT", "Specifies the port to use.") do |v|
    options[:port]
  end

  opts.on("--ssl", "Use SSL to connect.") do |v|
    options[:ssl] = true
  end

  opts.on("--title NAME", "Specifies the feed title.") do |v|
    options[:title]
  end
end

option_parser.parse!

if ARGV.empty?
  puts option_parser.help
  exit 1
end

uri = URI.parse(ARGV.pop)

if uri.scheme == "imaps"
  options[:port] = 993
  options[:ssl]  = true
end

if options[:gmail]
  uri.user = CGI.escape("#{uri.user}@#{uri.host}")
  uri.host = "imap.gmail.com"
end

if options[:password]
  uri.password = options[:password]
end

options[:title] ||= feed_id = "#{uri.scheme}://#{uri.host}#{uri.path}"

imap = Net::IMAP.new(uri.host, 993, true, "/usr/share/curl/curl-ca-bundle.crt", true)
imap.login(CGI.unescape(uri.user), CGI.unescape(uri.password))

if options[:list]
  puts "Available mailboxes:"
  imap.list("", "*").each do |entry|
    puts "  #{entry.name}"
  end
else
  folder = CGI.unescape(uri.path[1..-1])
  imap.examine(folder)

  messages = []

  count = imap.status(folder, ['MESSAGES'])['MESSAGES']
  imap.fetch(count-options[:count]..count, ['ENVELOPE', 'RFC822.TEXT']).each do |msg|
    envelope = msg.attr['ENVELOPE']
    body     = msg.attr['RFC822.TEXT']
    messages << [envelope, body]
  end

  messages.reverse!

  xml = Builder::XmlMarkup.new(:indent => 2, :target => STDOUT)
  xml.instruct!

  xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do

    xml.title   options[:title]
    xml.id      feed_id
    xml.updated Time.parse(messages[0][0].date).xmlschema if messages.any?
    xml.author  { xml.name "imap2atom" }

    messages.each do |envelope, body|
      xml.entry do
        xml.title   envelope.subject
        xml.id      "mid://" + envelope.message_id.gsub(/[<>]/, "") + "/"
        xml.updated Time.parse(envelope.date).xmlschema
        xml.author  { xml.name envelope.from[0].name }
        xml.content do
          xml.cdata! body
        end
      end
    end
  end
end

imap.logout

begin
  imap.disconnect
rescue Errno::ENOTCONN
end
