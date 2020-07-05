# encoding: utf-8

require 'net/imap'
require 'mail'
require 'rss'

imap = Net::IMAP.new(ENV["IMAP_SERVER"], 993, true)
imap.login(ENV["IMAP_UID"], ENV["IMAP_PWD"])
imap.select(ENV["IMAP_FOLDER"])
ids = imap.search("RECENT")
ids.uniq!

rss = RSS::Maker.make('rss2.0') do |maker|
    maker.channel.title = "Newsletters"
    maker.channel.link = ENV["BASEURL"]
    maker.channel.description = "My newsletter subscriptions as an rss feed"

    ids.each do |id|
        imsg = imap.fetch(id, "RFC822")[0].attr["RFC822"]

        message = Mail.read_from_string imsg

        maker.items.new_item do |item|
            item.link = "#{ENV["BASEURL"]}/item/#{id}"
            item.title = message.Subject
            
            if message.multipart?
                message.body.parts.each do |p|
                    if (p.content_type.index("text/html") == 0)
                        item.description = p.body.to_s.force_encoding('UTF-8')
                    end
                end
            else
                item.description = message.body.to_s.force_encoding('UTF-8')
            end
            item.author = message.from
            item.updated = message.date.to_s
        end
    end
end

puts rss