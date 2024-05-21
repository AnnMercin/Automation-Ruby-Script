#stage
error_ids = [] 
id_complete =[]
site.articles.ids.each do |id|
  begin
    ArticleIndex.import!(id)
id_complete << [id]
p(id_complete.count)
  rescue => e
    error_ids << [id ,e.message]
  end
end


#Live

json_file_path = "../#{site.name}.json"
error_ids = []
id_complete = []
File.open(json_file_path, 'w') do |json_file|
  site.articles.ids.each do |id|
    begin
      ArticleIndex.import!(id)
      id_complete << { 'Article_ID' => id,}
      json_file.puts(JSON.dump(id_complete.last))
      p(id_complete.count)
    rescue => e
      error_ids << { 'Article_Error_ID' => id, 'Error_Message' => e.message }
      json_file.puts(JSON.dump(error_ids.last))
    end
  end
end
# ----------------------------------------error------------------------------------------------

site = Ambient.set_site
json_file_path = "../#{site.name}.json"
error_ids = []

File.open(json_file_path, 'r') do |json_file|
  json_file.each_line do |line|
    data = JSON.parse(line)
    if data.key?('Article_Error_ID')
      error_ids << data['Article_Error_ID']
    end
  end
end
error_ids.count #to get count


# for doing again
 
again_error = []
 
begin
  error_ids.each do |id|
    ArticleIndex.import!(id)
  rescue => e
    again_error << [id, e.message]
  end
end

# Note and change error_ids again_error

json_error_file_path = "../#{site.name}_errors_ids.json"
 
File.open(json_error_file_path, 'w') do |json_file|
  json_file.puts(JSON.dump({ "ids" => error_ids }))
end

# ----------------------------------------------------------------------------------------------
client = Elasticsearch::Client.new(log: true)
client.cat.indices #it will list all index

# ________________________________________________________________________________________________

                                        # to do index with data_proxy_id for all site
# ______________________________________________________________________________________________

ids = Article.pluck(:data_proxy_id).uniq.compact

ids.each do |id|
  site = Site.find_by(data_proxy_id: id)
  Ambient.init
  Ambient.current_site = site
 
  site.articles.ids.each do |ar|
    begin
      ArticleIndex.import!(ar)
    rescue => e
      error_ids << [ar, e.message, id]
    end
  end
end
# ________________________________________________________________________________________________

                                          # to List of Missed all articles
# ________________________________________________________________________________________________

ids = Article.pluck(:data_proxy_id).uniq.compact
done = ArticleIndex.filter(terms: { data_proxy_id: ids }).pluck(:id)
ar_ids = Article.where(data_proxy_id: ids ).pluck(:id)
miss  = ar_ids - done
miss.count
s_ids = Article.where(id: miss).pluck(:data_proxy_id).uniq.compact
s_ids.each do |site_id|
  site = Site.find(site_id)  
  local_article_ids = site.articles.ids
  elasticsearch_article_ids = ArticleIndex.filter(term: { data_proxy_id: site.data_proxy_id }).pluck(:id)
  missing_articles = local_article_ids - elasticsearch_article_ids
  puts "#{site.name} ---------------------#{missing_articles.count}-----------------------------------#{site.status} ---------------------------------#{site.site_type}"
end

# ________________________________________________________________________________________________

                                          # to List of Missed ids for site
# ________________________________________________________________________________________________

ids = site.articles.ids
ArticleIndex.query(match: { data_proxy_id: site.data_proxy_id }).count
el_ids = ArticleIndex.filter(terms: { data_proxy_id: site.data_proxy_id }).pluck(:id)
missed = ids - el_ids


# ________________________________________________________________________________________________


