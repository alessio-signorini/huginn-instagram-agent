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

      interpolated['accounts_to_monitor'].map do |account|
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

      response = HTTParty.get(url)

      unless response.success?
        error("[#{account}] Could not fetch #{url} - error #{response.code}")
        memory['error'] = true
        return nil
      end

      json = extract_json(response.parsed_response)

      unless json
        error("[#{account}] Could not extract JSON from #{url} - raw #{response.parsed_response}")
        memory['error'] = true
        return nil
      end

      posts = extract_posts(json)

      unless posts.any?
        error("[#{account}] Could not find any posts, strange - raw #{json}")
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

  end
end
