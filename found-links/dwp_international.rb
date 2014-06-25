answer = Edition.where(state: 'published').map do |e|
  if e.respond_to?(:body) && e.body && e.body.include?('dwp.gov.uk/international/')
    e.id
  elsif e.respond_to?(:parts) && e.parts && e.parts.any? { |p| p.body && p.body.include?('dwp.gov.uk/international/') }
    e.id
  end
end

File.open('dwp-international.html', 'w') do |f|
  answer.compact.map do |edition|
    url = "http://publisher.production.alphagov.co.uk/editions/#{edition}"
    f.puts "<a href='#{url}'>#{url}</a>"
  end
end
