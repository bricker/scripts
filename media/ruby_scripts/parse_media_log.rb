#!/usr/bin/ruby

require 'apachelogregex'
require 'date'
require 'json'
require 'csv'
require 'uri'
require 'cgi'

REGEX = Regexp.new("GET (?<path>.+?)\s")
SHOWS = File.open("shows.txt").each_line.reject(&:empty?)

# populate hashes
month_keys        = []
by_month          = {}
totals            = {}
partial_requests  = {}

[*SHOWS, 'other'].each do |k|
  by_month[k]   = {}
end


format = '%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"'
# 64.55.111.113 - - [30/Jun/2011:00:01:04 -0700] "GET /law HTTP/1.1" 200 \
# 25772 "-" "Mozilla/5.0 (Linux; U; Windows NT 6.1; en-us; dream) DoggCatcher"

parser = ApacheLogRegex.new(format)

File.open(ARGV[0]).each_line do |line|
  # don't bother parsing non-mp3 lines
  next if line !~ /mp3/

  data = parser.parse(line)
  next if !data

  log_status    = data['%>s']
  log_ip        = data['%h']
  log_request   = data['%r']
  log_date      = data['%t']

  # skip non-200/206 responses or non-GET requests
  next if log_status !~ /20[06]/ || log_request !~ /^GET/

  # parse date
  date = DateTime.strptime(log_date, "[%d/%b/%Y:%H:%M:%S %z]")

  # For partial content, we don't want to count each request as a
  # separate logged listen, so we'll only log it once every 30 minutes.
  if log_status == '206'
    partial_requests[log_ip] ||= {}

    if partial_requests[log_ip][log_request] &&
    partial_requests[log_ip][log_request] >= (date - (60*30))
      # hit within last 30 minutes...  pass
      next
    else
      # first hit...  count it
      partial_requests[log_ip][log_request] = date
    end
  end

  # look for show files
  match = log_request.match(REGEX)
  next if !match

  uri       = URI.parse("http://media.scpr.org#{match[:path]}")
  query     = CGI.parse(uri.query)
  context   = query[:context]
  source    = query[:via]

  month_key = date.strftime("%Y-%m")
  # Keep track of this key so we can use it for headers in the CSV.
  month_keys << month_key unless month_keys.include?(month_key)

  # add to month stats
  by_month[context] ||= {}

  if !by_month[context][month_key]
    by_month[context][month_key] = { podcast: 0, ondemand: 0 }
  end

  type = source == 'podcast' ? :podcast : :ondemand
  by_month[key][month_key][type] += 1
end

CSV($stdout,
  :headers          => ["Show", "Type", *month_keys],
  :write_headers    => true
) do |csv|
  by_month.each do |show, data|
    [:podcast, :ondemand].each do |type|
      csv << [show, type, *month_keys.map { |k| data[k] ? data[k][type] : 0 }]
    end
  end
end
