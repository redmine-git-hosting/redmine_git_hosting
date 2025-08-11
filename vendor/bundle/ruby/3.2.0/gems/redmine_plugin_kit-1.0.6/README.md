# Redmine Plugin Kit

This gem can be used for [Redmine](https://www.redmine.org/) Plugin for loading customizations.

In an ideal world, all plugins would use this gem as base. Or even better: this gem comes to Redmine core itself.

If you are a Redmine developer, feel free and offer PRs with your Improvements.

## Features

- Loader for plugin customizations
- Deface support for Redmine plugins

## Why this gem?

1. a standard process for load patches, hooks or helper for plugins
2. deface is ready to use and does not require any additional plugin (e.g. redmine_base_deface). It is easier for a plugin user, to install one plugin (instead of two). This makes also sure, that all plugins uses the same deface version.

## Requirements

- Redmine `>= 4.1.0` (including upcoming)
- Ruby `>= 2.7` (only maintained ruby versions are supported)

## Installation

Add Gem to your Gemfile:

```ruby
gem 'redmine_plugin_kit'
```
