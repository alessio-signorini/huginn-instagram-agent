# InstagramAgent

Monitor public Instagram accounts and creates an event for each post.

It can be scheduled to hit Instagram as much as you want but will obey
  the `wait_between_refresh` for each account to avoid being banned.
  If set to `0` it will refresh all accounts at every run.

You can set the option `proxy` to use one. The format is `user:password@host:port`.

Links generally expire after 24 hours but this agent will try to keep the
  corresponding events updated so they can be used in a feed.
