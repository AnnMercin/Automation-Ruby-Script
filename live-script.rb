require 'uri'
require 'csv'
require 'fileutils'
require 'pry'
require 'active_support'
require 'active_support/core_ext'

puts "Please Enter Output File Name"
output_file_name = gets.chomp
puts "Please Enter  page id"
id = gets.chomp
puts "Please Enter URL"
url = gets.chomp
address = URI(url)
url = "curl -s -k #{ENV['NGINX_REFRESH']}#{address.path} -H Host:#{address.host} -H X-Cache-Bypass-Mode:All"
3.times do
 system(url)
end
response = `curl -X GET -u #{ENV['graylog_user']}:#{ENV['graylog_password']} "#{ENV['graylog_domain']}/api/search/universal/relative?query=facility:#{ENV['wps_facility']}%20AND%20page_id:#{id}&range=86400&limit=3&sort=timestamp%3Adesc"`
output_file = Dir.pwd + '/'+ output_file_name

headers = ["PAGE NAME", "COMPONENT NAME", "CACHE ENABLED", "SERVED FROM CACHE", "DURATION","PAGE RUN TIME"]
CSV.open(output_file, 'w', write_headers: true, headers: headers) do | writer |
parsed_response = JSON.parse(response)
final_msg_data = []	
parsed_response["messages"].each do |msg|
	data=msg["message"]["message"].split("::").last.strip if msg["message"]["message"]&.match(/Page json created/)
	replace_vale = data.match(/:page_cache_expires_in=>([^,]+)/)&.captures&.first
	json_msg = eval(data.gsub(replace_vale, "\"#{replace_vale}\"")).as_json
	final_msg_data << json_msg if json_msg['component_data'].present? && json_msg['component_data'] != 'nil'
end
next unless final_msg_data.present?
final_msg_data.each do |final_msg|
    writer << [final_msg["page_type"].gsub('_', ' ').upcase]
      total_component_time = 0
      final_msg['component_data'].each do |v|
        data_compute_time = v['data_compute_time'].present? ? v['data_compute_time'].to_f / 1000 : v['data_compute_time']
        duration = v['duration'].present? ? v['duration'].to_f / 1000 : v['duration']
        total_component_time += duration
        writer << ["", v['name'], v['cache_enabled'], v['served_from_cache'], duration]
      end
    writer << ["", "", "", "", total_component_time, final_msg['time_taken'].to_f / 1000]
    writer << ["DIFFERENCE", "", "", "", "", (final_msg['time_taken'].to_f / 1000) - total_component_time]
    writer << [""]
    end
end

