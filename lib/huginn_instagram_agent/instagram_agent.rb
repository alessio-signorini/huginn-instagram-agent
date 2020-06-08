module Agents
  class InstagramAgent < Agent

    can_dry_run!

    default_schedule 'every_1h'

    description <<-MD
      Monitor public Instagram accounts and creates an event for each post.

      Links generally expire after 24 hours but this agent will try to keep the
        corresponding events updated.
    MD


    def default_options
      {
        :accounts_to_monitor => []
      }
    end


    def validate_options
      errors.add(:base, "`accounts_to_monitor` must be an array of strings") unless options['accounts_to_monitor'].is_a?(Array)
      options['accounts_to_monitor'].each{|v| v.sub!(/^@+/,'')}
    end


    def working?
      memory['error'] != true
    end


    def check
      memory['error'] = nil

      accounts_to_refresh.each do |account|
        remember_fetching(account)

        posts = get_posts(account) or next

        posts.each do |post|
          if seen_before?(post)
            update_existing_event(post)
          else
            create_event :payload => post
          end
        end
      end

    end


    def get_posts(account)
      url = "https://www.instagram.com/#{account}/"

      response = HTTParty.get(url,
        :headers => {
          'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.97 Safari/537.36'
        }
      )

      unless response.success?
        error("[#{account}] Could not fetch #{url} - error #{response.code} | headers #{response.headers}")
        memory['error'] = true
        return nil
      end

      json = extract_json(response.parsed_response)

      unless json
        error("[#{account}] Could not extract JSON from #{url} - raw #{response.parsed_response} | headers #{response.headers}")
        memory['error'] = true
        return nil
      end

      posts = extract_posts(json)

      unless posts.any?
        error("[#{account}] Could not find any posts, strange - raw #{response.parsed_response} | headers #{response.headers} | json #{json}")
        memory['error'] = true
        return nil
      end

      return Array(posts).compact
    end


    def extract_json(html)
      if data = html.match(/window._sharedData\s*=\s*(\{.+?})\s*\;\s*<\/script>/m)[1]
        return JSON.parse(data)
      end

      rescue JSON::ParserError
        return nil
    end


    def extract_posts(json)
      json['entry_data']['ProfilePage'][0]['graphql']['user']['edge_owner_to_timeline_media']['edges'].map do |edge|
        edge['node']
      end

    rescue => e
      return []
    end


    private


    def instagramid_to_eventid
      @instagramid_to_eventid ||= events.all.map{|e| [e.payload['id'], e.id]}.to_h
    end


    def seen_before?(post)
      instagramid_to_eventid.has_key?(post['id'])
    end


    def update_existing_event(post)
      event_id = instagramid_to_eventid.fetch(post['id'])
      event = events.find(event_id)
      event.payload = post
      create_event(event)
    end


    def stale_accounts(refresh_every=24.hours)
      interpolated['accounts_to_monitor'].select do |account|
        last_fetched_at = memory.dig('last_fetched_at', account)
        last_fetched_at.nil? || last_fetched_at < refresh_every.ago.to_i
      end
    end


    def accounts_to_refresh
      Array(stale_accounts.sample)
    end


    def remember_fetching(account)
      memory['last_fetched_at'] ||= {}
      memory['last_fetched_at'][account] = Time.now.to_i
    end

  end
end
