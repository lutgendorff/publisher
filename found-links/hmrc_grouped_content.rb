answer = Edition.where(state: 'published').map do |e|
  if e.respond_to?(:body) && e.body && e.body.include?('hmrc.gov.uk')
    e.id
  elsif e.respond_to?(:parts) && e.parts && e.parts.any? { |p| p.body && p.body.include?('hmrc.gov.uk') }
    e.id
  end
end.compact

File.open('hmrc-grouped-content.html', 'w') do |f|
  answer.group_by {|e| Edition.find(e).class.name }.to_a.each do |editions|
    f.puts editions.first
    f.puts "<br/>"
    editions.last.each do |edition|
      url = "http://publisher.production.alphagov.co.uk/editions/#{edition}"
      f.puts "<a href='#{url}'>#{url}</a><br/>"
    end
  end
end
