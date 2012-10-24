require 'csv'
require 'reverse_markdown'

class BusinessSupportContentDiff
  
  MARKED_DOWN_HEADERS = ['additional_information','short_description','eligibility','evaluation','long_description']
  DIFF_HEADERS = ['organiser','url','will_continue_on','contact_details']
  
  def diff
    diffs = {}
    csv_diff_headers = MARKED_DOWN_HEADERS + DIFF_HEADERS
    csv_data = {}
    CSV.read(File.join(Rails.root, "data", "bsf_schemes.csv"), headers: true).each do |row|
      csv_data[row['id'].to_s] = row
    end
    get_schemes_json(csv_data.keys).each do |edition|
      edition = edition['details']
      identifier = edition['business_support_identifier']

      row = csv_data[identifier]

      slug = slug_for(row['title'])
      
      csv_diff_headers.each do |header|
        if MARKED_DOWN_HEADERS.include?(header)
          import_val = marked_down(row[header])
        else
          import_val = to_utf8(row[header])
        end
        meth = method_for_header(header)
        
        edition_val = edition[meth.to_s]
        if import_val and edition_val and import_val != edition_val
            
          key = "#{identifier}, #{slug}, #{meth}"
          diffs[key] = {} unless diffs.has_key?(key)
          diffs[key] = [identifier, slug, meth, import_val, edition_val]

          puts "identifier: #{identifier}, slug : #{slug}, field: #{meth}"
          puts "------------------ imported value -------------------------------------------"
          puts import_val
          puts "--- current value ---"
          puts edition_val
          puts "-----------------------------------------------------------------------------\n"
        end
      end
    end
    diffs
  end

  def report
    formatted_time = Time.now.strftime("%Y%m%d-%H%M")
    CSV.open(File.join(Rails.root, "data", "bsf_scheme_diffs_#{formatted_time}.csv"), "wb") do |diff_csv|
      headers = ["identifier", "slug", "field", "original", "current"]
      diff_csv << CSV::Row.new(headers, headers)
      diff.values.each do |val|
        diff_csv << CSV::Row.new(headers, val)
      end
    end
  end

  def get_schemes_json(identifiers)
    uri = URI.parse("https://www.gov.uk/api/business_support_schemes.json?identifiers=#{identifiers.join(',')}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    JSON.parse(response.body)['results']
  end

  def method_for_header(header)
    case header
    when 'long_description'
      return :body
    when 'url'
      return :continuation_link
    else  
      return header.to_sym
    end
  end

  def marked_down(str, unescape_html=false)
    return nil if str.nil?
    str = to_utf8(str)
    str = CGI.unescapeHTML(str) if unescape_html
    ReverseMarkdown.parse(str).gsub(/\n((\-.*\n)+)/) {|match|
      "\n\n#{$1}"
    }
  end
  
  def slug_for(title)
    to_utf8(title.parameterize.gsub("-amp-", "-and-"))
  end
  
  def to_utf8(str)
    (str.nil? ? nil : str.force_encoding("UTF-8"))
  end 
end
