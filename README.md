# Concerto Template Scheduling

A Rails Engine for scheduling templates for your screens in Concerto.

Templates can be scheduled for a specific time frame for specific days.  A template will be made active when this 
scheduling criteria is met.  A template can also be made active when content exists on a specified feed-- such as when 
you want travel advisories or weather alerts to show at the bottom of your screen while still having your other content
shown.

To use this engine, add the following to the Concerto Gemfile: 
```
gem 'concerto_template_scheduling'
```

To create the proper migrations, run: 
```
rails generate concerto_template_scheduling
```

## Security
If a user can update a screen, they have the ability to manage the scheduled templates for that screen.
