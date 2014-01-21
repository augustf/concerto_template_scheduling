# Concerto Template Scheduling

A Rails Engine for scheduling templates for your screens in Concerto.

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

# TODO
integrate ice_cube
hook into concerto
