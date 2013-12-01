class FeedRefresherReceiver
  include Sidekiq::Worker
  sidekiq_options queue: :feed_refresher_receiver

  def perform(update)
    feed = Feed.find(update['feed']['id'])
    if update['entries'].any?
      update['entries'].each do |entry|
        begin
          if entry['update'] == true
            Librato.increment('entry_update')
            # entry = Entry.find_by_public_id(entry['public_id'])
            # entry.update_attributes(updated_content: entry['content'], updated: entry['updated'])
          else
            feed.entries.create!(entry)
          end
        rescue Exception
          Sidekiq.redis { |client| client.hset("entry:public_ids:#{entry['public_id'][0..4]}", entry['public_id'], 1) }
        end
      end
    end
    feed.etag = update['feed']['etag']
    feed.last_modified = update['feed']['last_modified']
    feed.save
  end

end
