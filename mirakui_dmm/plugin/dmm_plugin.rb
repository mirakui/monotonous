require 'lib/imap_fetcher'
require 'lib/google'
require 'lib/dmm_client'
require 'lib/bitly'
require 'lib/mirakui_dmm_base'

module MirakuiDmm

  class GoogleDmmSearcher
    GOOGLE_SEARCH_QUERY_BASE_STR = 'site:dmm.com OR site:dmm.co.jp intitle:DVDレンタル -intitle:単品 %s'
    def self.search(title)
      search_result = Gena::Google.search GOOGLE_SEARCH_QUERY_BASE_STR % title
      long_url = URI.decode(search_result.first['url'])
      long_url
    end
  end

  class DmmSearcher
    def self.search(query)
      dmm_client = DmmClient.new
      search_result = dmm_client.search query
      long_url = search_result.first[:uri]
      long_url
    end
  end

  class DmmPlugin < MirakuiDmmBase

    def initialize
      @searcher = DmmSearcher
    end

    def execute(options)
      mails = fetch_mail
      mails.each do |mail|
        from = mail[:header][/^Subject:.*$/]
        logger.debug "FROM: #{from.inspect}"
        if from[/商品発送のお知らせ/]
          logger.debug '発送!!'
          process_dispatch_mail mail
        end
      end
    end

    private
    def fetch_mail
      imap = Gena::ImapFetcher.new('mirakui_dmm_imap')
      mails = imap.fetch( ['FROM', 'info@dmm.com', 'UNSEEN'] )
    end

    def process_dispatch_mail(mail)
      titles = []
      mail[:body].scan(/^\d{4}-\d{2}-\d{2}\s+\w+\s+(.*)$/) do |line|
        title = $1
        logger.debug "extracted from dispatch: #{title.inspect}"

        titles << title.chomp
      end
      titles.each do |title|
        dvd_url = dvd_url title
        post "「#{title}」を発送しました #{dvd_url}"
      end
    end

    def dvd_url(title)
      p title
      long_url  = @searcher.search title
      p long_url
      short_url = Gena::Bitly.shorten(long_url)
      short_url
    rescue Object => error
      p error
      logger.error error.to_s
    end

  end

end

__END__

d = MirakuiDmm::DmmPlugin.new
u = d.send('dvd_url', 'タイタニック')
p u

