site_path = ENV['SITE_PATH']
site = Ambient.set_site
components_file = site_path + "/#{site.short_name}/config/components.json"

components = JSON.parse(File.read(components_file))
newdata = {}

def dynamic_data_source?
  [
    @data_source_hash&.dig(:static_fragment, 0, :type),
    @data_source_hash&.dig(:ranked_list, 0, :type),
  ].include?('dynamic')
end

components.each do |id, component|
  component.deep_symbolize_keys!
  @data_source_hash = component[:property].delete(:data_source)

  component_type = if dynamic_data_source?
    component[:property][:dynamic_name] =
      case component[:source_type]
      when 'static_fragment'
        @data_source_hash&.dig(:static_fragment, 0, :title)
      when 'ranked_list'
        @data_source_hash&.dig(:ranked_list, 0, :name)
      end
    1
  else
    case component[:source_type]
    when 'static_fragment'
      title = @data_source_hash&.dig(:static_fragment, 0, :title)
      fragment = site.all_static_articles.find_by_title(title)
      component[:property][:fragment_title] = title
    when 'ranked_list'
      featured_set = site.featured_sets.find_by_name(
        @data_source_hash&.dig(:ranked_list, 0, :name)
      )
    end
    0
  end

  data = component.slice(
    :name, :paginate, :source_type, :exclude_from
  ).merge(
    presentation_proxy_id: site.presentation_proxy_id,
    site_id: site.id,
    fragment_id: fragment&.id,
    configurations: component[:property],
    featured_set_ids: [featured_set&.id],
    component_type: component_type
  )
  data[:id] = id if id
  newdata.merge!(data[:name] => data)
end
json_file_path = "#{site_path}/#{site.short_name}/config/components_new.json"
File.open(json_file_path, 'w') do |json_file|
  json_file.puts(JSON.pretty_generate(newdata))
end
