# Concerto Template Scheduling

A Rails Engine for scheduling templates for your screens in Concerto.

Templates can be scheduled for a screen for a specific time frame for specific days.  A template will be made active when this 
scheduling criteria is met.  A template can also be made active when content exists on a specified feed-- such as when 
you want travel advisories or weather alerts to show at the bottom of your screen while still having your other content
shown.

## Installation

To use this engine, add the plugin to Concerto via the UI, selecting rubygems as the source.

Or add this `gem 'concerto_template_scheduling'` to your Gemfile and run bundle install, generate the migrations, and run them. Then restart your webserver.
```
bundle install
rails generate concerto_template_scheduling
rake db:migrate
service apache2 restart
```

## Troubleshooting

If you click on the "Frequency" dropdown list and select "Set Schedule" and a "Repeat" pop up window does not appear, then you probably need to recompile your assets so the plugin's javascript gets included.

In /usr/share/concerto, as the concerto user or as root, run
```
RAILS_ENV=production bundle exec rake assets:precompile
chown -R www-data:www-data public/assets
service apache2 restart
```

Then reload your webpage and the pop up to set the schedule should come up.

## Time Zone Perspective

With the release of version 0.1.0 the time specified for the "active" period is considered from the perspective of the screen's timezone, not the user's timezone.  It most cases these two will match and you won't notice the change.  In other cases where you had screens outside of your normal time zone, you may need to adjust the schedules.

## Security
If a user can update a screen, they have the ability to manage the scheduled templates for that screen.
