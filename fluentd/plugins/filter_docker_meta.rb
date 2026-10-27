# Adds container name, image and compose project/service to records read from Docker's json-file logs.
# The container id is taken from the file path (/var/lib/docker/containers/<id>/<id>-json.log); the details come from <id>/config.v2.json
# in the same (read-only mounted) folder, so no Docker socket is needed. Results are cached for cache_ttl seconds.
require 'json'
require 'fluent/plugin/filter'

module Fluent
  module Plugin
    class DockerMetaFilter < Fluent::Plugin::Filter
      Fluent::Plugin.register_filter('docker_meta', self)

      config_param :containers_dir, :string, default: '/var/lib/docker/containers'
      config_param :path_key, :string, default: 'tailed_path'
      config_param :cache_ttl, :integer, default: 120

      def configure(conf)
        super
        @cache = {}
      end

      def filter(_tag, _time, record)
        path = record.delete(@path_key).to_s
        id = path[%r{/containers/([0-9a-f]{12,64})/}, 1]
        return record unless id
        meta = lookup(id)
        record['container_id'] = id[0, 12]
        record['container_name'] = meta[:name]
        record['image'] = meta[:image]
        record['compose_project'] = meta[:project] if meta[:project]
        record['compose_service'] = meta[:service] if meta[:service]
        record
      end

      private

      def lookup(id)
        now = Time.now.to_i
        hit = @cache[id]
        return hit if hit && now - hit[:at] < @cache_ttl
        meta = { at: now, name: id[0, 12], image: nil, project: nil, service: nil }
        begin
          cfg = JSON.parse(File.read(File.join(@containers_dir, id, 'config.v2.json')))
          meta[:name] = cfg['Name'].to_s.sub(%r{\A/}, '')
          labels = (cfg['Config'] || {})['Labels'] || {}
          meta[:image] = (cfg['Config'] || {})['Image']
          meta[:project] = labels['com.docker.compose.project']
          meta[:service] = labels['com.docker.compose.service']
        rescue StandardError => e
          log.debug "docker_meta: no metadata for #{id[0, 12]}: #{e.class}" # container already removed: keep the id as the name
          meta = hit if hit
        end
        @cache[id] = meta
      end
    end
  end
end
