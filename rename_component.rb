site = Ambient.set_site

site_path = ENV['SITE_PATH']

components_file = site_path + "/#{site.short_name}/config/components.json"
mappings_file = "#{site_path}/#{site.short_name}/config/mappings.json"
containers_file ="#{site_path}/#{site.short_name}/config/containers.json"

components = JSON.parse(File.read(components_file))
mappings = JSON.parse(File.read(mappings_file))
containers = JSON.parse(File.read(containers_file))

containers.each do |id , key|
	component = components[mappings[id].first]
	component['name'] = key["name"]
	file_name = ENV['SITE_PATH'] + "/#{site.short_name}/config/components.json"
	file_content = File.read(file_name)
    file_array = JSON.parse(file_content)
    file_array[component['id']] = component
    File.open(file_name, 'w+') do |f|
      f.write(JSON.pretty_generate(file_array))
    end
end
