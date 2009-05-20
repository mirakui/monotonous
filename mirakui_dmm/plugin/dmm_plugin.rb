require 'lib/imap_fetcher'
require 'lib/mirakui_dmm_base'

module MirakuiDmm

  class DmmPlugin < MirakuiDmmBase

    def initialize
    end

    def execute(options)
      mails = fetch_mail
      mails.each do |mail|
        from = mail[:header][/^Subject:.*$/]
        logger.debug "FROM: #{from.inspect}"
        if from[/ご返却確認いたしました/]
          logger.debug '返却!!'
          process_return_mail mail
        elsif from[/商品発送のお知らせ/]
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

    def process_return_mail(mail)
      titles = []
      mail[:body].scan(/^\d{4}-\d{2}-\d{2}\s+\w+\s+(.*)$/) do |line|
        title = $1
        logger.debug "extracted from return_mail: #{title.inspect}"

        titles << title
      end
      post "#{titles.map{|t| "「#{t}」"}}を返却しました"
    end

    def process_dispatch_mail(mail)
      titles = []
      mail[:body].scan(/^\d{4}-\d{2}-\d{2}\s+\w+\s+(.*)$/) do |line|
        title = $1
        logger.debug "extracted from dispatch: #{title.inspect}"

        titles << title
      end
      post "#{titles.map{|t| "「#{t}」"}}を発送しました"
    end

  end

end

__END__

d = MirakuiDmm::DmmPlugin.new
d.execute

