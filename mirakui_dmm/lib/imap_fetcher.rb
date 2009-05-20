require 'rubygems'
require 'net/imap'
require 'kconv'
require 'pit'
require 'loggable'

module Gena
  class ImapFetcher

    include Loggable

    def initialize(pit_name)
      @pit = Pit.get(
        pit_name,
        :require=>{
          'host'=>'imap.gmail.com',
          'port'=>993,
          'use_ssl'=>'true',
          'login'=>'',
          'password'=>''
        }
      )
    end

    def fetch(filter)
      mails = []
      begin
        # GmailにIMAPで接続、ログインする
        @imap = Net::IMAP.new( @pit['host'], @pit['port'].to_i, @pit['use_ssl']=='true' )
        logger.debug 'IMAP.new'
        @imap.login( @pit['login'], @pit['password'] ) # ID、パスワード
        logger.debug "IMAP LOGIN #{@pit['login'].inspect}"

        # 受信箱を開く
        @imap.select( 'INBOX' )
        logger.debug 'IMAP SELECT INBOX'

        # メールを開く
        logger.debug "IMAP SEARCH #{filter.inspect}"
        @imap.search( filter ).each do | msg_id |
          logger.debug "FOUND msg_id:#{msg_id.inspect}"

          # 本文を取得する
          fetch_attr = '(UID RFC822.SIZE ENVELOPE BODY[HEADER] BODY[TEXT])'
          msg = @imap.fetch( msg_id, fetch_attr ).first
          logger.debug "IMAP FETCH #{msg_id.inspect} #{fetch_attr.inspect}"
          fetched_mail = {
            :body => msg.attr['BODY[TEXT]'].toutf8,
            :header => msg.attr['BODY[HEADER]'].toutf8
          }
          mails.push fetched_mail
          logger.debug "PUSHED #{fetched_mail[:header][/^Subject:.*$/]}"

          # 既読と削除のフラグを立てる
          @imap.store( msg_id, '+FLAGS', [:Seen] ) unless $DEBUG
          logger.debug "IMAP STORE #{msg_id.inspect} +FLAGS SEEN"
          #@imap.store( msg_id, '+FLAGS', [:Deleted] )
        end

        # フラグを反映させる
        @imap.expunge
        logger.debug "IMAP EXPUNGE"

      rescue Object=>e

        raise e # 例外処理

      ensure

        # 切断する
        @imap.logout
        logger.debug "IMAP LOGOUT"

        #@imap.disconnect
        #logger.debug "IMAP DISCONNECT"

      end
      mails
    end
  end
end

__END__

require 'pp'
imap = Gena::ImapFetcher.new('mirakui_dmm_imap')
mails = imap.fetch( ['FROM', 'mimitako@gmail.com', 'UNSEEN'] )

pp mails

