module Babushka
  class PathChecker

    def self.in_path? provided_list
      commands = [provided_list].flatten(1).versions

      cmds_in_path?(commands) and matching_versions?(commands) {|cmd|
        ShellHelpers.shell("#{cmd.name} --version")
      }
    end

    private

    def self.cmds_in_path? commands
      dir_hash = [*commands].group_by {|cmd| ShellHelpers.cmd_dir(cmd.name) }

      if dir_hash.keys.compact.length > 1
        LogHelpers.log_error "These commands run from more than one place."
        LogHelpers.log_error dir_hash.values.map {|cmds|
            cmd_location_str_for cmds
          }.to_list(:oxford => true, :conj => 'but').end_with('.')
        unmeetable! unless Prompt.confirm("Multiple installations might indicate a problem. Meet anyway?", :default => 'n')
      else
        dir_hash[nil].blank?.tap {|result|
          if result
            cmds = dir_hash.values.first
            LogHelpers.log cmd_location_str_for(cmds).end_with('.') unless cmds.blank?
          else
            LogHelpers.log "#{dir_hash[nil].map {|i| "'#{i}'" }.to_list} #{dir_hash[nil].length == 1 ? 'is' : 'are'} missing."
          end
        }
      end
    end

    def self.matching_versions? commands
      versions = commands.select {|cmd|
        !cmd.version.nil?
      }.inject({}) {|hsh,cmd|
        potential_versions = match_potential_versions(yield(cmd), cmd.version)
        if potential_versions.empty?
          # No potential versions to check against.
        else
          hsh[cmd] = potential_versions.detect {|piece| cmd.matches?(piece) }
          if hsh[cmd] == cmd.version
            LogHelpers.log_ok "#{cmd.name} is #{cmd.version}."
          else
            LogHelpers.log "#{cmd.name} is #{hsh[cmd] || potential_versions.first}, which is#{"n't" unless hsh[cmd]} #{cmd.version}.", :as => (:ok if hsh[cmd])
          end
        end
        hsh
      }
      versions.values.all?
    end

    def self.match_potential_versions str, example = ''
      (str || '').split(/[^\w\.\-]+/).map {|piece|
        begin
          piece.to_version
        rescue VersionStrError
          nil
        end
      }.compact.reject {|piece|
        piece.to_s['.'].nil? if example.to_s['.']
      }
    end

    def self.cmd_location_str_for cmds
      "#{cmds.map {|i| "'#{i.name}'" }.to_list(:conj => '&')} run#{'s' if cmds.length == 1} from #{ShellHelpers.cmd_dir(cmds.first.name)}"
    end
  end
end
