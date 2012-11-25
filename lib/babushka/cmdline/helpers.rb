# coding: utf-8

module Babushka
  class Cmdline
    class Helpers
      def self.print_version opts = {}
        if opts[:full]
          LogHelpers.log "Babushka v#{VERSION} (#{Base.ref}), (c) 2012 Ben Hoskings <ben@hoskings.net>"
        else
          LogHelpers.log "#{VERSION} (#{Base.ref})"
        end
      end

      def self.print_usage
        LogHelpers.log "\nThe gist:"
        LogHelpers.log "  #{Base.program_name} <command> [options]"
        LogHelpers.log "\nAlso:"
        LogHelpers.log "  #{Base.program_name} help <command>  # Print command-specific usage info"
        LogHelpers.log "  #{Base.program_name} <dep name>      # A shortcut for 'babushka meet <dep name>'"
        LogHelpers.log "  #{Base.program_name} babushka        # Update babushka itself (what babushka.me/up does)"
      end

      def self.print_handlers
        LogHelpers.log "\nCommands:"
        Handler.all.each {|handler|
          LogHelpers.log "  #{handler.name.ljust(10)} #{handler.description}"
        }
      end

      def self.print_examples
        LogHelpers.log "\nExamples:"
        LogHelpers.log "  # Inspect the 'system' dep (and all its sub-deps) without touching the system.".colorize('grey')
        LogHelpers.log "  #{Base.program_name} system --dry-run"
        LogHelpers.log "\n"
        LogHelpers.log "  # Meet the 'fish' dep (i.e. install fish and all its dependencies).".colorize('grey')
        LogHelpers.log "  #{Base.program_name} fish"
        LogHelpers.log "\n"
        LogHelpers.log "  # Meet the 'user setup' dep, printing lots of debugging (including realtime".colorize('grey')
        LogHelpers.log "  # shell command output).".colorize('grey')
        LogHelpers.log "  #{Base.program_name} 'user setup' --debug"
      end

      def self.print_notes
        LogHelpers.log "\nCommands can be abbrev'ed, as long as they remain unique."
        LogHelpers.log "  e.g. '#{Base.program_name} l' is short for '#{Base.program_name} list'."
      end

      def self.search_results_for q
        YAML.load(search_webservice_for(q).body).sort_by {|i|
          -i[:runs_this_week]
        }.map {|i|
          [
            i[:name],
            i[:source_uri],
            ((i[:runs_this_week] && i[:runs_this_week] > 0) ? "#{i[:runs_this_week]} this week" : "#{i[:total_runs]} ever"),
            ((i[:runs_this_week] && i[:runs_this_week] > 0) ? "#{(i[:success_rate_this_week] * 100).round}%" : ((i[:total_runs] && i[:total_runs] > 0) ? "#{(i[:total_success_rate] * 100).round}%" : '')),
            (i[:source_uri][github_autosource_regex] ? "#{Base.program_name} #{$1}:#{"'" if i[:name][/\s/]}#{i[:name]}#{"'" if i[:name][/\s/]}" : '✣')
          ]
        }
      end

      def self.print_search_results search_term, results
        LogHelpers.log "The webservice knows about #{results.length} dep#{'s' unless results.length == 1} that match#{'es' if results.length == 1} '#{search_term}':"
        LogHelpers.log ""
        Logging.log_table(
          ['Name', 'Source', 'Runs', ' ✓', 'Command'],
          results
        )
        if (custom_sources = results.select {|r| r[1][github_autosource_regex].nil? }.length) > 0
          LogHelpers.log ""
          LogHelpers.log "✣  #{custom_sources == 1 ? 'This source has a custom URI' : 'These sources have custom URIs'}, so babushka can't discover #{custom_sources == 1 ? 'it' : 'them'} automatically."
          LogHelpers.log "   You can run #{custom_sources == 1 ? 'its' : 'their'} deps in the same way, though, once you add #{custom_sources == 1 ? 'it' : 'them'} manually:"
          LogHelpers.log "   $ #{Base.program_name} sources -a <alias> <uri>"
          LogHelpers.log "   $ #{Base.program_name} <alias>:<dep>"
        end
      end

      def self.github_autosource_regex
        /^\w+\:\/\/github\.com\/(.*)\/babushka-deps(\.git)?/
      end

      def self.search_webservice_for q
        Net::HTTP.start('babushka.me') {|http|
          http.get URI.escape("/deps/search.yaml/#{q}")
        }
      end

      def self.generate_list_for to_list, filter_str
        context = to_list == :deps ? Base.program_name : ':template =>'
        match_str = filter_str.try(:downcase)
        Base.sources.all_present.each {|source|
          source.load!
        }.map {|source|
          [source, source.send(to_list).items]
        }.map {|(source,items)|
          if match_str.nil? || source.name.downcase[match_str]
            [source, items]
          else
            [source, items.select {|item| item.name.downcase[match_str] }]
          end
        }.select {|(_,items)|
          !items.empty?
        }.sort_by {|(source,_)|
          source.name
        }.each {|(source,items)|
          indent = (items.map {|item| "#{source.name}:#{item.name}".length }.max || 0) + 3
          LogHelpers.log ""
          LogHelpers.log "# #{source.name} (#{source.type})#{" - #{source.uri}" unless source.implicit?}"
          LogHelpers.log "# #{items.length} #{to_list.to_s.chomp(items.length == 1 ? 's' : '')}#{" matching '#{filter_str}'" unless filter_str.nil?}:"
          items.each {|dep|
            LogHelpers.log "#{context} #{"'#{source.name}:#{dep.name}'".ljust(indent)}"
          }
        }
      end
    end
  end
end
