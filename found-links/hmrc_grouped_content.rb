require 'pp'

link_matcher = /[^\(]*hmrc\.gov\.uk[^\)|^\s]*/
answer = Edition.where(state: 'published').map do |e|
  if e.respond_to?(:body) && e.body && (matches = e.body.scan(link_matcher))
    matches.unshift(e.id) unless matches.empty?
  elsif e.respond_to?(:parts) && e.parts
    matches = []
    e.parts.each do |p|
      part_matches = p.body.scan(link_matcher)
      matches.concat(part_matches) unless part_matches.empty?
    end
    matches.unshift(e.id) unless matches.empty?
  end
end.compact

File.open('found-links/hmrc-grouped-content.html', 'w') do |f|
  answer.group_by {|e| Edition.find(e.first).class.name }.to_a.each do |editions|
    f.puts "<h1>#{editions.first}</h1>"
    editions.last.each do |edition|
      url = "http://publisher.production.alphagov.co.uk/editions/#{edition.first}"
      f.puts "<a href='#{url}'>#{url}</a><br/>"
      f.puts "<ul>"
      edition[1..-1].each do |link|
        f.puts "<li><a href='#{link}'>#{link}</a></li>"
      end
      f.puts "</ul>"
    end
  end
end
